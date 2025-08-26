FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssh-server sudo \
    && rm -rf /var/lib/apt/lists/*

# tạo user root với password 1234
RUN echo 'root:1234' | chpasswd

# Cho phép root login qua SSH
RUN sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN mkdir /var/run/sshd

CMD ["/usr/sbin/sshd", "-D"]