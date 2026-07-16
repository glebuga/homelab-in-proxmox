# bootstrap — шпаргалка по таскам

Первичная настройка хоста. Запускается **один раз** как root (playbook
`playbooks/bootstrap.yml`, hosts: `all:!hq`), до появления admin-пользователя.

| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Set hostname | имя хоста = inventory_hostname | хост называется понятно (k3s-205 и т.п.) |
| Configure timezone | TZ (Europe/Moscow) | единое время в логах |
| Create admin user | user `admin` + group sudo/wheel | рабочий пользователь вместо root |
| Create ~/.ssh directory | `/home/admin/.ssh` 0700 | папка для SSH-ключей |
| Add public SSH keys | ключи в authorized_keys | вход по ключу, без паролей |
| Allow passwordless sudo | `/etc/sudoers.d/admin` NOPASSWD | ansible может `become: true` без пароля |
| Disable password authentication | `PasswordAuthentication no` | вход только по ключу (безопасность) |
| Disable root login | `PermitRootLogin no` | root не заходит по SSH |
| Lock root password | `password_lock: true` | блокирует пароль root локально |
| Remove root authorized_keys | удаляет `/root/.ssh/authorized_keys` | у root нет ключей |

**Итог:** хост готов к управлению по SSH-ключу от `admin` с sudo, root закрыт.
