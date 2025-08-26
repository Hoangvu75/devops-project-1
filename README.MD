### TodoList DevOps Project

A learning-oriented, production-like TodoList application showcasing a modern DevOps toolchain.

- **Frontend**: Next.js (React)
- **Backend**: NestJS (Node.js)
- **CI/CD**: Jenkins
- **Orchestration**: Kubernetes
- **Ingress / Web**: NGINX (Ingress Controller)
- **Code Quality**: SonarQube
- **Provisioning**: Ansible
- **Observability (Logs)**: Loki + Grafana (with Promtail)

---

### Goals
- **Build** and containerize a Next.js frontend and NestJS backend
- **Automate** CI/CD with Jenkins Pipelines (PR checks → build → test → security scan → deploy)
- **Deploy** to Kubernetes with zero-downtime strategies (RollingUpdate)
- **Expose** services via NGINX Ingress
- **Enforce** quality gates with SonarQube
- **Centralize logs** with Loki and visualize in Grafana
- **Automate infra** bootstrap with Ansible

---

### High-Level Architecture
- `nextjs-frontend` → served via Node server or static export behind **NGINX Ingress**
- `nestjs-backend` → API service exposed internally via ClusterIP, publicly via **Ingress** paths
- **Jenkins** → builds, tests, scans, and deploys using Kubernetes credentials
- **Loki + Promtail + Grafana** → cluster logs aggregated and visualized
- **SonarQube** → quality scanning (TypeScript rules for Next/Nest)

```
[Developers] → Git push → Jenkins (CI/CD) → Docker Registry → Kubernetes
                                            ↘ SonarQube (Quality Gate)
Kubernetes → NGINX Ingress → Frontend (Next.js) ⇄ Backend (NestJS)
Kubernetes logs → Promtail → Loki → Grafana Dashboards
```

---

### Repository Structure (suggested)
```
.
├─ frontend/              # Next.js app
├─ backend/               # NestJS app
├─ cicd/
│  ├─ Jenkinsfile         # Declarative pipeline
│  └─ sonar-project.properties
├─ deploy/
│  ├─ k8s/
│  │  ├─ namespace.yaml
│  │  ├─ ingress.yaml
│  │  ├─ frontend/
│  │  │  ├─ deployment.yaml
│  │  │  └─ service.yaml
│  │  └─ backend/
│  │     ├─ deployment.yaml
│  │     └─ service.yaml
│  └─ monitoring/
│     ├─ loki/
│     ├─ promtail/
│     └─ grafana/
├─ ansible/
│  ├─ inventories/
│  ├─ roles/
│  │  ├─ jenkins/
│  │  ├─ k8s/
│  │  ├─ nginx_ingress/
│  │  └─ loki_stack/
│  └─ playbooks/
│     ├─ bootstrap-ci.yml
│     ├─ bootstrap-k8s.yml
│     └─ bootstrap-observability.yml
└─ README.MD
```

---

### Local Development
- Requirements:
  - Node.js 18+
  - Docker + Docker Compose

- Frontend (Next.js):
```bash
cd frontend
npm install
npm run dev
```
- Backend (NestJS):
```bash
cd backend
npm install
npm run start:dev
```

- Docker Compose (optional local stack):
```bash
docker compose up -d --build
```

---

### Containerization
- Example Dockerfiles:

Frontend `frontend/Dockerfile` (multi-stage):
```dockerfile
# Stage 1: deps
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Stage 2: build
FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: runner
FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY package*.json ./
RUN npm ci --omit=dev
EXPOSE 3000
CMD ["npm", "start"]
```

Backend `backend/Dockerfile`:
```dockerfile
FROM node:18-alpine as deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:18-alpine as builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:18-alpine as runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm ci --omit=dev
EXPOSE 4000
CMD ["node", "dist/main.js"]
```

---

### Kubernetes Manifests (examples)
Namespace `deploy/k8s/namespace.yaml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: todolist
```

Backend `deploy/k8s/backend/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: todolist
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: YOUR_REGISTRY/todolist-backend:latest
          ports:
            - containerPort: 4000
          env:
            - name: NODE_ENV
              value: production
          readinessProbe:
            httpGet:
              path: /health
              port: 4000
          livenessProbe:
            httpGet:
              path: /health
              port: 4000
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: todolist
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
    - port: 4000
      targetPort: 4000
```

Frontend `deploy/k8s/frontend/deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: todolist
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: YOUR_REGISTRY/todolist-frontend:latest
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: production
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: todolist
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
    - port: 3000
      targetPort: 3000
```

Ingress `deploy/k8s/ingress.yaml` (NGINX Ingress Controller required):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todolist-ingress
  namespace: todolist
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
    - host: todolist.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 3000
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 4000
```

---

### Jenkins CI/CD
- Declarative pipeline `cicd/Jenkinsfile` (example stages):
```groovy
pipeline {
  agent any
  environment {
    REGISTRY = 'YOUR_REGISTRY'
    IMAGE_FRONTEND = "${REGISTRY}/todolist-frontend"
    IMAGE_BACKEND  = "${REGISTRY}/todolist-backend"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Node Setup') {
      steps {
        sh 'node -v || true'
        sh 'npm -v || true'
      }
    }
    stage('Install & Test') {
      parallel {
        stage('Frontend') {
          steps { sh 'cd frontend && npm ci && npm test -- --ci' }
        }
        stage('Backend') {
          steps { sh 'cd backend && npm ci && npm run test:ci' }
        }
      }
    }
    stage('SonarQube Scan') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh 'sonar-scanner -Dproject.settings=cicd/sonar-project.properties'
        }
      }
    }
    stage('Build Images') {
      parallel {
        stage('Frontend Image') {
          steps { sh 'docker build -t ${IMAGE_FRONTEND}:${BUILD_NUMBER} frontend' }
        }
        stage('Backend Image') {
          steps { sh 'docker build -t ${IMAGE_BACKEND}:${BUILD_NUMBER} backend' }
        }
      }
    }
    stage('Push Images') {
      steps {
        sh 'docker push ${IMAGE_FRONTEND}:${BUILD_NUMBER}'
        sh 'docker push ${IMAGE_BACKEND}:${BUILD_NUMBER}'
      }
    }
    stage('Deploy to K8s') {
      steps {
        sh 'kubectl apply -f deploy/k8s/namespace.yaml'
        sh 'kubectl -n todolist set image deployment/frontend frontend=${IMAGE_FRONTEND}:${BUILD_NUMBER} --record || kubectl -n todolist apply -f deploy/k8s/frontend'
        sh 'kubectl -n todolist set image deployment/backend backend=${IMAGE_BACKEND}:${BUILD_NUMBER} --record || kubectl -n todolist apply -f deploy/k8s/backend'
        sh 'kubectl apply -f deploy/k8s/ingress.yaml'
      }
    }
  }
  post {
    always { archiveArtifacts artifacts: '**/junit*.xml', allowEmptyArchive: true }
  }
}
```

SonarQube config `cicd/sonar-project.properties` (example):
```properties
sonar.projectKey=todolist
sonar.sources=frontend,backend
sonar.language=ts
sonar.sourceEncoding=UTF-8
sonar.tests=frontend,backend
sonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info,backend/coverage/lcov.info
```

---

### Observability (Loki + Grafana)
- Install via Helm (recommended):
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
# Loki
helm upgrade --install loki grafana/loki -n monitoring --create-namespace
# Promtail (log collector)
helm upgrade --install promtail grafana/promtail -n monitoring \
  --set "config.clients[0].url=http://loki.monitoring:3100/loki/api/v1/push"
# Grafana
helm upgrade --install grafana grafana/grafana -n monitoring \
  --set adminPassword=admin
```
- Access Grafana and add Loki as a data source. Build dashboards for `nginx`, `frontend`, and `backend` pods.

---

### Ansible (Bootstrap Examples)
- CI server (Jenkins) provisioning `ansible/playbooks/bootstrap-ci.yml`:
```yaml
- hosts: jenkins
  become: true
  roles:
    - jenkins
```
- Kubernetes cluster add-ons `ansible/playbooks/bootstrap-k8s.yml`:
```yaml
- hosts: k8s_masters
  become: true
  roles:
    - nginx_ingress
```
- Observability stack `ansible/playbooks/bootstrap-observability.yml`:
```yaml
- hosts: k8s_masters
  become: true
  roles:
    - loki_stack
```

---

### NGINX Ingress Notes
- Use `NGINX Ingress Controller` via Helm:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
```
- Map DNS (e.g., `/etc/hosts`) for `todolist.local` to your ingress controller address.

---

### Security & Quality
- Enable SonarQube **quality gates** to fail the pipeline on low coverage or code smells.
- Add basic dependency scans (e.g., `npm audit --production`) in CI.
- Use Kubernetes Secrets for sensitive env vars and avoid committing them.

---

### Next Steps
- Fill in `YOUR_REGISTRY` and push images to Docker Hub/Harbor/GHCR
- Add health endpoints in NestJS (`/health`) and Next.js (`/api/health` if needed)
- Parameterize manifests with Helm/Kustomize for environments
- Add TLS to Ingress with cert-manager

---

### License
This project is for educational purposes.
