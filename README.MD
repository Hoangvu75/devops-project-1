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

## How deploy works (Ansible)

`ansible/deploy.yml` does the following per host:
1) Update apt cache and install base tools (`rsync`, `python3-requests`)
2) Add Docker repo + install Docker CE (fallback to `docker.io` if needed)
3) Start Docker service; if no systemd, start `dockerd` manually and wait for `/var/run/docker.sock`
4) Sync the project to `project_dir` using rsync (excludes `.git`, `node_modules`, `.next`, `dist`)
5) Run `docker compose` for the services configured in group vars
6) Print running container names for quick verification

Notes
- The playbook is idempotent; re‑running updates the stack in place.
- In the lab, services inside a compose call each other by service name (e.g., `backend:4000`), not `localhost`.

---

## Troubleshooting

- Prometheus target DOWN, error contains `localhost:4000`
  - In a compose network, `localhost` refers to the Prometheus container itself. Ensure target is `backend:4000` (service name).
- Grafana shows "No data"
  - Generate traffic (CRUD on frontend or `curl http://localhost:14000/`) and wait 10–30s. Verify Prometheus `backend` target is UP.
- Docker daemon errors in ubuntu‑server containers
  - The playbook starts `dockerd` if systemd isn’t available; ensure the host was deployed via Ansible so dockerd is running.
- apt lock errors (when deploying to multiple hosts)
  - Use a single host or set `serial: 1` in the play to run hosts sequentially.

---

## Repository layout (key files)

```
backend/                # NestJS API (exposes /metrics)
frontend/               # Next.js UI
prometheus.yml          # Prometheus scrape config
ubuntu-server/          # Lab: control-node + ubuntu-server-1..3
  control-node/
  ubuntu-server/
ansible/
  hosts.ini             # Inventory
  group_vars/app.yml    # Services per group
  deploy.yml            # Playbook: install Docker, sync, compose up
```

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
