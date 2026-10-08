"""Check the real controller with Nulina configs, without running hardware nodes."""

import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

import rclpy
from rclpy.parameter import Parameter
from sensor_msgs.msg import Imu
from std_msgs.msg import Float32
import yaml

from stingray_core_control.stingray_core_control_node import StingrayCoreControlNode


class NulinaControlTest(unittest.TestCase):
    """Exercise config loading and persistence through the ROS parameter API."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.config_dir = Path(self.temp.name) / 'control'
        source_dir = Path(__file__).resolve().parents[1] / 'src/nulina_config/control'
        shutil.copytree(source_dir, self.config_dir)
        # A value different from the core defaults proves the override was loaded.
        tuning_file = self.config_dir / 'controllers.yaml'
        tuning = yaml.safe_load(tuning_file.read_text())
        tuning['stingray_core_control_node']['ros__parameters']['controllers.yaw.K_p'] = 0.37
        tuning_file.write_text(yaml.safe_dump(tuning))
        env = patch.dict(os.environ, {'STINGRAY_CONFIG_DIR': str(self.config_dir)})
        env.start()
        self.addCleanup(env.stop)
        self.node = None
        self.addCleanup(self.stop_node)

    def start_node(self):
        args = ['--ros-args']
        for filename in (
            'stingray_core_control_node.yaml', 'thruster_matrix.yaml', 'controllers.yaml'
        ):
            args.extend(['--params-file', str(self.config_dir / filename)])
        rclpy.init(args=args)
        self.node = StingrayCoreControlNode()

    def stop_node(self):
        if self.node is not None:
            self.node.destroy_node()
            self.node = None
        if rclpy.ok():
            rclpy.shutdown()

    def test_sensor_topics_and_platform_parameters(self):
        self.start_node()
        self.assertEqual(self.node.sub_imu_data.topic_name, '/imu_full_data')
        self.assertEqual(self.node.sub_pressure_sensor.topic_name, '/ms5837/depth')
        self.assertEqual(len(self.node.thrusters), 6)
        self.assertEqual(self.node.get_parameter('surge_right_u_surge').value, -1)
        self.assertEqual(self.node.get_parameter('controllers.yaw.K_p').value, 0.37)

        imu = Imu()
        imu.orientation.w = 1.0
        self.node.imu_callback(imu)
        self.node.pressure_sensor_callback(Float32(data=1.25))
        self.assertAlmostEqual(self.node.imu_yaw, 0.0)
        self.assertAlmostEqual(self.node.depth, 1.25)

    def test_tuning_survives_controller_restart(self):
        self.start_node()
        result = self.node.set_parameters([
            Parameter('controllers.yaw.K_p', value=0.75),
        ])
        self.assertTrue(result[0].successful, result[0].reason)
        saved = yaml.safe_load((self.config_dir / 'controllers.yaml').read_text())
        self.assertEqual(
            saved['stingray_core_control_node']['ros__parameters']['controllers.yaw.K_p'],
            0.75,
        )
        self.stop_node()
        self.start_node()
        self.assertEqual(self.node.get_parameter('controllers.yaw.K_p').value, 0.75)


if __name__ == '__main__':
    unittest.main()
