#!/bin/bash

# Script tiện ích để chạy Terraform cho DevOps Project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  DevOps Project - Terraform Runner${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_requirements() {
    echo "🔍 Kiểm tra yêu cầu hệ thống..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform không được cài đặt"
        echo "Cài đặt: https://developer.hashicorp.com/terraform/downloads"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker không được cài đặt"
        echo "Cài đặt: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon không chạy"
        echo "Khởi động Docker Desktop hoặc Docker service"
        exit 1
    fi
    
    print_success "Tất cả yêu cầu đã được đáp ứng"
}

init_terraform() {
    echo "🚀 Khởi tạo Terraform..."
    terraform init
    print_success "Terraform đã được khởi tạo"
}

plan_terraform() {
    echo "📋 Tạo kế hoạch Terraform..."
    terraform plan
}

apply_terraform() {
    echo "⚡ Áp dụng cấu hình Terraform..."
    terraform apply -auto-approve
    
    echo ""
    print_success "Infrastructure đã được tạo thành công!"
    echo ""
    
    # Hiển thị thông tin truy cập
    echo "🌐 Truy cập services:"
    echo "  Frontend:   http://localhost:13000"
    echo "  Backend:    http://localhost:14000"  
    echo "  Prometheus: http://localhost:19090"
    echo "  Grafana:    http://localhost:13001"
    echo ""
    echo "🖥️  Truy cập containers:"
    echo "  Control Node: docker exec -it control-node bash"
    echo "  SSH Server 1: ssh -p 2221 root@localhost (password: 1234)"
    echo "  SSH Server 2: ssh -p 2222 root@localhost (password: 1234)"
    echo "  SSH Server 3: ssh -p 2223 root@localhost (password: 1234)"
}

destroy_terraform() {
    echo "💥 Xóa infrastructure..."
    print_warning "Điều này sẽ xóa tất cả containers, networks và volumes"
    read -p "Bạn có chắc chắn muốn tiếp tục? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform destroy -auto-approve
        print_success "Infrastructure đã được xóa"
    else
        echo "Hủy bỏ"
    fi
}

show_status() {
    echo "📊 Trạng thái containers:"
    docker ps --filter "name=control-node" --filter "name=ubuntu-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "🔗 Network:"
    docker network ls --filter "name=ansible-net" --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"
}

show_logs() {
    local container=${1:-"control-node"}
    echo "📋 Logs của container: $container"
    docker logs "$container" --tail=50 --follow
}

show_help() {
    echo "Sử dụng: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  init       Khởi tạo Terraform"
    echo "  plan       Xem kế hoạch thực thi"
    echo "  apply      Tạo infrastructure và chạy Ansible"
    echo "  destroy    Xóa toàn bộ infrastructure"
    echo "  status     Hiển thị trạng thái containers"
    echo "  logs [container]  Xem logs (default: control-node)"
    echo "  full       Chạy đầy đủ: init + apply"
    echo "  help       Hiển thị trợ giúp này"
}

# Main script
print_header

case "${1:-full}" in
    init)
        check_requirements
        init_terraform
        ;;
    plan)
        check_requirements
        plan_terraform
        ;;
    apply)
        check_requirements
        apply_terraform
        ;;
    destroy)
        destroy_terraform
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    full)
        check_requirements
        init_terraform
        apply_terraform
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Command không hợp lệ: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
