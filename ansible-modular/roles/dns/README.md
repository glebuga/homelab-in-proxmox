# Роль: dns (сервер)

DNS-сервер на базе dnsmasq для локальной сети homelab. Применяется только к
группе `net_service` и должен выполняться **до** роли `common`, потому что
клиенты уже указывают на этот сервер (через Terraform).

## Что делает

1. Устанавливает `dnsmasq`.
2. Генерирует `/etc/homelab.hosts` из инвентаря (все хосты → IP + имя.home.local).
3. Настраивает dnsmasq через `/etc/dnsmasq.d/homelab.conf`:
   - слушает на `127.0.0.1` и IP хоста,
   - отдаёт локальную зону `home.local` из `homelab.hosts`,
   - пересылает внешние запросы на апстрим-серверы (`dns_upstream_servers`).
4. Включает и запускает службу.

## Переменные

| Переменная               | По умолчанию               | Назначение                       |
|--------------------------|----------------------------|----------------------------------|
| `dns_domain`             | `home.local`               | Внутренний домен (совпадает с search_domain в Terraform). |
| `dns_upstream_servers`   | роутер + 8.8.8.8 + 1.1.1.1 | Серверы для пересылки запросов.  |
| `dns_listen_addresses`   | `127.0.0.1`, `ansible_host`| Адреса прослушивания.            |
| `dns_hosts_file`         | `/etc/homelab.hosts`       | Файл статических хостов.         |
| `dns_config_file`        | `/etc/dnsmasq.d/homelab.conf` | Конфиг dnsmasq.               |

## Как вызывается

Через [`playbooks/site.yml`](../playbooks/site.yml) — первый play применяет
роль `dns` к группе `net_service`.
