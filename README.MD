# DevOps Project 1

A small full‑stack demo with:
- Backend: NestJS (HTTP API, SQLite via TypeORM, Prometheus metrics on `/metrics`)
- Frontend: Next.js (Todo UI)
- Monitoring: Prometheus + Grafana
- Orchestration: Docker Compose
- Provisioning/Deploy: Ansible (run from a control node into simulated Ubuntu servers)

---

## Architecture

There are two main ways to run the stack:

1) Local Compose (single host)
- Top‑level `docker-compose.yml` builds and runs `backend`, `frontend`, `prometheus`, `grafana` together.
- Prometheus scrapes the backend at `/metrics`.

2) Lab with "Ubuntu servers" (Docker‑in‑Docker)
- Folder `ubuntu-server/` provides:
  - `control-node`: a container with Ansible + collection preinstalled and the project mounted at `/workspace`.
  - `ubuntu-server-1..3`: simulated Ubuntu servers (privileged) able to run Docker daemon inside each container.
- Ansible playbook (`ansible/deploy.yml`) installs Docker on target(s), syncs the repo to `/opt/devops-project-1`, and runs `docker compose` only for the services defined for that host/group.

Monitoring
- Backend exposes metrics at `GET /metrics` via `prom-client` and a Nest interceptor.
- Prometheus scrapes the backend job and Grafana renders dashboards provisioned in `grafana/provisioning/`.

---

## Quick start (local)

```bash
# From project root
docker compose up -d --build
```

URLs (local):
- Frontend: http://localhost:3000
- Backend:  http://localhost:4000
- Prometheus: http://localhost:9090
- Grafana:   http://localhost:3001

Open Prometheus Targets: http://localhost:9090/targets → `backend` must be UP.
Generate a few requests (CRUD in the frontend or `curl` the backend) then open Grafana to view dashboards.

---

## Lab mode with simulated servers

Start the lab:
```bash
cd ubuntu-server
docker compose up -d --build
```
This creates:
- `control-node` (Ansible controller; repo mounted at `/workspace`)
- `ubuntu-server-1..3` (Docker daemon inside each; ports mapped to host)

Enter control node:
```bash
docker exec -it control-node bash
cd /workspace/ansible
```

Inventory (`ansible/hosts.ini`) — deploy all services to `ubuntu-server-1`:
```ini
[app]
app1 ansible_host=ubuntu-server-1 ansible_user=root ansible_password=1234 ansible_python_interpreter=/usr/bin/python3
```

Group services (`ansible/group_vars/app.yml`):
```yaml
compose_services:
  - backend
  - frontend
  - prometheus
  - grafana
project_dir: /opt/devops-project-1
```

Deploy:
```bash
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i hosts.ini deploy.yml --become --limit app1
```

Published URLs (from host):
- Frontend:   http://localhost:13000
- Backend:    http://localhost:14000
- Prometheus: http://localhost:19090
- Grafana:    http://localhost:13001

Regenerate traffic in the frontend, then check Prometheus Targets (should be UP) and Grafana dashboards.

---

## Updating & redeploying

After code changes:
```bash
# lab mode
ansible-playbook -i ansible/hosts.ini ansible/deploy.yml --become --limit app1

# local
docker compose up -d --build
```

Enjoy hacking!
