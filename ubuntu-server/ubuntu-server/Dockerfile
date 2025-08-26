FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    openssh-server sudo \
    && rm -rf /var/lib/apt/lists/*

# tạo user root với password 1234
RUN echo 'root:1234' | chpasswd

RUN mkdir /var/run/sshd

CMD ["/usr/sbin/sshd", "-D"]
