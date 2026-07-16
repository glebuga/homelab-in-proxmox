# Роль: common

Базовая настройка ОС, применяемая ко всем хостам сразу после `bootstrap`
(через [`playbooks/site.yml`](../playbooks/site.yml), второй play, группа
`all:!hq`). Выполняется **после** роли `dns`, чтобы установка пакетов шла
через уже поднятый внутренний DNS-сервер.

## Что делает

1. Обновляет apt-кэш.
2. (Опционально) обновляет все пакеты (`common_upgrade`).
3. Устанавливает базовые пакеты (`common_packages`).
4. Настраивает NTP через `systemd-timesyncd`.
5. Включает таймер автообновлений (`unattended-upgrades`).
6. (Опционально) базовый `.bashrc` для admin (`common_shell_config`).

## Переменные

| Переменная                  | По умолчанию | Назначение                           |
|-----------------------------|--------------|--------------------------------------|
| `common_packages`           | см. роль     | Список базовых пакетов.              |
| `common_upgrade`            | `false`      | Обновлять ли все пакеты.             |
| `common_upgrade_mode`       | `dist`       | Режим обновления.                    |
| `common_unattended_upgrades`| `true`       | Включить автообновления security.    |
| `common_shell_config`       | `false`      | Настраивать `.bashrc` admin.         |
| `common_ntp_servers`        | пулы NTP     | NTP-серверы.                         |

## Зависимости

Требует, чтобы роль `dns` уже отработала на `net_service` (см. порядок в
`playbooks/site.yml`).
