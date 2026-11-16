FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Jakarta \
    LANG=C.UTF-8 \
    NODE_MAJOR=20

# Dasar: SSH server + tools yang dipakai bot (git, zip/unzip, python, pip) + alat cek (htop, ping, dig).
# Daftar paket (/var/lib/apt/lists) sengaja TIDAK dihapus supaya "apt install" dari tombol Install Tools langsung jalan.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-server sudo ca-certificates curl wget git nano vim-tiny \
      unzip zip tar xz-utils htop procps net-tools iputils-ping dnsutils \
      tzdata locales gnupg python3 python3-pip \
 && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata \
 && mkdir -p /run/sshd \
 && apt-get clean

# Node.js LTS (NodeSource) + pm2 (dipakai fitur Deploy) + n (ganti versi Node kalau sc butuh versi lain).
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g pm2 n \
 && npm cache clean --force \
 && apt-get clean

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /root
EXPOSE 22
CMD ["/start.sh"]
