variable "repo_dir" {
  type        = string
  description = "Đường dẫn tuyệt đối tới thư mục devops-project-1 trên host"
  default     = "/Users/alphalogy2/Workspace/devops-project-1"
}

variable "wait_for_containers_seconds" {
  type        = number
  description = "Thời gian chờ containers khởi động trước khi chạy Ansible (giây)"
  default     = 30
}
