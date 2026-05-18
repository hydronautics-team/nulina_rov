from setuptools import find_packages, setup
import os
from glob import glob

package_name = 'nulina_bringup'

setup(
    name=package_name,
    version='0.0.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name), glob('launch/*.launch.py')),
        (os.path.join('share', package_name, 'nulina_config', 'communication'), glob('../nulina_config/communication/*')),
        (os.path.join('share', package_name, 'nulina_config', 'control'), glob('../nulina_config/control/*')),
        (os.path.join('share', package_name, 'nulina_config', 'sensors'), glob('../nulina_config/sensors/*')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='shakuevda',
    maintainer_email='da@shakuev.ru',
    description='TODO: Package description',
    license='TODO: License declaration',
    tests_require=['pytest'],
    entry_points={
        'console_scripts': [
        ],
    },
)
