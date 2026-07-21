# gitlab — шпаргалка

Роль разворачивает **GitLab (omnibus)** внутри отдельного хоста `gitlab`
(группа `gitlab_node`) с **самоподписным** TLS-сертификатом.

## Что делает
1. Копирует **заранее сгенерированный локально** TLS-сертификат из
   `ansible-modular/certs/gitlab/` в `/etc/gitlab/ssl` на хосте (сама не генерирует!).
2. Подключает официальный apt-репозиторий GitLab и ставит `gitlab-ce`.
3. Рендерит `/etc/gitlab/gitlab.rb` из `templates/gitlab.rb.j2`
   (HTTPS + self-signed, Let's Encrypt выключен).
4. Запускает `gitlab-ctl reconfigure`, ждёт порт 443.

## Где что лежит
- Переменные группы: `inventory/group_vars/gitlab_node/main.yml` (открытые) и
  `vault.yml` (пароль root).
- Шаблон конфига: `templates/gitlab.rb.j2`.
- Каталог установки на хосте: `/etc/gitlab` (`gitlab.rb`, `gitlab-secrets.json`).

## Секреты
Пароль root — только в зашифрованном `vault.yml`. Работа с ним:
```bash
ansible-vault edit --vault-password-file=.vault_pass \
  inventory/group_vars/gitlab_node/vault.yml
```

## TLS-сертификат (генерируется локально, вне роли)
См. `ansible-modular/certs/gitlab/README.md`. Файлы `gitlab.crt` / `gitlab.key`
должны совпадать по CN/SAN с `gitlab_hostname`.

## Запуск
```bash
ansible-playbook -i inventory playbooks/gitlab.yml --vault-password-file=.vault_pass
```

## Переменные (коротко)
| Переменная | Значение по умолчанию | Где |
|------------|----------------------|-----|
| `gitlab_edition` | `gitlab-ce` | group_vars |
| `gitlab_version` | `` (latest) | group_vars |
| `gitlab_hostname` | `gitlab.home.local` | group_vars |
| `gitlab_external_url` | `https://gitlab.home.local` | group_vars |
| `gitlab_https_port` | `443` | group_vars |
| `gitlab_ssl_dir` | `/etc/gitlab/ssl` | defaults |
| `gitlab_cert_file` | `gitlab.crt` | defaults |
| `gitlab_key_file` | `gitlab.key` | defaults |
| `gitlab_root_password` | (vault) | vault.yml |
