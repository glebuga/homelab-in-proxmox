# common — шпаргалка по таскам

Базовая ОС-настройка всех хостов. Запускается на `all:!hq` после bootstrap
(playbook `playbooks/site.yml`).

| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Update apt cache | `apt update` (раз в час) | свежие метаданные пакетов |
| Upgrade all packages | `apt upgrade` | **только если** `common_upgrade: true` (по умолч. false) |
| Install common packages | curl/vim/htop/tree | базовый набор утилит на каждом хосте |
| Configure NTP (timesyncd) | шаблон `/etc/systemd/timesyncd.conf` | синхронизация времени с NTP |
| Enable and start systemd-timesyncd | включает/стартует timesyncd | время реально синхронизируется |
| Configure base shell for admin user | шаблон `.bashrc` | **только если** `common_shell_config: true` (по умолч. false) |

**Итог:** единообразная база ОС (пакеты, время). Авто-обновления и кастомный
bashrc выключены по умолчанию — обновления под твоим контролем.
