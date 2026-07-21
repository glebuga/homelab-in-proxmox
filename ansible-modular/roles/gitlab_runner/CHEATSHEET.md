# gitlab_runner — шпаргалка

Роль ставит **GitLab Runner** и регистрирует его через `config.toml` + токен
`glrt-...` (без `gitlab-runner register`, без legacy registration token).

## Что делает
1. Репозиторий GitLab Runner (apt, ключ в `/etc/apt/keyrings/gitlab-runner.gpg`).
2. Пакет `gitlab-runner`.
3. Рендер `config.toml` (`force: false` — не затирает ручные правки).
4. Сервис `gitlab-runner` enabled + started.

## Где что
- `defaults/main.yml` — `gitlab_runner_gitlab_url`, `gitlab_runner_executor` (shell/docker), `gitlab_runner_token`, теги, concurrent.
- `templates/config.toml.j2` — итоговый конфиг.
- Токен: `inventory/group_vars/gitlab_node/vault.yml` (`gitlab_runner_token`).

## Токен (glrt-...)
Создаётся в GitLab UI/API (Admin → Runners или проект → Settings → CI/CD → Runners),
кладётся в зашифрованный `vault.yml`.

## Запуск
```bash
ansible-playbook -i inventory playbooks/gitlab_runner.yml \
  --vault-password-file=/home/admin/homelab-infra/.vault_pass
```

## Переменные
| Переменная | Дефолт | Где |
|------------|--------|-----|
| `gitlab_runner_gitlab_url` | `https://gitlab.home.local` | defaults |
| `gitlab_runner_executor` | `shell` | defaults |
| `gitlab_runner_token` | `` (vault) | vault.yml |
| `gitlab_runner_tags` | `local,shell` | defaults |
| `gitlab_runner_concurrent` | `2` | defaults |
| `gitlab_runner_repo_codename` | `jammy` | defaults |
