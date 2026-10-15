# Сборка и запуск Nulina ROV

Команда `run nulina` предназначена для локального выполнения на компьютере
Нулины. Она не устанавливает SSH-соединение и не запускает аппарат на другом
хосте.

## Первый запуск

На компьютере аппарата должны быть установлены Git и Docker. Пользователь,
запускающий Нулину, должен иметь доступ к Docker daemon и устройствам аппарата.

Клонировать проект и подготовить подмодули:

```bash
git clone --recurse-submodules git@github.com:hydronautics-team/nulina_rov.git
cd nulina_rov
git submodule update --init --recursive
```

Собрать Docker-образ для архитектуры компьютера Нулины:

```bash
./build_docker.sh
```

По умолчанию создаётся образ `nulina_rov:humble`.

## Установка команды `run`

Из корня репозитория выполнить:

```bash
./scripts/install-cli.sh
```

Установщик создаёт символическую ссылку `~/.local/bin/run` на скрипт текущего
клона. Благодаря этому команда работает из любого каталога, а изменения скрипта
в репозитории применяются без повторной установки.

Если `~/.local/bin` отсутствует в `PATH`, установщик напечатает подсказку.
Добавить каталог для Bash можно так:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Проверить установку:

```bash
command -v run
run --help
```

Если репозиторий перемещён, повторно выполните `./scripts/install-cli.sh` из его
нового расположения.

## Обычный запуск

```bash
run nulina
```

Команду можно выполнять из любого рабочего каталога. Во время запуска:

1. `run` находит корень репозитория;
2. `local_run.sh` запускает Docker-контейнер;
3. `run_rov.sh` собирает выбранные ROS 2-пакеты;
4. запускается `nulina_bringup/run_rov.launch.py`.

Остановить ROS и контейнер можно сочетанием `Ctrl+C`. Контейнер запускается с
`--rm` и после остановки удаляется автоматически.

## Debug-режим

```bash
run nulina --debug
```

Debug-режим включает shell-трассировку launcher: перед выполнением в терминале
показываются команды и их аргументы. Это помогает увидеть фактический путь
репозитория, команду запуска контейнера и вызов `ros2 launch`.

Флаг `--debug` должен следовать сразу после `nulina`.

## Launch-аргументы

Все аргументы после имени цели передаются в `ros2 launch`. Например:

```bash
run nulina \
  control_config_dir:=/stingray_core/src/nulina_config/control

run nulina \
  thruster_params_file:=/stingray_core/src/nulina_config/communication/thruster.params.yaml
```

Debug-режим можно сочетать с launch-аргументами:

```bash
run nulina --debug \
  control_config_dir:=/stingray_core/src/nulina_config/control
```

Доступные аргументы текущего launch-файла можно посмотреть внутри контейнера:

```bash
./run_docker.sh bash
source install/setup.bash
ros2 launch nulina_bringup run_rov.launch.py --show-args
```

## Переменные окружения

Параметры Docker и ROS можно задать перед командой:

```bash
ROS_DOMAIN_ID=2 run nulina
ROS_LOCALHOST_ONLY=1 run nulina
IMAGE_NAME=nulina_rov:humble CONTAINER_NAME=nulina_rov run nulina
```

Значения по умолчанию:

| Переменная | Значение | Назначение |
| --- | --- | --- |
| `IMAGE_NAME` | `nulina_rov:humble` | Docker-образ |
| `CONTAINER_NAME` | `nulina_rov` | Имя контейнера |
| `ROS_DOMAIN_ID` | `1` | ROS 2 domain |
| `ROS_LOCALHOST_ONLY` | `0` | Разрешить обмен ROS по сети |

`ROS_DOMAIN_ID` должен совпадать с domain компьютера пульта.

## Запуск без установленной команды

Из корня репозитория доступны эквивалентные команды:

```bash
./local_run.sh
./local_run.sh --debug
```

Для ручной диагностики отдельных слоёв:

```bash
./run_docker.sh                 # открыть Bash в контейнере
./run_docker.sh ./run_rov.sh    # собрать и запустить аппарат
```

## Типовые ошибки

### `run: command not found`

Выполните установщик и убедитесь, что `~/.local/bin` добавлен в `PATH`:

```bash
./scripts/install-cli.sh
export PATH="$HOME/.local/bin:$PATH"
```

### Нет доступа к Docker daemon

Проверьте Docker и права текущего пользователя:

```bash
docker version
docker image inspect nulina_rov:humble
```

### Docker-образ не найден

Соберите его на компьютере Нулины:

```bash
./build_docker.sh
```

### Контейнер с таким именем уже существует

Проверьте, не запущен ли уже экземпляр аппарата:

```bash
docker ps -a --filter name=nulina_rov
```

Не удаляйте работающий контейнер, пока не убедитесь, что аппарат безопасно
остановлен.

### Не инициализирован `stingray_core`

```bash
git submodule update --init --recursive
```

После этого повторите `run nulina`.
