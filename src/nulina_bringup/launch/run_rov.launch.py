"""Bring up Nulina's thrusters, AH127C IMU, MS5837 and GPIO power control."""

import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import EnvironmentVariable, LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node


def generate_launch_description():
    """Connect the platform configuration to the Nulina hardware drivers."""
    platform_share = get_package_share_directory('nulina_bringup')
    config_dir = os.path.join(platform_share, 'nulina_config')
    serial_share = get_package_share_directory('serial_driver')

    def include(package, filename):
        return IncludeLaunchDescription(PythonLaunchDescriptionSource(
            os.path.join(get_package_share_directory(package), 'launch', filename)
        ))

    return LaunchDescription([
        DeclareLaunchArgument(
            'control_config_dir',
            default_value=EnvironmentVariable(
                'STINGRAY_CONFIG_DIR',
                default_value=os.path.join(config_dir, 'control'),
            ),
            description='Directory containing the three control YAML files',
        ),
        DeclareLaunchArgument(
            'thruster_params_file',
            default_value=os.path.join(config_dir, 'communication', 'thruster.params.yaml'),
            description='Serial port settings for the thruster board',
        ),
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(os.path.join(
                serial_share, 'launch', 'serial_driver_bridge_node.launch.py'
            )),
            launch_arguments={
                'params_file': LaunchConfiguration('thruster_params_file'),
            }.items(),
        ),
        Node(
            package='stingray_core_communication',
            executable='thrusters_driver_node',
            name='thrusters_driver_node',
            output='screen',
        ),
        # The upstream launch hard-codes its own YAML files. Load the platform
        # files here and give its parameter saver the same directory.
        Node(
            package='stingray_core_control',
            executable='stingray_core_control_node',
            name='stingray_core_control_node',
            output='screen',
            parameters=[
                PathJoinSubstitution([LaunchConfiguration('control_config_dir'), filename])
                for filename in (
                    'stingray_core_control_node.yaml',
                    'thruster_matrix.yaml',
                    'controllers.yaml',
                )
            ],
            additional_env={
                'STINGRAY_CONFIG_DIR': LaunchConfiguration('control_config_dir'),
            },
        ),
        include('ms5837_pressure_sensor', 'ms5837.launch.py'),
        include('power_control', 'power_gpio.launch.py'),
        include('parser', 'parser.launch.py'),
    ])
