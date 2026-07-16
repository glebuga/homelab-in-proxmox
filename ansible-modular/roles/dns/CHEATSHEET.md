# dns — шпаргалка по таскам

Внутренний DNS (dnsmasq). Ставится на группу `net_service` (хост `dns`,
10.0.0.104). Playbook `playbooks/site.yml`.

| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Install dnsmasq | `apt install dnsmasq` | DNS-сервер для локальной сети |
| Generate hosts file | шаблон `homelab.hosts.j2` → `/etc/homelab.hosts` | статические записи `*.home.local` |
| Configure dnsmasq | шаблон `dnsmasq.conf.j2` → `/etc/dnsmasq.d/homelab.conf` | настройка dnsmasq (интерфейсы, upstream) |
| Enable and start dnsmasq | включает/стартует сервис | DNS отвечает клиентам |
| Apply changes | `meta: flush_handlers` | применяет restart dnsmasq сразу |

**Итог:** внутренний резолвер, контейнеры/ВМ видят друг друга по `*.home.local`.
