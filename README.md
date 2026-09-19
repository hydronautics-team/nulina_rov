# NULINA — запуск аппарата

## Структура запуска

Проект разделяет запуск Docker-контейнера и запуск самого аппарата:

```text
run
 │
 └── SSH → NULINA
          │
          └── local_run.sh
                   │
                   └── run_docker.sh
                            │
                            └── stingray_core/docker/run.sh
                                     │
                                     └── Docker
                                              │
                                              └── run_rov.sh
                                                       │
                                                       ├── colcon build
                                                       └── ros2 launch
```

### Назначение скриптов

| Скрипт                            | Где выполняется | Назначение                                |
| --------------------------------- | --------------- | ----------------------------------------- |
| `run`                             | ПК разработчика | Удобная команда для запуска аппарата      |
| `local_run.sh`                    | NULINA          | Локальный entrypoint для запуска NULINA   |
| `run_docker.sh`                   | NULINA          | Универсальный wrapper для запуска Docker  |
| `src/stingray_core/docker/run.sh` | NULINA          | Непосредственный запуск Docker-контейнера |
| `run_rov.sh`                      | внутри Docker   | Сборка пакетов и запуск ROS2              |

---

# 1. Запуск Docker

`run_docker.sh` является универсальным скриптом и не содержит специфичной логики.

Запуск:

```bash
./run_docker.sh
```

Он запускает контейнер `stingray_core`.

Для запуска конкретной команды внутри контейнера скрипт поддерживает передачу аргументов дальше в `docker run`.

Например:

```bash
./run_docker.sh bash
```

---

# 2. Запуск NULINA

Для запуска аппарата используется отдельный:

```bash
./local_run.sh
```

Скрипт:

1. переходит в корень `nulina_rov`;
2. задаёт параметры Docker;
3. запускает `stingray_core/docker/run.sh`;
4. передаёт ему команду запуска Нулины.

Фактически внутри контейнера выполняется:

```bash
cd /stingray_core
./run_rov.sh
```

`run_rov.sh`:

1. собирает необходимые ROS2-пакеты;
2. выполняет `source install/setup.bash`;
3. запускает:

```bash
ros2 launch nulina_bringup run_rov.launch.py
```

---

# 3. Первый запуск на аппарате

На аппарате должен быть установлен Docker.

Проверить:

```bash
docker --version
```

и:

```bash
docker images
```

Должен присутствовать образ:

```text
stingray_core
```

Проверить наличие исходников:

```bash
cd ~/nulina_rov
ls
```

Ожидается:

```text
local_run.sh
run_docker.sh
run_rov.sh
src/
```

Сделать скрипты исполняемыми:

```bash
chmod +x local_run.sh
chmod +x run_docker.sh
chmod +x run_rov.sh
chmod +x src/stingray_core/docker/run.sh
```

После этого можно проверить запуск непосредственно на аппарате:

```bash
cd ~/nulina_rov
./local_run.sh
```

---

# 4. Запуск с компьютера разработчика

Чтобы не заходить вручную по SSH, можно сделать команду:

```bash
run nulina
```

Для этого на компьютере разработчика создаётся:

```bash
~/.local/bin/run
```

Содержимое:

```bash
#!/usr/bin/env bash
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: run <target>"
    exit 1
fi

case "$1" in
    nulina)
        ssh -t nulina@192.168.1.100 \
            'cd ~/nulina_rov && ./local_run.sh'
        ;;
    *)
        echo "Unknown target: $1"
        echo "Available targets:"
        echo "  nulina"
        exit 1
        ;;
esac
```

IP:

```text
192.168.1.100
```

необходимо заменить на актуальный IP аппарата.

Сделать файл исполняемым:

```bash
chmod +x ~/.local/bin/run
```

Добавить `~/.local/bin` в `PATH`:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

Применить:

```bash
source ~/.bashrc
```

После этого:

```bash
run nulina
```

запустит аппарат.

---

# 5. SSH без пароля

Для удобной работы рекомендуется настроить SSH-ключ.

На новом ПК:

```bash
ssh-keygen -t ed25519
```

Можно несколько раз нажать `Enter`, если пароль для ключа не требуется.

Проверить:

```bash
ls ~/.ssh/
```

Должен появиться:

```text
id_ed25519
id_ed25519.pub
```

Передать публичный ключ на NULINA:

```bash
ssh-copy-id nulina@192.168.1.100
```

После этого:

```bash
ssh nulina@192.168.1.100
```

не должен требовать пароль пользователя.

Проверить:

```bash
ssh nulina@192.168.1.100 'echo OK'
```

Ожидаемый результат:

```text
OK
```

---

# 6. Автоматическая настройка SSH на новом ПК

Чтобы не запоминать IP, пользователя и дополнительные параметры, можно создать:

```bash
~/.ssh/config
```

Например:

```sshconfig
Host nulina
    HostName 192.168.1.100
    User nulina
    IdentityFile ~/.ssh/id_ed25519
```

После этого подключение выполняется просто:

```bash
ssh nulina
```

А `run` можно упростить до:

```bash
#!/usr/bin/env bash
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: run <target>"
    exit 1
fi

case "$1" in
    nulina)
        ssh -t nulina \
            'cd ~/nulina_rov && ./local_run.sh'
        ;;
    *)
        echo "Unknown target: $1"
        echo "Available targets:"
        echo "  nulina"
        exit 1
        ;;
esac
```

Теперь:

```bash
run nulina
```

---

# 7. Полная настройка нового ПК

На новом компьютере достаточно выполнить следующие шаги.

### 1. Создать SSH-ключ

```bash
ssh-keygen -t ed25519
```

### 2. Скопировать ключ на NULINA

```bash
ssh-copy-id nulina@192.168.1.100
```

### 3. Настроить SSH alias

Создать:

```bash
nano ~/.ssh/config
```

Добавить:

```sshconfig
Host nulina
    HostName 192.168.1.100
    User nulina
    IdentityFile ~/.ssh/id_ed25519
```

### 4. Проверить SSH

```bash
ssh nulina
```

### 5. Создать команду `run`

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/run
```

Добавить:

```bash
#!/usr/bin/env bash
set -e

if [ "$#" -ne 1 ]; then
    echo "Usage: run <target>"
    exit 1
fi

case "$1" in
    nulina)
        ssh -t nulina \
            'cd ~/nulina_rov && ./local_run.sh'
        ;;
    *)
        echo "Unknown target: $1"
        echo "Available targets:"
        echo "  nulina"
        exit 1
        ;;
esac
```

### 6. Сделать `run` исполняемым

```bash
chmod +x ~/.local/bin/run
```

### 7. Добавить `~/.local/bin` в PATH

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 8. Запустить

```bash
run nulina
```

---

# 8. Что происходит при `run nulina`

Команда:

```bash
run nulina
```

вызывает:

```text
ПК разработчика
│
│ ssh -t nulina
▼
Нулина
│
│ ~/nulina_rov/local_run.sh
▼
run_docker.sh
│
▼
stingray_core/docker/run.sh
│
│ docker run ...
▼
Docker container
│
│ cd /stingray_core
│ ./run_rov.sh
▼
colcon build
│
▼
ros2 launch nulina_bringup run_rov.launch.py
```

`ssh -t` нужен для корректной работы интерактивного Docker-контейнера (`docker run -it`) и передачи `Ctrl+C`.

---

# 9. Остановка

Для остановки аппарата достаточно:

```text
Ctrl+C
```

Сигнал передаётся через SSH в Docker-контейнер, после чего ROS2 launch завершается.

Так как контейнер запускается с:

```bash
--rm
```

после завершения он автоматически удаляется.

---

# 10. Переменные окружения

Параметры можно переопределить перед запуском:

```bash
IMAGE_NAME=my_image ./local_run.sh
```

или:

```bash
CONTAINER_NAME=my_container ./local_run.sh
```

или:

```bash
ROS_DOMAIN_ID=2 ./local_run.sh
```

По умолчанию используются:

```text
IMAGE_NAME=stingray_core
CONTAINER_NAME=nulina_rov
ROS_DOMAIN_ID=1
```

---

# 11. Требования

На компьютере разработчика:

* Linux;
* SSH client;
* доступ по сети к Нулине;
* настроенный SSH-ключ.

На Нулине:

* Docker;
* образ `stingray_core`;
* исходный код `nulina_rov`;
* доступ к устройствам `/dev`;

---

# 12. Быстрый запуск

После первоначальной настройки вся последовательность сводится к одной команде:

```bash
run nulina
```

Для непосредственного запуска на самом аппарате:

```bash
cd ~/nulina_rov
./local_run.sh
```
