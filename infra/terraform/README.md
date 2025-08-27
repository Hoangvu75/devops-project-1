# Terraform Infrastructure cho DevOps Project

## Mô tả

Terraform configuration này tự động hóa việc:
1. **Bước 2**: Tạo 4 Docker containers (control-node + 3 ubuntu-server)
2. **Bước 3**: Chạy Ansible để deploy Frontend, Backend, Prometheus, Grafana

## Yêu cầu

- **Terraform** >= 1.5.0
- **Docker Desktop** (macOS/Windows) hoặc Docker Engine (Linux)
- **Docker Compose** (thường đi kèm Docker Desktop)

## Cài đặt

### 1. Cài Terraform

**macOS (Homebrew):**
```bash
brew install terraform
```

**Windows (Chocolatey):**
```bash
choco install terraform
```

**Linux:**
```bash
# Ubuntu/Debian
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
```

### 2. Khởi tạo và chạy

```bash
# Di chuyển vào thư mục terraform
cd infra/terraform

# Khởi tạo Terraform (tải providers)
terraform init

# Xem kế hoạch thực thi (tuỳ chọn)
terraform plan

# Áp dụng cấu hình (tạo infrastructure + chạy Ansible)
terraform apply
```

Terraform sẽ hỏi xác nhận trước khi tạo resources. Gõ `yes` để tiếp tục.

## Cấu hình

### Variables

Bạn có thể tùy chỉnh các biến trong `variables.tf` hoặc truyền qua command line:

```bash
# Thay đổi đường dẫn repo (nếu khác mặc định)
terraform apply -var="repo_dir=/path/to/your/devops-project-1"

# Thay đổi thời gian chờ containers khởi động
terraform apply -var="wait_for_containers_seconds=45"
```

### Hoặc tạo file `terraform.tfvars`:

```hcl
repo_dir = "/Users/yourusername/Workspace/devops-project-1"
wait_for_containers_seconds = 45
```

## Sau khi chạy thành công

### Truy cập services

- **Frontend**: http://localhost:13000
- **Backend API**: http://localhost:14000
- **Prometheus**: http://localhost:19090
- **Grafana**: http://localhost:13001

### Truy cập containers

```bash
# Vào control-node để chạy Ansible thủ công
docker exec -it control-node bash

# SSH vào các ubuntu-server (password: 1234)
ssh -p 2221 root@localhost  # ubuntu-server-1
ssh -p 2222 root@localhost  # ubuntu-server-2
ssh -p 2223 root@localhost  # ubuntu-server-3
```

### Kiểm tra containers

```bash
# Xem danh sách containers
docker ps

# Xem logs của container
docker logs control-node
docker logs ubuntu-server-1
```

## Quản lý

### Cập nhật infrastructure

```bash
# Sau khi thay đổi code hoặc cấu hình
terraform apply
```

### Chạy lại Ansible (không rebuild containers)

```bash
docker exec control-node bash -c "cd /workspace/ansible && ansible-playbook -i hosts.ini deploy.yml -v"
```

### Xóa toàn bộ infrastructure

```bash
terraform destroy
```

## Cấu trúc files

```
infra/terraform/
├── versions.tf    # Terraform version và providers
├── providers.tf   # Cấu hình Docker provider
├── variables.tf   # Biến đầu vào
├── main.tf        # Resources chính (containers, network, volumes)
├── outputs.tf     # Thông tin đầu ra
└── README.md      # Hướng dẫn này
```

## Troubleshooting

### Lỗi Docker socket

```bash
# Đảm bảo Docker Desktop đang chạy
# macOS/Windows: Mở Docker Desktop app
# Linux: sudo systemctl start docker
```

### Containers không khởi động

```bash
# Kiểm tra logs
docker logs control-node
docker logs ubuntu-server-1

# Restart thủ công
docker restart control-node ubuntu-server-1 ubuntu-server-2 ubuntu-server-3
```

### Ansible playbook thất bại

```bash
# Chạy lại Ansible thủ công với verbose
docker exec control-node bash -c "cd /workspace/ansible && ansible-playbook -i hosts.ini deploy.yml -vvv"
```

### Port conflicts

Nếu ports 13000, 14000, 19090, 13001 đã được sử dụng, bạn có thể:
1. Dừng services đang dùng ports đó
2. Hoặc sửa ports trong `main.tf` (phần `docker_container.ubuntu_server_1.ports`)

## Lưu ý

- Containers được mount với `restart = "unless-stopped"` để tự động khởi động lại khi Docker restart
- Toàn bộ repo được mount vào `/workspace` trong control-node (read-write)
- Ansible sẽ tự động sync code sang các ubuntu-server và chạy `docker compose up`
- Nếu thay đổi Ansible files, Terraform sẽ tự động chạy lại playbook khi `terraform apply`
