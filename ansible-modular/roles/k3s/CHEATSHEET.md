# k3s — шпаргалка по таскам

Kubernetes-кластер (master + worker). Playbook `playbooks/k3s.yml`. Роль сама
определяет роль хоста (`k3s_is_master`).

## Определение роли
| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Determine node role | `set_fact k3s_is_master` | ветвит логику мастер/воркер |

## Мастер (`k3s_is_master == true`)
| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Check if k3s binary present (master) | `stat /usr/local/bin/k3s` | не качать заново (важно при таймаутах сети) |
| Download k3s binary (master) | `get_url` с GitHub | скачать, если нет и не `k3s_skip_download` |
| Install k3s server via official installer | `sh -s - server --disable traefik servicelb` | control plane, отключены лишние ingress/LB |
| Enable and start k3s service | `systemd` k3s + `daemon_reload` | запуск сервера как сервиса |
| Wait for k3s server to be ready | ждёт файл `node-token` | сервер поднялся, готов выдавать токен |

## Воркер (`k3s_is_master == false`)
| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Read node token from master | `slurp` token с мастера (`delegate_to`) | **токен не хардкодится**, берётся в рантайме |
| Set node token fact | `set_fact k3s_node_token` | сохраняет токен для след. таски |
| Check if k3s binary present (worker) | `stat` бинаря | идемпотентность скачивания |
| Download k3s binary (worker) | `get_url` | скачать, если нет |
| Install k3s agent and join master | `sh -s -` с `K3S_URL`+`K3S_TOKEN` | агент регистрируется в кластере |
| Enable and start k3s-agent service | `systemd` k3s-agent | запуск агента как сервиса |

## Верификация (только мастер)
| Таска | Что делает | Зачем нужна |
|-------|-----------|-------------|
| Show cluster nodes | `kubectl get nodes -o wide` | убедиться, что ноды `Ready` |
| Show system pods | `kubectl get pods -A -o wide` | убедиться, что системные поды запущены |

> Воркер скипает верификацию (`when: k3s_is_master`) — это нормально.

**Итог:** рабочий k3s-кластер, traefik/servicelb отключены, токен не в коде.
