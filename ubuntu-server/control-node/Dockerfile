FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    ansible \
    sshpass \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ansible
CMD ["/bin/bash"]
