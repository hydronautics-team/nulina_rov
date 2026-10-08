FROM ros:humble-ros-base

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash-completion build-essential cmake git \
    libasio-dev libserial-dev i2c-tools \
    python3-colcon-common-extensions python3-libgpiod python3-pyqtgraph \
    python3-smbus python3-smbus2 python3-yaml \
    ros-humble-ament-cmake-auto ros-humble-ament-cmake-gtest \
    ros-humble-ament-lint-auto ros-humble-ament-lint-common \
    ros-humble-geometry-msgs ros-humble-lifecycle-msgs \
    ros-humble-launch-ros ros-humble-nav-msgs \
    ros-humble-rclcpp-components ros-humble-rclcpp-lifecycle \
    ros-humble-rqt-common-plugins ros-humble-rqt-gui-py \
    ros-humble-sensor-msgs ros-humble-tf2-geometry-msgs ros-humble-udp-msgs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /stingray_core
ENV PYTHONUNBUFFERED=1
ENV ROS_DOMAIN_ID=1
ENV ROS_LOCALHOST_ONLY=0
ENV STINGRAY_CONFIG_DIR=/stingray_core/src/nulina_config/control

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    echo 'source /opt/ros/humble/setup.bash' >> /root/.bashrc && \
    echo '[ ! -f /stingray_core/install/setup.bash ] || source /stingray_core/install/setup.bash' >> /root/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
