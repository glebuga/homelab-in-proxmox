# Роль Ansible: `harbor`

Роль разворачивает **Harbor** — приватный Docker-реестр (хранилище контейнерных образов) — на выделенном хосте. Harbor запускается как набор контейнеров через Docker Compose. Роль полностью автоматизирует установку: от установки Docker до создания нужного проекта в реестре и настройки автозапуска при загрузке системы.

---

## 1. Что делает роль в целом

Роль выполняет задачи в строгом порядке, потому что каждая следующая ступень зависит от предыдущей:

1. Ставит **Docker** и плагин `docker compose` (без них Harbor не запустить).
2. Копирует **TLS-сертификат и ключ** на хост (они нужны для работы по HTTPS).
3. Загружает и распаковывает **дистрибутив Harbor** (онлайн или из локального архива).
4. Генерирует конфигурационный файл `/opt/harbor/harbor.yml` из шаблона.
5. Запускает **официальный установщик** `install.sh`, который подготавливает конфиги и поднимает контейнеры.
6. Дополнительно гарантирует, что стек **реально запущен**, и создаёт **systemd-юнит** для автозапуска.
7. Ждёт, пока откроется HTTPS-порт.
8. Через API удаляет дефолтный проект `library` и создаёт нужный проект (по умолчанию `gitlab`).

Роль **идемпотентна**: повторный запуск не ломает уже работающий Harbor и не дублирует проект.

---

## 2. Откуда что берётся (источники данных)

| Что | Откуда |
|-----|--------|
| Переменные хоста (`harbor_hostname`, порты, пути, флаги компонентов, имя проекта) | `inventory/group_vars/harbor_nodes/main.yml` |
| Пароль администратора (`harbor_admin_password`) | `inventory/group_vars/harbor_nodes/vault.yml` (зашифрован ansible-vault) |
| TLS-сертификат и ключ | Локальная папка на управляющей машине `certs/harbor/` (роль **только копирует** их, не генерирует) |
| Дистрибутив Harbor | Либо скачивается с GitHub (онлайн), либо берётся из локального архива `harbor-installer/harbor-offline-installer-vX.Y.Z.tgz` |
| Шаблон конфига | `roles/harbor/templates/harbor.yml.j2` (основан на официальном `harbor.yml.tmpl` версии `harbor_version`) |
| Список пакетов Docker | `roles/harbor/defaults/main.yml` (`harbor_packages`) |

**Важно про администратора.** Harbor всегда использует логин `admin`, независимо от переменной `harbor_admin_username` (она не читается самим Harbor и оставлена для справки). Пароль берётся из `harbor_admin_password` (vault). Для входа в веб-интерфейс и для API используется связка `admin` + этот пароль.

---

## 3. Пошаговое описание задач (`tasks/main.yml`)

### Блок 1. Установка Docker и плагина compose
- **Install prerequisites for Docker repo** — ставит `ca-certificates`, `curl`, `gnupg` (нужны, чтобы добавить репозиторий Docker).
- **Create keyrings directory** — создаёт `/etc/apt/keyrings` для хранения ключа репозитория.
- **Add Docker GPG key** — скачивает GPG-ключ Docker в `/etc/apt/keyrings/docker.asc` (им подписаны пакеты).
- **Add Docker apt repository** — подключает официальный репозиторий Docker для Ubuntu.
- **Install Docker and compose plugin** — ставит `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin` (список в `harbor_packages`).
- **Enable and start docker service** — включает Docker в systemd и запускает его.

### Блок 2. Копирование TLS-сертификата
- **Ensure cert directory exists on host** — создаёт каталог на хосте (`harbor_cert_dir`, по умолчанию `/data/cert`).
- **Copy Harbor TLS certificate from external source** — копирует `harbor.crt` из `certs/harbor/` (управляющая машина) в `harbor_cert_dir` на хосте. При изменении триггерит перезапуск Harbor (`notify: restart harbor`).
- **Copy Harbor TLS private key from external source** — копирует `harbor.key` с правами `0600`. Также триггерит перезапуск.

> Сертификат должен быть сгенерирован заранее (с CN/SAN, совпадающим с `harbor_hostname`). Роль его не создаёт.

### Блок 3. Загрузка и распаковка Harbor
- **Ensure install directory exists** — создаёт `/opt/harbor` (`harbor_install_dir`).
- **Download Harbor installer (online)** — скачивает онлайн-инсталлятор с GitHub. Выполняется только если `harbor_offline_installer: false` и `harbor_skip_download: false`.
- **Use local offline installer archive** — копирует локальный `*.tgz` из `harbor_local_installer_src` в `/tmp`. Выполняется только если `harbor_offline_installer: true`.
- **Unpack Harbor installer** — распаковывает архив в `/opt/harbor` (`--strip-components=1`, чтобы не было вложенной папки). Пропускается, если уже есть `harbor.yml.tmpl` (`creates:`).

### Блок 4. Генерация конфигурации
- **Render harbor.yml configuration** — подставляет переменные в шаблон `harbor.yml.j2` и кладёт результат в `/opt/harbor/harbor.yml` с правами `0600`. `no_log: true` скрывает пароль из вывода. При изменении триггерит перезапуск Harbor.

> Шаблон содержит все обязательные секции, которые требует `prepare` из дистрибутива (включая `notification.webhook_job_http_client_timeout` и `log.level`). `internal_tls` в шаблоне **выключен** (`enabled: false`), потому что при включении Harbor требует отдельные внутренние сертификаты компонентов (`portal.crt`, `core.crt` и т.д.), которых роль не создаёт.

### Блок 5. Запуск установщика и гарантия запуска
- **Run Harbor installer** — запускает `/opt/harbor/install.sh`. Скрипт выполняет `prepare` (генерация конфигов компонентов) и `docker compose up -d` (подъём контейнеров). Пропускается, если уже есть `docker-compose.yml` (`creates:`).
- **Ensure Harbor stack is running** — явно выполняет `docker compose up -d`. Нужен на случай, если предыдущая задача была пропущена (файл `docker-compose.yml` уже существовал, например, после ручной установки), иначе контейнеры могли бы остаться остановленными.
- **Install Harbor auto-start systemd unit** — создаёт файл `/etc/systemd/system/harbor.service`. Юнит зависит от `docker.service` и запускает `docker compose up -d` при старте системы. Триггерит перезапуск Harbor.
- **Enable Harbor auto-start service** — включает юнит в systemd (`systemctl enable harbor`), чтобы он стартовал при загрузке.

> Автозапуск обеспечивается двойным механизмом: (а) `restart: always` в `docker-compose.yml` перезапускает контейнеры, когда Docker уже работает, и (б) юнит `harbor.service` явно делает `up -d` после старта Docker и сети.

### Блок 6. Ожидание готовности
- **Wait for Harbor HTTPS port** — ждёт, пока на `harbor_https_port` (443) начнётся прослушивание (таймаут 300 c). Если порт не откроется — playbook упадёт с ошибкой, сигнализируя, что Harbor не поднялся.

### Блок 7. Управление проектами (через API)
Harbor при первой установке сам создаёт проект `library`. Роль заменяет его на нужный:
- **Check if default library project exists** — GET-запрос к API; запоминает, существует ли `library` (статус 200/404).
- **Delete default library project** — удаляет `library`, только если он существует (`when: library_check.status == 200`).
- **Check if configured project already exists** — проверяет, есть ли проект с именем `harbor_project_name` (по умолчанию `gitlab`).
- **Create configured project** — создаёт проект (приватный, без лимита по месту), только если его ещё нет (`when: project_check.status == 404`).
- **Show Harbor URL and project** — выводит итоговый адрес и имя проекта.

Все обращения к API идут с логином `admin` и паролем из vault, с отключённой проверкой сертификата (`validate_certs: false`), так как обращение идёт на `harbor_hostname` внутри сети.

---

## 4. Handler (`handlers/main.yml`)

- **restart harbor** — выполняет `docker compose up -d` в `/opt/harbor`. Срабатывает, когда какая-то задача поменяла сертификат, конфиг или systemd-юнит (через `notify: restart harbor`). Это мягкий перезапуск: изменившиеся контейнеры пересоздаются, остальные трогать не обязательно.

---

## 5. Переменные

### `defaults/main.yml` (значения по умолчанию)
| Переменная | Значение | Назначение |
|-----------|----------|-----------|
| `harbor_install_dir` | `/opt/harbor` | Куда распакован Harbor |
| `harbor_skip_download` | `false` | Пропустить загрузку/распаковку дистрибутива |
| `harbor_offline_installer` | `false` | Использовать локальный архив вместо скачивания |
| `harbor_local_installer_src` | `""` | Путь к локальному архиву (если offline) |
| `harbor_packages` | список пакетов Docker | Что ставить через apt |
| `harbor_compose_bin` | `/usr/lib/docker/cli-plugins/docker-compose` | Путь к бинарю compose (для справки) |

### `group_vars/harbor_nodes/main.yml` (настройки хоста)
| Переменная | Пример | Назначение |
|-----------|--------|-----------|
| `harbor_hostname` | `harbor.home.local` | FQDN Harbor, должен совпадать с CN сертификата |
| `harbor_version` | `v2.10.1` | Версия дистрибутива |
| `harbor_http_port` | `80` | HTTP-порт (редирект на HTTPS) |
| `harbor_https_port` | `443` | HTTPS-порт |
| `harbor_admin_username` | `gvinogradov` | **Не используется Harbor** (только для справки) |
| `harbor_data_volume` | `/data` | Каталог с данными Harbor на хосте |
| `harbor_cert_dir` | `/data/cert` | Куда класть сертификат/ключ на хосте |
| `harbor_cert_file` | `harbor.crt` | Имя файла сертификата |
| `harbor_key_file` | `harbor.key` | Имя файла ключа |
| `harbor_local_cert_src` | `{{ playbook_dir }}/../certs/harbor` | Откуда брать сертификаты на управляющей машине |
| `harbor_with_trivy` | `true` | Включить сканер уязвимостей Trivy |
| `harbor_with_notary` | `false` | Включить Notary (подписание образов) |
| `harbor_with_chartmuseum` | `false` | Включить ChartMuseum (Helm-чарты) |
| `harbor_project_name` | `gitlab` | Имя проекта, который создаёт роль вместо `library` |

### `group_vars/harbor_nodes/vault.yml` (секреты, зашифровано)
| Переменная | Назначение |
|-----------|-----------|
| `harbor_admin_password` | Пароль администратора Harbor (логин всегда `admin`) |

---

## 6. Как запустить

Из каталога `ansible-modular`:

```bash
ansible-playbook playbooks/harbor.yml --vault-password-file=../.vault_pass
```

Playbook `playbooks/harbor.yml` просто применяет эту роль к группе `harbor_nodes`.

Полезные ключи:
- `--check` — прогон в режиме «что изменится» без реальных изменений.
- `--syntax-check` — только проверка синтаксиса.
- `-l harbor` — ограничить выполнение только хостом `harbor`.

---

## 7. Команды для диагностики

Все команды выполняются **на хосте Harbor** (через SSH) или с управляющей машины, если указано.

### Статус контейнеров Harbor
```bash
sudo docker ps --format "table {{.Names}}\t{{.Status}}"
```
Ожидаем: 9 контейнеров со статусом `Up ... (healthy)`.

### Быстрая проверка, что Harbor отвечает
```bash
curl -sk -o /dev/null -w "HTTP %{http_code}\n" https://harbor.home.local/
# или по IP:
curl -sk -o /dev/null -w "HTTP %{http_code}\n" https://10.0.0.106/
```
Ожидаем: `HTTP 200`.

### Список проектов (через API)
```bash
curl -sk -u "admin:ПАРОЛЬ" https://harbor.home.local/api/v2.0/projects \
  | python3 -c "import sys,json; print([p['name'] for p in json.load(sys.stdin)])"
```

### Логи конкретного контейнера
```bash
sudo docker logs --tail 100 harbor-core
sudo docker logs -f harbor-portal   # следить в реальном времени
```

### Перезапуск всего стека Harbor
```bash
cd /opt/harbor && sudo docker compose restart
# или полный перезапуск:
cd /opt/harbor && sudo docker compose down && sudo docker compose up -d
```

### Проверка автозапуска
```bash
systemctl is-enabled harbor     # должно быть: enabled
systemctl is-enabled docker     # должно быть: enabled
```

### Если Harbor «не запущен», хотя файл docker-compose.yml есть
Частая ситуация: `install.sh` уже отработал раньше, файл существует, и повторный запуск роли пропускает установщик, не поднимая контейнеры. Поднять вручную:
```bash
cd /opt/harbor && sudo docker compose up -d
```
(роль теперь делает это самой задачей **Ensure Harbor stack is running**).

### Прослушивание портов
```bash
sudo ss -tlnp | grep -E ":(80|443)"
```
Процесс `docker-proxy` на 80/443 означает, что порты заняты контейнерами Harbor.

---

## 8. Типичные проблемы и их причины

| Симптом | Причина | Решение |
|---------|---------|---------|
| `KeyError: 'webhook_job_http_client_timeout'` / `'level'` при `prepare` | В `harbor.yml` не хватает обязательных секций | Шаблон `harbor.yml.j2` уже содержит все нужные секции; не редактировать его «вручную в урезанном виде» |
| `KeyError: 'level'` в блоке `log` | Нет секции `log:` | Уже исправлено в шаблоне |
| Ошибка про `/data/secret/tls/portal.crt` | Включён `internal_tls: true`, но нет внутренних сертификатов компонентов | Держать `internal_tls.enabled: false` (так и настроено) |
| Harbor «установлен, но не запущен» | `install.sh` пропущен из-за `creates: docker-compose.yml`, контейнеры не подняты | Задача **Ensure Harbor stack is running** поднимает их; либо `docker compose up -d` вручную |
| Не пускает под `harbor_admin_username` | Harbor всегда использует `admin` | Логин `admin`, пароль из vault |

---

## 9. Структура роли

```
roles/harbor/
├── README.md                 # этот файл
├── defaults/main.yml         # дефолтные переменные (пакеты, пути)
├── handlers/main.yml         # handler «restart harbor»
├── tasks/main.yml            # основной сценарий (все блоки выше)
├── templates/
│   └── harbor.yml.j2         # шаблон конфига Harbor (на базе официального)
├── meta/main.yml             # зависимости роли (если есть)
└── vars/main.yml             # (опционально) переопределения переменных
```

Связанные файлы вне роли:
- `inventory/group_vars/harbor_nodes/main.yml` — настройки хоста.
- `inventory/group_vars/harbor_nodes/vault.yml` — зашифрованный пароль админа.
- `certs/harbor/` — исходные TLS-сертификат и ключ.
- `harbor-installer/` — локальный офлайн-архив (если используется).
- `playbooks/harbor.yml` — playbook, применяющий роль.
