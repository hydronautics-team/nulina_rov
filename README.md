# Nulina ROV

Платформа Нулины на ROS 2 Humble. Ядро `src/stingray_core` закреплено на
коммите `e8dc8bc` ветки `nulina_2026-feat-imu-nulina-version1`.
Схема работы такая же, как у `welt_rov`: контейнер монтирует весь репозиторий,
а `run_rov.sh` собирает нужные пакеты и запускает аппарат.

## Подготовка

На компьютере аппарата нужны Docker и доступ к репозиториям подмодулей:

```bash
git clone --recurse-submodules git@github.com:hydronautics-team/nulina_rov.git
cd nulina_rov
# Для уже клонированного репозитория:
git submodule update --init --recursive
./build_docker.sh
```

Образ называется `nulina_rov:humble`; он содержит зависимости AH127C, MS5837,
GPIO, контроллера и RQT. Его нужно собирать на целевой архитектуре компьютера.

## Запуск

Из корня репозитория на аппарате:

```bash
./run_docker.sh
# Внутри контейнера:
./run_rov.sh
```

Либо одной командой:

```bash
./run_docker.sh ./run_rov.sh
```

По умолчанию используются контейнер `nulina_rov`, `ROS_DOMAIN_ID=1` и
`ROS_LOCALHOST_ONLY=0`. ROS domain должен совпадать с компьютером пульта.
Переопределение образа, имени и домена:

```bash
IMAGE_NAME=stingray_core CONTAINER_NAME=nulina_rov ROS_DOMAIN_ID=1 ./run_docker.sh
```

При использовании существующего образа в нём должны быть установлены все
зависимости из `docker/Dockerfile`. Скрипт не удаляет существующий контейнер;
во второй терминал уже запущенного контейнера можно войти командой
`docker exec -it nulina_rov bash`.

## Оборудование и настройки

Запускаются serial bridge, драйвер шести движителей, контроллер, AH127C,
MS5837 и GPIO-питание. В этой ветке нет DVL и локализации Welt.

| Устройство | Подключение / топик | Где настраивается |
| --- | --- | --- |
| Плата движителей | `/dev/ttyAMA5`, 115200 | `src/nulina_config/communication/thruster.params.yaml` |
| AH127C | `/dev/ttyUSB0`, 115200; `/imu_full_data` (`sensor_msgs/Imu`) | Порт и скорость фиксированы в драйвере этой ветки |
| MS5837 | I²C; `/ms5837/depth` (`std_msgs/Float32`, метры) | Драйвер `ms5837_pressure_sensor` |
| Питание | `gpiochip0`, линия 16, включено при старте | `src/stingray_core/src/power_control/config/power_gpio.param.yaml` |

Контроллер получает IMU из `/imu_full_data`, глубину из `/ms5837/depth`,
команды из `/control/data` и маску контуров из `/control/loop_flags`.
Матрица движителей и коэффициенты сохранены из конфигурации Нулины.

Три YAML-файла управления находятся в `src/nulina_config/control`.
Изменения через RQT сохраняются туда же на хосте и загружаются при следующем
запуске. Для этого `build.sh` идемпотентно применяет небольшой патч
`patches/stingray_core-platform-config.patch`: добавляет поддержку
`STINGRAY_CONFIG_DIR` в функции выбора путей сохранения старого ядра.
После сборки изменение `save_params.py` в подмодуле ожидаемо; сам патч хранится
в этом репозитории и воспроизводится при чистом клонировании.

Launch-аргументы передаются через `run_rov.sh`, например внутри контейнера:

```bash
./run_rov.sh thruster_params_file:=/stingray_core/src/nulina_config/communication/thruster.params.yaml
./run_rov.sh control_config_dir:=/stingray_core/src/nulina_config/control
```

Неиспользуемые конфиги panel, pressure, power и старого pressure_sensor
не участвуют в основном запуске.

## Проверка без оборудования

Внутри контейнера можно собрать пакеты и проверить описание запуска, не
запуская драйверы:

```bash
./build.sh
source install/setup.bash
ros2 launch nulina_bringup run_rov.launch.py --show-args
ROS_LOCALHOST_ONLY=1 python3 -m unittest discover -s tests -v
```

Тесты создают только контроллер, не запускают его цикл управления и проверяют
загрузку настроек, приём IMU/глубины и сохранение коэффициента после перезапуска.
Настройки для тестов копируются во временный каталог.

После запуска на аппарате проверить потоки данных:

```bash
ros2 topic hz /imu_full_data
ros2 topic hz /ms5837/depth
ros2 lifecycle get /serial_bridge_node
```

Serial bridge должен быть в состоянии `active`. Реальную связь с UART/I²C,
GPIO и направления движителей необходимо проверять на аппарате.
