# Tạo Docker network cho các containers
resource "docker_network" "ansible_net" {
  name = "ansible-net"
}

# Tạo Docker volumes cho các ubuntu-server
resource "docker_volume" "docker_data_1" {
  name = "docker-data-1"
}

resource "docker_volume" "docker_data_2" {
  name = "docker-data-2"
}

resource "docker_volume" "docker_data_3" {
  name = "docker-data-3"
}

# Build Docker image cho control-node
resource "docker_image" "control_node" {
  name = "ubuntu-server-control-node:terraform"
  build {
    context = "${var.repo_dir}/ubuntu-server/control-node"
    tag     = ["ubuntu-server-control-node:terraform"]
  }
  keep_locally = true
}

# Build Docker image cho ubuntu-server
resource "docker_image" "ubuntu_server" {
  name = "ubuntu-server-base:terraform"
  build {
    context = "${var.repo_dir}/ubuntu-server/ubuntu-server"
    tag     = ["ubuntu-server-base:terraform"]
  }
  keep_locally = true
}

# Container control-node
resource "docker_container" "control_node" {
  name  = "control-node"
  image = docker_image.control_node.image_id
  tty   = true

  networks_advanced {
    name = docker_network.ansible_net.name
  }

  # Mount toàn bộ repo vào /workspace
  mounts {
    type   = "bind"
    target = "/workspace"
    source = var.repo_dir
  }

  # Đảm bảo container khởi động và duy trì
  restart = "unless-stopped"
}

# Container ubuntu-server-1 (chính - chạy tất cả services)
resource "docker_container" "ubuntu_server_1" {
  name       = "ubuntu-server-1"
  image      = docker_image.ubuntu_server.image_id
  tty        = true
  privileged = true

  networks_advanced {
    name = docker_network.ansible_net.name
  }

  # Mount cgroup và docker volume
  mounts {
    type   = "bind"
    source = "/sys/fs/cgroup"
    target = "/sys/fs/cgroup"
  }

  mounts {
    type   = "volume"
    source = docker_volume.docker_data_1.name
    target = "/var/lib/docker"
  }

  # Publish ports cho SSH và các services
  ports {
    internal = 22
    external = 2221
  }
  ports {
    internal = 3000  # Frontend
    external = 13000
  }
  ports {
    internal = 4000  # Backend
    external = 14000
  }
  ports {
    internal = 9090  # Prometheus
    external = 19090
  }
  ports {
    internal = 3001  # Grafana
    external = 13001
  }

  restart = "unless-stopped"
}

# Container ubuntu-server-2
resource "docker_container" "ubuntu_server_2" {
  name       = "ubuntu-server-2"
  image      = docker_image.ubuntu_server.image_id
  tty        = true
  privileged = true

  networks_advanced {
    name = docker_network.ansible_net.name
  }

  mounts {
    type   = "bind"
    source = "/sys/fs/cgroup"
    target = "/sys/fs/cgroup"
  }

  mounts {
    type   = "volume"
    source = docker_volume.docker_data_2.name
    target = "/var/lib/docker"
  }

  ports {
    internal = 22
    external = 2222
  }

  restart = "unless-stopped"
}

# Container ubuntu-server-3
resource "docker_container" "ubuntu_server_3" {
  name       = "ubuntu-server-3"
  image      = docker_image.ubuntu_server.image_id
  tty        = true
  privileged = true

  networks_advanced {
    name = docker_network.ansible_net.name
  }

  mounts {
    type   = "bind"
    source = "/sys/fs/cgroup"
    target = "/sys/fs/cgroup"
  }

  mounts {
    type   = "volume"
    source = docker_volume.docker_data_3.name
    target = "/var/lib/docker"
  }

  ports {
    internal = 22
    external = 2223
  }

  restart = "unless-stopped"
}

# Chờ containers khởi động và chạy Ansible
resource "null_resource" "run_ansible" {
  depends_on = [
    docker_container.control_node,
    docker_container.ubuntu_server_1,
    docker_container.ubuntu_server_2,
    docker_container.ubuntu_server_3
  ]

  # Chờ containers khởi động hoàn toàn
  provisioner "local-exec" {
    command = "sleep ${var.wait_for_containers_seconds}"
  }

  # Chạy Ansible playbook bên trong control-node
  provisioner "local-exec" {
    command = <<-EOT
      docker exec control-node bash -c "
        cd /workspace/ansible && 
        ansible-galaxy collection install -r requirements.yml --force &&
        ansible-playbook -i hosts.ini deploy.yml -v
      "
    EOT
  }

  # Trigger để chạy lại khi có thay đổi trong ansible files
  triggers = {
    ansible_playbook_hash = filemd5("${var.repo_dir}/ansible/deploy.yml")
    ansible_hosts_hash    = filemd5("${var.repo_dir}/ansible/hosts.ini")
    ansible_config_hash   = filemd5("${var.repo_dir}/ansible/ansible.cfg")
  }
}
