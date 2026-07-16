# Inventory

В этой директории находится **динамический inventory**.
Статического `hosts.ini` нет — вместо этого `terraform_inventory.py`
генерирует inventory автоматически из вывода Terraform.

## Как это работает

`terraform_inventory.py` выполняет:

    terraform -chdir=../terraform-modular output -json

и сопоставляет полученные IP-адреса группам Ansible. Ansible узнаёт, что
использовать этот скрипт как inventory, из `ansible.cfg`:

    inventory = ./inventory/terraform_inventory.py

Поэтому каждая команда `ansible-playbook` / `ansible-inventory` **сама
запускает скрипт** — вручную его запускать не нужно.

## Как посмотреть сгенерированные хосты

Выполните любую из команд (результат одинаковый — первая запускает скрипт
напрямую, вторая — Ansible вызывает его):

    python3 inventory/terraform_inventory.py --list
    ansible-inventory --list

При каждом запуске с `--list` скрипт дополнительно пишет человекочитаемый
отчёт в `hosts_report.txt` в этой же папке: список хостов, их IP, группы,
пользователи подключения и DNS, через который резолвится каждый хост. Файл
перезаписывается при каждом вызове, поэтому его удобно добавить в `.gitignore`
как генерируемый артефакт.

### Пример вывода (текущее состояние)

```json
{
    "all": {
        "vars": {
            "timezone": "Europe/Moscow",
            "locale": "en_US.UTF-8",
            "proxmox": "192.168.0.200",
            "management_ip": "10.0.0.2"
        }
    },
    "nginx_nodes": ["nginx"],
    "docker_nodes": ["docker"],
    "net_service": ["dns"],
    "gitlab_node": ["gitlab"],
    "kuber": [],
    "ubuntu_vms": [],
    "local": ["hq"],
    "_meta": {
        "hostvars": {
            "nginx":  { "ansible_host": "10.0.0.103", "bootstrap_user": "root", "ansible_user": "admin" },
            "docker": { "ansible_host": "10.0.0.102", "bootstrap_user": "root", "ansible_user": "admin" },
            "dns":    { "ansible_host": "10.0.0.104", "bootstrap_user": "root", "ansible_user": "admin" },
            "gitlab": { "ansible_host": "10.0.0.105", "bootstrap_user": "root", "ansible_user": "admin" },
            "hq":     { "ansible_connection": "local", "ansible_host": "127.0.0.1" }
        }
    }
}
```

## Как читать этот вывод

- **Ключи верхнего уровня** (`nginx_nodes`, `docker_nodes`, ...) — это
  **группы**; каждая содержит список *имён* хостов в ней.
- **`all.vars`** — переменные, применяемые ко всем хостам.
- **`_meta.hostvars`** — данные подключения для каждого хоста:
  - `ansible_host` — IP-адрес (взят из Terraform)
  - `bootstrap_user: root` — используется только bootstrap playbook'ом
  - `ansible_user: admin` — используется всеми остальными playbook'ами

## Примечания

- `kuber` и `ubuntu_vms` заполняются **автоматически** из вывода Terraform,
  как только соответствующие ВМ созданы. Редактировать скрипт вручную для
  добавления очередной VM **не нужно** — достаточно дописать её в список
  `k3s_vms` / `ubuntu_vms` в `terraform.tfvars` и выполнить `apply`.
- Если Terraform ещё не применён, скрипт выведет предупреждение и вернёт
  пустые группы. Сначала выполните `terraform apply` в `terraform-modular/`.

## Добавление новой машины (LXC / VM)

IP-адреса **нигде не захардкожены** в Ansible — единственный источник правды
это `terraform-modular/terraform.tfvars`. Поток данных:

```
terraform.tfvars (ip_address)
   -> terraform apply
   -> outputs.tf (nginx_ip / k3s_vm_ips / ...)
   -> terraform output -json
   -> terraform_inventory.py (ansible_host = IP)
   -> группы Ansible
```

Поэтому, чтобы новая машина появилась в инвентаре, она сначала должна
появиться в выводе Terraform.

### Новая VM (k3s / ubuntu) — минимум действий

VM описаны **списками** (`k3s_vms`, `ubuntu_vms`), поэтому скрипт инвентаря
подхватывает любое их количество сам. Править скрипт не нужно.

1. В `terraform-modular/terraform.tfvars` добавь объект в нужный список,
   например в `k3s_vms`:
   ```hcl
   {
     vm_id      = 207
     hostname   = "k3s-worker-2"
     ip_address = "10.0.0.207/24"
     cpu_cores  = 2
     memory     = 3072
     disk_size  = 30
   }
   ```
2. `terraform -chdir=terraform-modular apply`
3. Готово — инвентарь покажет `k3s-207` в группе `kuber` без правок скрипта.

> Важно: модуль `k3s_vms` в `main.tf` не передаёт `started`, поэтому по
> умолчанию виртуалка после `apply` может оказаться остановленной. Запусти её
> в Proxmox вручную перед Ansible, если она нужна для настройки.

### Новый LXC-контейнер (нового типа) — больше шагов

LXC описаны **отдельными объектами**, поэтому добавление нового типа требует
правок в 4 файлах Terraform + 1 в скрипте инвентаря.

1. `terraform-modular/variables.tf` — добавь переменную (скопируй форму
   `docker_container`).
2. `terraform-modular/main.tf` — добавь вызов модуля, например:
   ```hcl
   module "monitoring" {
     source = "./modules/lxc"
     # ... те же параметры, что у других контейнеров,
     # включая dns_server = var.dns_server
   }
   ```
3. `terraform-modular/outputs.tf` — добавь вывод IP:
   ```hcl
   output "monitoring_ip" {
     value = module.monitoring.ipv4
   }
   ```
4. `terraform-modular/terraform.tfvars` — добавь блок, например:
   ```hcl
   monitoring_container = {
     vm_id      = 106
     hostname   = "monitoring"
     ip_address = "10.0.0.106/24"
     cpu_cores  = 1
     memory     = 1024
     swap       = 512
     start      = true
     onboot     = true
     privileged = false
   }
   ```
5. `terraform -chdir=terraform-modular apply`
6. `ansible-modular/inventory/terraform_inventory.py` — добавь группу в словарь
   `groups` и одну строку:
   ```python
   add("monitoring", _first_ip(out.get("monitoring_ip")), "monitoring_group")
   ```
   (или добавь `("monitoring_ip", "monitoring_group", "monitoring")` в список
   `LXC_HOSTS`, если скрипт переведён в data-driven вид).

### Чек-лист «чтобы всё заработало» после добавления машины

1. `terraform -chdir=terraform-modular apply` — ресурс создан, output обновлён.
2. `ansible-inventory --list` (из `ansible-modular/`) — убедись, что новый хост
   появился в нужной группе и у него есть `ansible_host`.
3. `ansible-playbook playbooks/bootstrap.yml -e "ansible_user=root" --ask-pass --limit <группа>`
   — для LXC. Для Ubuntu-VM используй `ansible_user=ubuntu --ask-become-pass`.
   Это создаёт пользователя `admin` и прописывает SSH-ключ.
4. `ansible-playbook playbooks/site.yml` — применяет роли (dns → common) на все
   хосты, теперь уже под пользователем `admin` по SSH-ключу.
5. `ansible-playbook playbooks/inspect.yml` — проверь IP / FQDN / DNS.
