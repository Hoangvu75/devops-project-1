FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    sshpass \
    openssh-client \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Cài Ansible qua pip để chủ động version
RUN pip3 install --no-cache-dir ansible

# Copy requirements để install collection lúc build
WORKDIR /control-node
COPY requirements.yml ./
RUN ansible-galaxy collection install -r requirements.yml

# Thư mục làm việc thực tế sẽ mount repo vào /workspace
WORKDIR /workspace
CMD ["/bin/bash"]
