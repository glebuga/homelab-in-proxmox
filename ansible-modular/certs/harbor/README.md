# TLS-сертификат для Harbor

Роль `harbor` **не генерирует** сертификат — она только копирует готовые
`harbor.crt` и `harbor.key` из этой папки в `/data/cert` на хосте Harbor.

Это сделано намеренно: сертификат выпускается отдельно (вне таск роли), чтобы
не перевыпускать его на каждом прогоне плейбука.

## Требования

- `CN` (Common Name) сертификата должен совпадать с `harbor_hostname`
  (см. `inventory/group_vars/harbor_nodes/main.yml`).
- Если используется внутренний CA — его корневой сертификат нужно добавить
  в доверенные на клиентах (`/etc/ssl/certs/ca-certificates.crt`).
- Файлы должны называться ровно `harbor.crt` и `harbor.key` (имена задаются
  переменными `harbor_cert_file` / `harbor_key_file`).

## Как сгенерировать (пример, самоподписанный)

```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
  -keyout harbor.key \
  -out harbor.crt \
  -subj "/CN=harbor.home.local" \
  -addext "subjectAltName=DNS:harbor.home.local,IP:192.168.0.x"
```

## Безопасность

Сами `*.crt` / `*.key` **не коммитятся** (см. `.gitignore` в корне проекта).
В репозитории остаётся только этот `README.md`.
