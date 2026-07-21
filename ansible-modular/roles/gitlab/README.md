# Роль `gitlab`

Устанавливает **GitLab Omnibus** (CE/EE) с self-signed TLS-сертификатом и настраивает его
через `gitlab.rb`. Тяжёлые шаги (репозиторий, установка пакета, reconfigure) пропускаются
на уже живом инстансе через `when`/`creates` + предварительные `stat`/`wait_for` проверки.

---

## Переменные

| Переменная | Значение по умолчанию | Назначение |
|---|---|---|
| `gitlab_edition` | `gitlab-ce` | Редакция пакета (gitlab-ce / gitlab-ee) |
| `gitlab_hostname` | `gitlab.home.local` | FQDN — основа для имени сертификата `<fqdn>.crt` |
| `gitlab_external_url` | `https://{{ gitlab_hostname }}` | Внешний URL, задаётся в `EXTERNAL_URL` при установке |
| `gitlab_https_port` | `443` | Порт HTTPS для проверки доступности |
| `gitlab_ssl_dir` | `/etc/gitlab/ssl` | Каталог сертификатов Omnibus |
| `gitlab_local_cert_src` | `certs/gitlab` | Источник сертификата на control-машине |
| `gitlab_cert_file` | `gitlab.crt` | Имя файла-источника сертификата |
| `gitlab_key_file` | `gitlab.key` | Имя файла-источника ключа |
| `gitlab_ssl_cert_dest` | `{{ gitlab_hostname }}.crt` | Имя назначения (= `gitlab.home.local.crt`) — его ждёт Omnibus |
| `gitlab_ssl_key_dest` | `{{ gitlab_hostname }}.key` | Имя назначения ключа |
| `gitlab_repo_codename` | `jammy` | Codename репозитория apt (Ubuntu 22.04) |
| `gitlab_version` | `""` | Пусто = последняя; иначе фикс версия пакета |
| `gitlab_service` | `gitlab-runsvdir` | Имя systemd-сервиса |
| `gitlab_monitoring_enabled` | `false` | Вкл/выкл экспортеры (prometheus/node/redis/postgres) |
| `gitlab_letsencrypt_enabled` | `false` | Вкл/выкл Let's Encrypt (у нас self-signed) |
| `gitlab_root_password` | (из vault) | Пароль root, задаётся через `gitlab-rails runner` |

> `gitlab_root_password` хранится в зашифрованном `inventory/group_vars/gitlab_node/vault.yml`.

---

## Таски (по порядку)

### 1. Check if GitLab is already installed
```yaml
- name: Check if GitLab is already installed
  ansible.builtin.stat:
    path: /usr/bin/gitlab-ctl   # бинарь управления Omnibus — признак установки
  register: gitlab_installed     # сохраняем факт для when в таске установки пакета
```

### 2. Check if GitLab apt repository is already configured
```yaml
- name: Check if GitLab apt repository is already configured
  ansible.builtin.stat:
    path: /etc/apt/sources.list.d/gitlab_{{ gitlab_edition }}.list  # файл репозитория
  register: gitlab_repo_present   # факт: если есть — все таски репозитория пропускаем
```

### 3. Check if GitLab HTTPS port is already listening
```yaml
- name: Check if GitLab HTTPS port is already listening
  ansible.builtin.wait_for:
    port: "{{ gitlab_https_port }}"  # 443 — ждём, что уже отвечает
    timeout: 5                        # недолго, чтобы не тормозить прогон
  register: gitlab_port_listening     # факт: если успешно — финальный wait_for не нужен
  ignore_errors: true                 # порт может не слушать — это не ошибка, просто пропустим
```

### 4. Ensure GitLab SSL directory exists
```yaml
- name: Ensure GitLab SSL directory exists
  ansible.builtin.file:
    path: "{{ gitlab_ssl_dir }}"  # /etc/gitlab/ssl
    state: directory               # создаём, если нет
    owner: root
    group: root
    mode: "0700"                  # закрытый доступ — там лежит приватный ключ
```

### 5. Copy GitLab TLS certificate
```yaml
- name: Copy GitLab TLS certificate
  ansible.builtin.copy:
    src: "{{ gitlab_local_cert_src }}/{{ gitlab_cert_file }}"   # certs/gitlab/gitlab.crt (control)
    dest: "{{ gitlab_ssl_dir }}/{{ gitlab_ssl_cert_dest }}"     # /etc/gitlab/ssl/gitlab.home.local.crt
    owner: root
    group: root
    mode: "0644"                 # публичный сертификат — чтение всем
  notify: reconfigure gitlab     # после смены сертификата нужен reconfigure
```
> Важно: имя назначения — `<fqdn>.crt`. Omnibus игнорирует `nginx['ssl_certificate']`,
> если файл назван иначе, и сгенерирует свой. Наш раннер доверяет именно `gitlab.home.local.crt`.

### 6. Copy GitLab TLS private key
```yaml
- name: Copy GitLab TLS private key
  ansible.builtin.copy:
    src: "{{ gitlab_local_cert_src }}/{{ gitlab_key_file }}"   # certs/gitlab/gitlab.key (control)
    dest: "{{ gitlab_ssl_dir }}/{{ gitlab_ssl_key_dest }}"     # /etc/gitlab/ssl/gitlab.home.local.key
    owner: root
    group: root
    mode: "0600"                 # приватный ключ — только root
  notify: reconfigure gitlab     # меняем ключ → reconfigure
```

### 7. Install prerequisites for GitLab repo
```yaml
- name: Install prerequisites for GitLab repo
  ansible.builtin.apt:
    name:
      - ca-certificates         # доверие к HTTPS-репозиториям
      - curl                    # скачивание GPG-ключа
      - gnupg                   # dearmor ключа
      - openssh-server          # нужен для git over SSH в GitLab
    state: present
    update_cache: true          # обновить кэш apt перед установкой
  when: not gitlab_repo_present.stat.exists   # только если репозиторий ещё не подключён
```

### 8. Create GitLab keyrings directory
```yaml
- name: Create GitLab keyrings directory
  ansible.builtin.file:
    path: /etc/apt/keyrings     # стандартный каталог для GPG-ключей репозиториев
    state: directory
    owner: root
    group: root
    mode: "0755"
  when: not gitlab_repo_present.stat.exists   # дублируется с таском 7 — when то же самое
```

### 9. Download GitLab GPG key
```yaml
- name: Download GitLab GPG key
  ansible.builtin.get_url:
    url: "https://packages.gitlab.com/gpg.key"  # публичный ключ подписи репозитория
    dest: /tmp/gitlab-gpg.key                    # временный файл перед dearmor
    mode: "0644"
  when: not gitlab_repo_present.stat.exists
```

### 10. Dearmor GitLab GPG key into keyring
```yaml
- name: Dearmor GitLab GPG key into keyring
  ansible.builtin.command:
    cmd: "gpg --dearmor -o /etc/apt/keyrings/gitlab.gpg /tmp/gitlab-gpg.key"  # PEM→бинарь
    creates: /etc/apt/keyrings/gitlab.gpg   # если уже есть — не перезаписываем (идемпотентно)
  when: not gitlab_repo_present.stat.exists
```

### 11. Add GitLab apt repository
```yaml
- name: Add GitLab apt repository
  ansible.builtin.copy:
    dest: /etc/apt/sources.list.d/gitlab_{{ gitlab_edition }}.list  # файл репозитория
    owner: root
    group: root
    mode: "0644"
    content: >-
      deb [arch=amd64 signed-by=/etc/apt/keyrings/gitlab.gpg]
      https://packages.gitlab.com/gitlab/{{ gitlab_edition }}/ubuntu/ {{ gitlab_repo_codename }} main
      # signed-by указывает apt использовать наш keyring для проверки подписи
  when: not gitlab_repo_present.stat.exists
```

### 12. Update apt cache for GitLab repository
```yaml
- name: Update apt cache for GitLab repository
  ansible.builtin.apt:
    update_cache: true   # увидеть пакет gitlab-ce/ee из нового репозитория
  when: not gitlab_repo_present.stat.exists
```

### 13. Render gitlab.rb configuration
```yaml
- name: Render gitlab.rb configuration
  ansible.builtin.template:
    src: gitlab.rb.j2                  # шаблон с external_url, nginx ssl, monitoring
    dest: /etc/gitlab/gitlab.rb        # читается при reconfigure
    owner: root
    group: root
    mode: "0600"                       # может содержать initial_root_password
  no_log: true                         # не светить содержимое в логах
```
> Рендерим ДО установки пакета: postinst-скрипт Omnibus сам дёрнет `reconfigure`
> и подхватит наш `gitlab.rb` сразу.

### 14. Install GitLab omnibus package
```yaml
- name: Install GitLab omnibus package
  ansible.builtin.apt:
    name: "{{ gitlab_edition }}{% if gitlab_version | length > 0 %}={{ gitlab_version }}{% endif %}"
    state: present
  environment:
    EXTERNAL_URL: "{{ gitlab_external_url }}"   # Omnibus использует для первичной настройки
  register: gitlab_pkg_install
  failed_when:
    - gitlab_pkg_install.rc != 0
    - "'already the newest version' not in gitlab_pkg_install.stdout"  # игнорим «уже установлен»
  when: not gitlab_installed.stat.exists       # пропускаем, если gitlab-ctl уже есть
```

### 15. Run gitlab-ctl reconfigure (initial)
```yaml
- name: Run gitlab-ctl reconfigure (initial)
  ansible.builtin.command:
    cmd: gitlab-ctl reconfigure        # применяет gitlab.rb, настраивает сервисы/nginx
    creates: /var/opt/gitlab/bootstrapped   # если уже bootstrapped — не гоняем повторно
```

### 16. Enable and start GitLab service
```yaml
- name: Enable and start GitLab service
  ansible.builtin.systemd:
    name: "{{ gitlab_service }}"   # gitlab-runsvdir
    enabled: true                  # автозапуск при загрузке
    state: started                 # запустить, если не запущен
```

### 17. Set GitLab root password from vault (idempotent)
```yaml
- name: Set GitLab root password from vault (idempotent)
  ansible.builtin.command:
    cmd: >-
      gitlab-rails runner "user = User.find_by(username: 'root');
      user.password = '{{ gitlab_root_password }}';
      user.password_confirmation = '{{ gitlab_root_password }}';
      user.save!(validate: false)"   # задаём/обновляем пароль root напрямую в БД
  no_log: true                       # не светить пароль
  changed_when: false                # не помечаем как изменение (idempotent по сути)
```

### 18. Wait for GitLab HTTPS port
```yaml
- name: Wait for GitLab HTTPS port
  ansible.builtin.wait_for:
    port: "{{ gitlab_https_port }}"  # 443
    timeout: 600                     # GitLab долго стартует — ждём до 10 мин
  when: not gitlab_port_listening is succeeded   # пропускаем, если порт уже отвечал в таске 3
```

---

## Handlers

- **reconfigure gitlab** — `gitlab-ctl reconfigure`, применяет изменения `gitlab.rb`
  (вызывается при смене сертификата/ключа).

---

## Запуск

```bash
cd ansible-modular
ansible-playbook -i inventory playbooks/gitlab.yml --vault-password-file=.vault_pass
```

Только на одном хосте:

```bash
ansible-playbook -i inventory playbooks/gitlab.yml --limit gitlab --vault-password-file=.vault_pass
```

---

## TLS (self-signed)

Сертификат копируется в `/etc/gitlab/ssl/gitlab.home.local.crt` (имя `<fqdn>.crt` —
именно его ожидает Omnibus/nginx). Если назвать файл иначе, Omnibus сгенерирует свой
сертификат, и nginx будет отдавать его, а не наш — из-за этого раннер падал с
`x509: certificate signed by unknown authority`.

---

## Сертификат

Источник — `certs/gitlab/gitlab.crt` + `gitlab.key` на control-машине. Генерируется вручную
(см. `certs/gitlab/README.md`). В роли только раскладывается по месту с правильным именем.
