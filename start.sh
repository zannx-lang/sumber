#!/bin/bash
# Variabel dari bot: ROOT_PASSWORD / PASSWORD (root). Opsional: USER_NAME + USER_PASSWORD (+ SUDO_ACCESS) buat user biasa.
set -e

ROOT_PW="${ROOT_PASSWORD:-${PASSWORD:-}}"
if [ -z "$ROOT_PW" ]; then
  echo "ROOT_PASSWORD belum diset, SSH tidak dijalankan."
  exit 1
fi

# --- akun ---
echo "root:${ROOT_PW}" | chpasswd
if [ -n "${USER_NAME:-}" ]; then
  id "$USER_NAME" >/dev/null 2>&1 || useradd -m -s /bin/bash "$USER_NAME"
  echo "${USER_NAME}:${USER_PASSWORD:-$ROOT_PW}" | chpasswd
  [ "${SUDO_ACCESS:-true}" = "true" ] && usermod -aG sudo "$USER_NAME"
fi

# --- SSH (drop-in, dibaca sebelum sshd_config utama) ---
ssh-keygen -A >/dev/null 2>&1 || true
mkdir -p /run/sshd /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/10-vps.conf <<'CONF'
PermitRootLogin yes
PasswordAuthentication yes
UseDNS no
X11Forwarding no
ClientAliveInterval 60
ClientAliveCountMax 5
MaxAuthTries 4
LoginGraceTime 30
MaxSessions 10
CONF

# --- kenyamanan shell (sekali saja) ---
if ! grep -q "# vps-template" /root/.bashrc 2>/dev/null; then
  cat >> /root/.bashrc <<'RC'
# vps-template
export PS1='\[\e[1;35m\]\u@\h\[\e[0m\]:\[\e[1;36m\]\w\[\e[0m\]\$ '
alias ll='ls -lah --color=auto'
alias ports='ss -tulpn 2>/dev/null || netstat -tulpn'
alias mem='free -h'
RC
fi

# variabel container (tanpa password) tersedia untuk sesi login interaktif
export -p | grep -Ev '^declare -x (ROOT_PASSWORD|PASSWORD|USER_PASSWORD|HOME|PWD|OLDPWD|SHLVL|_|HOSTNAME|TERM|PATH)=' \
  > /etc/profile.d/10-container-env.sh 2>/dev/null || true

echo "sshd siap di port 22"
exec /usr/sbin/sshd -D -e
