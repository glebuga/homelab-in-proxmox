# harbor — шпаргалка

Роль разворачивает **Harbor registry поверх HTTPS** внутри отдельного LXC-контейнера
`harbor` (группа `harbor_nodes`), используя официальный docker-compose инсталлятор.

## Что делает
1. Ставит Docker + docker-compose-plugin.
2. Копирует **заранее сгенерированный** TLS-сертификат из
   `ansible-modular/certs/harbor/` в `/data/cert` на хосте (сама не генерирует!).
3. Качает и распаковывает релиз Harbor (`harbor-online-installer-<ver>.tgz`).
4. Рендерит `harbor.yml` из `templates/harbor.yml.j2` (HTTPS + пароль из vault).
5. Запускает `install.sh` (docker compose up).
6. Ждёт порт HTTPS.

## Где что лежит
- Переменные группы: `inventory/group_vars/harbor_nodes/main.yml` (открытые) и
  `vault.yml` (зашифрованный пароль админа).
- Шаблон конфига: `templates/harbor.yml.j2`.
- Каталог установки на хосте: `/opt/harbor` (там `harbor.yml`, `docker-compose.yml`, `install.sh`).

## Секреты
Пароль админа — только в зашифрованном `vault.yml`. Работа с ним:
```bash
# посмотреть/отредактировать
ansible-vault edit --vault-password-file=.vault_pass \
  inventory/group_vars/harbor_nodes/vault.yml
# перешифровать под свой пароль
ansible-vault rekey --ask-vault-pass \
  inventory/group_vars/harbor_nodes/vault.yml
```

## TLS-сертификат (генерируется вручную, вне роли)
См. `ansible-modular/certs/harbor/README.md`. Файлы `harbor.crt` / `harbor.key`
должны совпадать по CN с `harbor_hostname`.

## Запуск
```bash
ansible-playbook -i inventory playbooks/harbor.yml --vault-password-file=.vault_pass
```

## Переменные (коротко)
| Переменная | Значение по умолчанию | Где |
|------------|----------------------|-----|
| `harbor_version` | `v2.10.1` | group_vars |
| `harbor_hostname` | `harbor.home.local` | group_vars |
| `harbor_https_port` | `443` | group_vars |
| `harbor_admin_username` | `gvinogradov` | group_vars |
| `harbor_admin_password` | (vault) | vault.yml |
| `harbor_with_trivy` | `true` | group_vars |
| `harbor_install_dir` | `/opt/harbor` | defaults |
| `harbor_packages` | `[docker.io, docker-compose-plugin]` | defaults |
