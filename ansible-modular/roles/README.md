# Roles

Переиспользуемые, самодостаточные блоки настройки («рецепты»). Каждая роль
следует стандартной структуре Ansible:

```
roles/<имя>/
├── tasks/main.yml      # шаги, которые нужно применить
├── handlers/main.yml   # действия по `notify` (например, перезапуск сервисов)
├── defaults/main.yml   # переменные низкого приоритета (безопасно переопределять)
├── vars/main.yml       # переменные высокого приоритета (внутренние для роли)
├── meta/main.yml       # метаданные / зависимости
├── templates/          # Jinja2-шаблоны (`.j2`)
└── files/              # статические файлы (копируются как есть)
```

## Роли в этом проекте

| Роль        | Статус      | Назначение                                  |
|-------------|-------------|---------------------------------------------|
| `bootstrap` | **готово**  | Начальная настройка хоста: admin, SSH, sudo.|
| `common`    | **готово**  | Базовая настройка ОС: пакеты, NTP, автообновления. |
| `dns`       | **готово**  | DNS-сервер dnsmasq (net_service).           |
| `docker`    | **готово**  | Docker + compose-plugin. Единый источник установки Docker; другие роли (harbor) зависят от неё. |
| `harbor`    | **готово**  | Harbor registry over HTTPS (docker compose). Зависит от `docker`. |
| `firewall`  | заготовка   | Правила iptables.                           |
| `nginx`     | заготовка   | Reverse-proxy Nginx.                        |
| `etcd`      | заготовка   | Кластер etcd.                               |
| `patroni`   | заготовка   | Отказоустойчивый Postgres (Patroni).        |

Заготовки ролей содержат только пустые `main.yml`; реализуйте их по одной по
мере необходимости. См. [`bootstrap/README.md`](bootstrap/README.md) для
примеров полностью реализованной роли.

## Единый источник правды (SSOT)

- **Глобальные переменные** (`timezone`, `locale`, `admin_user`,
  `bootstrap_user`, `proxmox`, `management_ip`) определены один раз в
  [`inventory/group_vars/all/main.yml`](../inventory/group_vars/all/main.yml).
  Роли ссылаются на них напрямую и не переопределяют.
- **Docker** устанавливается только ролью `docker`. Роль `harbor` объявляет
  её как зависимость в `meta/main.yml` и не дублирует установку Docker.
- **Секреты** Harbor (`harbor_admin_password`, `harbor_db_password`)
  хранятся в зашифрованном `inventory/group_vars/harbor_nodes/vault.yml`
  и не дублируются в открытых файлах.
