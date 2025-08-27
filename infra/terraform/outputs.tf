output "container_info" {
  description = "Thông tin về các containers đã tạo"
  value = {
    control_node = {
      name = docker_container.control_node.name
      id   = docker_container.control_node.id
    }
    ubuntu_server_1 = {
      name  = docker_container.ubuntu_server_1.name
      id    = docker_container.ubuntu_server_1.id
      ports = {
        ssh       = "localhost:2221"
        frontend  = "localhost:13000"
        backend   = "localhost:14000"
        prometheus = "localhost:19090"
        grafana   = "localhost:13001"
      }
    }
    ubuntu_server_2 = {
      name = docker_container.ubuntu_server_2.name
      id   = docker_container.ubuntu_server_2.id
      ports = {
        ssh = "localhost:2222"
      }
    }
    ubuntu_server_3 = {
      name = docker_container.ubuntu_server_3.name
      id   = docker_container.ubuntu_server_3.id
      ports = {
        ssh = "localhost:2223"
      }
    }
  }
}

output "network_name" {
  description = "Tên Docker network được tạo"
  value       = docker_network.ansible_net.name
}

output "access_instructions" {
  description = "Hướng dẫn truy cập các services"
  value = {
    control_node_shell = "docker exec -it control-node bash"
    frontend_url       = "http://localhost:13000"
    backend_url        = "http://localhost:14000"
    prometheus_url     = "http://localhost:19090"
    grafana_url        = "http://localhost:13001"
    ssh_commands = {
      ubuntu_server_1 = "ssh -p 2221 root@localhost (password: 1234)"
      ubuntu_server_2 = "ssh -p 2222 root@localhost (password: 1234)"
      ubuntu_server_3 = "ssh -p 2223 root@localhost (password: 1234)"
    }
  }
}
