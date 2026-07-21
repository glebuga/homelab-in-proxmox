# Роль `gitlab_runner`

Устанавливает и настраивает **GitLab Runner** (shell-исполнитель) на хосте и подключает его
к GitLab-серверу по HTTPS с самоподписанным сертификатом. Регистрация выполняется **одноразово
через `config.toml`** (современный `glrt-` токен), без вызова `gitlab-runner register`.

---

## Переменные

| Переменная | Значение по умолчанию | Назначение |
|---|---|---|
| `gitlab_runner_gitlab_url` | `https://gitlab.home.local` | URL GitLab-сервера, к которому подключается раннер |
| `gitlab_runner_executor` | `shell` | Тип исполнителя (shell — без Docker) |
| `gitlab_runner_token` | `""` (из vault) | `glrt-...` токен аутентификации раннера |
| `gitlab_runner_tls_ca_file` | `/etc/gitlab/ssl/gitlab.home.local.crt` | Путь к CA-сертификату GitLab на хосте (для trust-store и `tls-ca-file`) |
| `gitlab_runner_tls_skip_verify` | `true` | `tls-skip-verify` в `config.toml` (доп. мера, процессом игнорируется — см. TLS) |
| `gitlab_runner_name` | `{{ inventory_hostname }}` | Имя раннера в GitLab |
| `gitlab_runner_tags` | `local,shell` | Теги раннера (через запятую) |
| `gitlab_runner_concurrent` | `2` | Число параллельных заданий |
| `gitlab_runner_user` | `gitlab-runner` | Пользователь, от имени которого работает сервис |
| `gitlab_runner_config_file` | `/etc/gitlab-runner/config.toml` | Путь к конфигу раннера |
| `gitlab_runner_repo_codename` | `jammy` | Codename репозитория apt (Ubuntu 22.04) |
| `gitlab_runner_version` | `""` | Пусто = последняя версия; иначе `gitlab-runner=<version>` |

> Токен `gitlab_runner_token` хранится в зашифрованном
> `inventory/group_vars/gitlab_node/vault.yml` и подставляется в `config.toml.j2`.

---

## Таски (по порядку)

1. **Install prerequisites for gitlab-runner repo** — ставит `ca-certificates`, `curl`, `gnupg`,
   необходимые для добавления внешнего apt-репозитория и работы HTTPS.

2. **Create GitLab keyrings directory** — создаёт `/etc/apt/keyrings` (владелец root, `0755`),
   куда будет положен dearmored GPG-ключ репозитория.

3. **Download GitLab Runner GPG key** — скачивает публичный GPG-ключ репозитория Runner
   (`packages.gitlab.com/runner/gitlab-runner/gpgkey`) во временный файл `/tmp/gitlab-runner-gpg.key`.

4. **Dearmor GitLab Runner GPG key into keyring** — конвертирует ключ в бинарный формат
   (`gpg --dearmor`) в `/etc/apt/keyrings/gitlab-runner.gpg`. Идемпотентно благодаря
   `creates:` — повторный прогон не перезаписывает ключ.

5. **Add GitLab Runner apt repository** — пишет `/etc/apt/sources.list.d/gitlab-runner.list`
   с указанием репозитория и `signed-by=` на ранее созданный keyring.

6. **Update apt cache for GitLab Runner repository** — обновляет кэш apt, чтобы увидеть пакет
   `gitlab-runner` из нового репозитория.

7. **Install GitLab Runner package** — устанавливает пакет `gitlab-runner` (при заданном
   `gitlab_runner_version` — фиксированную версию).

8. **Install GitLab CA certificate into system trust store** — копирует сертификат GitLab
   (`gitlab_runner_tls_ca_file`) в `/usr/local/share/ca-certificates/gitlab.crt` и ставит
   `notify: update ca certificates`. Это нужно, чтобы раннер (Go-процесс) доверял self-signed
   HTTPS GitLab. Выполняется только если `gitlab_runner_tls_ca_file` задан (`when:`).

9. **Render gitlab-runner config.toml** — рендерит `templates/config.toml.j2` в
   `/etc/gitlab-runner/config.toml` (`mode 0600`, `force: true`) и ставит
   `notify: restart gitlab-runner`. Именно здесь прописываются `url`, `token` (`glrt-`),
   `executor`, `tag_list`, `tls-ca-file`/`tls-skip-verify`.

10. **Enable and start gitlab-runner service** — через systemd включает автозапуск и запускает
    сервис `gitlab-runner`.

11. **Run runner diagnostic script** — запускает `scripts/gitlab-runner-diag.sh` на хосте
    (модуль `ansible.builtin.script`) с пробросом переменных окружения (`GITLAB_RUNNER_TLS_CA_FILE`,
    `GITLAB_RUNNER_TLS_SKIP_VERIFY`, `GITLAB_RUNNER_NAME`, `GITLAB_RUNNER_TAGS`,
    `GITLAB_RUNNER_CONCURRENT`). Скрипт пишет отчёт в `/tmp/gitlab_runner_report.txt`
    и проверяет доступность GitLab, статус сервиса и `gitlab-runner verify`.
    `changed_when: false` — диагностика не меняет состояние.

12. **Fetch runner diagnostic report from host** — читает `/tmp/gitlab_runner_report.txt`
    с хоста через `slurp` (важно: `lookup('file')` читал бы control-машину, а не хост).

13. **Show runner diagnostic report in terminal** — печатает содержимое отчёта
    (`b64decode`) в выводе playbook, чтобы сразу видеть: к какому хосту подключён раннер,
    его статус и результат `gitlab-runner verify`.

---

## Handlers

- **update ca certificates** — выполняет `update-ca-certificates` (пересобирает системный
  trust-бандл после добавления сертификата GitLab).
- **restart gitlab-runner** — перезапускает сервис `gitlab-runner` после смены `config.toml`.

---

## Запуск

```bash
cd ansible-modular
ansible-playbook -i inventory playbooks/gitlab_runner.yml \
  --vault-password-file=.vault_pass
```

Только на одном хосте:

```bash
ansible-playbook -i inventory playbooks/gitlab_runner.yml --limit gitlab \
  --vault-password-file=.vault_pass
```

---

## Диагностика раннера

После прогона плейбука отчёт печатается в терминале (таск 13). Пример вывода:

```
Host:     gitlab (10.0.0.105)
URL:      https://gitlab.home.local
EXEC:     shell
STATUS:   RUNNER OK — connected and authorized to https://gitlab.home.local
```

Получить отчёт вручную (на самом хосте раннера):

```bash
sudo /home/admin/homelab-infra/ansible-modular/scripts/gitlab-runner-diag.sh
cat /tmp/gitlab_runner_report.txt
```

Или удалённо с control-машины через Ansible:

```bash
ansible gitlab -i inventory -m slurp -a "path=/tmp/gitlab_runner_report.txt" \
  --vault-password-file=.vault_pass \
  | python3 -c "import sys,json,base64; print(base64.b64decode(json.load(sys.stdin)['/tmp/gitlab_runner_report.txt']['content']).decode())"
```

Прочитать сохранённый отчёт на хосте:

```bash
ansible gitlab -i inventory -m command -a "cat /tmp/gitlab_runner_report.txt" \
  --vault-password-file=.vault_pass
```

---

## TLS (self-signed)

Раннер подключается к GitLab по HTTPS с самоподписанным сертификатом. Чтобы `gitlab-runner verify`
и сами джобы не падали с `x509: certificate signed by unknown authority`:

- Сертификат GitLab копируется в системный trust-store (`/usr/local/share/ca-certificates/gitlab.crt`)
  и обновляется бандл (`update-ca-certificates`). Go-процесс раннера читает системный бандл.
- В `config.toml` также прописан `tls-ca-file` на тот же сертификат.
- `tls-skip-verify = true` добавлен как доп. мера, но **процессом runner 19.x и подкомандой
  `gitlab-runner verify` он игнорируется** — доверие обеспечивает именно trust-store + `tls-ca-file`.

> Важно: имя файла сертификата на стороне GitLab должно быть `<fqdn>.crt`
> (`gitlab.home.local.crt`) — иначе Omnibus сгенерирует свой и nginx будет отдавать его,
> а не наш сертификат (см. README роли `gitlab`).
