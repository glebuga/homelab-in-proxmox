# TLS-сертификат для GitLab

Роль `gitlab` **не генерирует** сертификат — она только копирует готовые
`gitlab.crt` и `gitlab.key` из этой папки в `/etc/gitlab/ssl` на хосте GitLab.

Это сделано намеренно: сертификат выпускается отдельно (вне таск роли), чтобы
не перевыпускать его на каждом прогоне плейбука.

## Требования

- `CN` (Common Name) и `subjectAltName` сертификата должны совпадать с
  `gitlab_hostname` (см. `inventory/group_vars/gitlab_node/main.yml`).
- Файлы должны называться ровно `gitlab.crt` и `gitlab.key` (имена задаются
  переменными `gitlab_cert_file` / `gitlab_key_file`).
- Если используется внутренний CA — его корневой сертификат нужно добавить
  в доверенные на клиентах (`/etc/ssl/certs/ca-certificates.crt`).

## Как сгенерировать (пример, самоподписанный)

```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout gitlab.key \
  -out gitlab.crt \
  -subj "/CN=gitlab.home.local" \
  -addext "subjectAltName=DNS:gitlab.home.local,IP:192.168.0.x"
```

## Безопасность

Сами `*.crt` / `*.key` **не коммитятся** (см. `.gitignore` в корне проекта).
В репозитории остаётся только этот `README.md`.
