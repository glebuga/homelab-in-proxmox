# Playbooks

Точки входа, которые говорят Ansible, *какие роли запускать на каких хостах*.

## bootstrap.yml

Одноразовая начальная настройка новых хостов. Он:

- подключается под `root` (`bootstrap_user`),
- создаёт пользователя `admin`, копирует ваш SSH-ключ, выдаёт sudo без пароля,
- усиливает SSH (отключает вход по паролю и вход root, блокирует root).

Запускайте один раз для каждого нового хоста. Так как на целевом хосте пока
есть только `root` с паролем, укажите пароль root (в старом `hosts.ini`
использовался `--ask-pass`):

    # интерактивный ввод пароля:
    ansible-playbook playbooks/bootstrap.yml -e "ansible_user=root" --ask-pass

    # или неинтерактивно (например, в CI), ограничив одним хостом:
    ansible-playbook playbooks/bootstrap.yml --limit nginx \
        -e "ansible_user=root" -e "ansible_password=SECRET"

> Роль bootstrap **не устанавливает пакеты**, поэтому шаг `apt update`
> намеренно отсутствует — она выполняется быстро.

## site.yml

Главный playbook для повседневной настройки. Подключается под `admin`
(`ansible_user`) и пока применяет роль `common` (заготовка). По мере
реализации ролей добавляйте их в список `roles:`, например `dns`, `docker`,
`firewall`, `nginx`.

    ansible-playbook playbooks/site.yml

## Ограничение набора хостов

Используйте `--limit <группа|хост>`, чтобы ограничить выполнение, например
`--limit nginx` или `--limit docker_nodes`.
