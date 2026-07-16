# ansible-modular

Чистая, модульная конфигурация Ansible для домашней лаборатории (homelab),
переделанная по образу и подобию `terraform-modular/`.

## Структура

```
ansible-modular/
├── ansible.cfg
├── inventory/
│   └── terraform_inventory.py   # динамический inventory из вывода terraform
├── playbooks/
│   ├── bootstrap.yml            # одноразовая начальная настройка + подключение
│   └── site.yml                 # главный playbook (расширяется позже)
└── roles/
    ├── bootstrap/               # начальная настройка хоста (перенесена)
    ├── common/                  # (заготовка)
    ├── dns/                     # (заготовка)
    ├── docker/                  # (заготовка)
    ├── firewall/                # (заготовка)
    ├── nginx/                   # (заготовка)
    ├── etcd/                    # (заготовка)
    └── patroni/                 # (заготовка)
```

## Документация

У каждой части проекта свой README:

- [`inventory/README.md`](inventory/README.md) — динамический inventory на базе Terraform и его вывод.
- [`playbooks/README.md`](playbooks/README.md) — playbook'и bootstrap и site, как их запускать.
- [`roles/README.md`](roles/README.md) — структура ролей и статус каждой роли.
- [`roles/bootstrap/README.md`](roles/bootstrap/README.md) — единственная полностью реализованная роль.

## Inventory

`inventory/terraform_inventory.py` читает `terraform -chdir=../terraform-modular output -json`
и сопоставляет полученные IP-адреса группам Ansible:

| Вывод Terraform | Группа Ansible   |
|------------------|-------------------|
| nginx_ip         | nginx_nodes       |
| docker_ip        | docker_nodes      |
| dns_ip           | net_service       |
| gitlab_ip        | gitlab_node       |
| k3s_vm_ips       | kuber             |
| ubuntu_vm_ips    | ubuntu_vms        |
| (localhost)      | hq (connection=local) |

Каждый управляемый хост получает `ansible_host`, `bootstrap_user=root`
(используется только bootstrap playbook'ом) и `ansible_user=admin`.

## Использование

```bash
# 1. Одноразовый bootstrap (подключение под root)
ansible-playbook playbooks/bootstrap.yml -e "ansible_user=root" --ask-pass

# 2. Обычные запуски под пользователем admin
ansible-playbook playbooks/site.yml
```

> Требуется `terraform` в PATH и применённый `terraform-modular/`, чтобы
> `terraform output` возвращал IP-адреса хостов.
