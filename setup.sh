#!/bin/sh
set -e

# ====================================================================
# 1. PERSIAPAN DIREKTORI TERISOLASI (/opt/axynera)
# ====================================================================
AXY_DIR="/opt/axynera"
AXY_BIN="$AXY_DIR/bin"
AXY_LOG="$AXY_DIR/logs"
AXY_CFG="$AXY_DIR/config"

echo "[+] Membuka direktori terisolasi Axynera di $AXY_DIR..."
mkdir -p "$AXY_BIN" "$AXY_LOG" "$AXY_CFG"

# ====================================================================
# 2. INSTALL DEPENDENCY & SYSTEM HOSTNAME
# ====================================================================
echo "[+] Menginstal paket dependency server..."
apk update && apk upgrade
apk add openssh sudo bash curl wget nano htop openrc shadow

echo "[+] Mengunduh binary resmi Cloudflare Tunnel (cloudflared)..."
ARCH=$(uname -m)
case "$ARCH" in
    aarch64|arm64) CF_ARCH="arm64" ;;
    armv7l|armhf|arm) CF_ARCH="arm" ;;
    x86_64) CF_ARCH="amd64" ;;
    i386|i686) CF_ARCH="386" ;;
    *) CF_ARCH="arm64" ;;
esac

curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

echo "[+] Mengatur hostname sistem..."
hostname "axynera-vps-node1"
echo "axynera-vps-node1" > /etc/hostname

echo "[+] Generating Host Key OpenSSH..."
ssh-keygen -A

# ====================================================================
# 3. KONFIGURASI OPENSSH & BANNER (MOTD)
# ====================================================================
echo "[+] Menyiapkan konfigurasi OpenSSH & Banner Axynera Cloud..."
printf '%s\n' \
'Port 22' \
'Protocol 2' \
'HostKey /etc/ssh/ssh_host_rsa_key' \
'HostKey /etc/ssh/ssh_host_ecdsa_key' \
'HostKey /etc/ssh/ssh_host_ed25519_key' \
'' \
'PermitRootLogin yes' \
'PasswordAuthentication yes' \
'PubkeyAuthentication yes' \
'AuthorizedKeysFile .ssh/authorized_keys' \
'' \
'ClientAliveInterval 60' \
'ClientAliveCountMax 3' \
'' \
'X11Forwarding no' \
'AllowTcpForwarding yes' \
'UsePAM no' \
'Subsystem sftp /usr/libexec/sftp-server' > /etc/ssh/sshd_config

printf '%s\n' \
'====================================================================' \
'                 Welcome to Axynera Cloud Services' \
'====================================================================' \
'  Instance Domain  : Axynera Enterprise Cloud Instance' \
'  OS Environment   : Alpine Linux Enterprise (x86_64 Cloud)' \
'  Hypervisor Engine: Axynera Container Virtualization' \
'  RAM Allocation   : 1024 MB Dedicated RAM + 1024 MB SWAP' \
'  Network Uplink   : High-Speed Encrypted Cloudflare Backbone' \
'  System Status    : HEALTHY (24/7 Uptime Guaranteed)' \
'  Dashboard Portal : https://axynera.com' \
'--------------------------------------------------------------------' \
'  SECURITY WARNING:' \
'  - Unauthorized access is strictly prohibited.' \
'  - DDoS attacks, crypto mining, and torrenting are monitored' \
'    and will result in instant account suspension.' \
'====================================================================' > /etc/motd

# ====================================================================
# 4. MANAJEMEN USER PENYEWA (client1)
# ====================================================================
if ! id "client1" >/dev/null 2>&1; then
    echo "[+] Membuat akun user penyewa (client1)..."
    useradd -m -s /bin/bash client1
    echo "[!] Atur password baru untuk client1:"
    passwd client1
fi

echo "client1 ALL=(ALL) ALL" > /etc/sudoers.d/client1
chmod 0440 /etc/sudoers.d/client1
chown -R client1:client1 /home/client1

printf '%s\n' 'export PS1="\[\033[01;32m\]client1@axynera-vps\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /home/client1/.bashrc

# ====================================================================
# 5. SKRIP KONTROL SERVICE (START, STOP, REBOOT, UNINSTALL)
# ====================================================================

# A. Start Service
printf '%s\n' \
'#!/bin/bash' \
'AXY_LOG="/opt/axynera/logs"' \
'' \
'echo "[+] Starting Axynera Cloud Services..."' \
'' \
'if ! pgrep -x "sshd" > /dev/null; then' \
'    /usr/sbin/sshd' \
'    echo "[OK] OpenSSH Server running on port 22"' \
'else' \
'    echo "[INFO] OpenSSH Server is active."' \
'fi' \
'' \
'if ! pgrep -x "cloudflared" > /dev/null; then' \
'    nohup /usr/local/bin/cloudflared tunnel --url ssh://localhost:22 > "$AXY_LOG/cloudflared.log" 2>&1 &' \
'    echo "[OK] Cloudflare Backbone Tunnel active."' \
'else' \
'    echo "[INFO] Cloudflare Tunnel is active."' \
'fi' \
'' \
'echo "[+] All Axynera Cloud services are live."' > "$AXY_BIN/start.sh"

# B. Stop Service
printf '%s\n' \
'#!/bin/bash' \
'echo "[-] Stopping Axynera Cloud Services..."' \
'pkill -x sshd || true' \
'pkill -x cloudflared || true' \
'echo "[OK] All Axynera services stopped."' > "$AXY_BIN/stop.sh"

# C. Reboot Service Container
printf '%s\n' \
'#!/bin/bash' \
'echo "[!] Rebooting Axynera VPS Container..."' \
'echo "[+] Stopping running instances..."' \
'/opt/axynera/bin/stop.sh' \
'' \
'echo "[+] Flushing cache and temporary memory..."' \
'rm -rf /tmp/* 2>/dev/null || true' \
'' \
'sleep 2' \
'' \
'echo "[+] Restarting Axynera Cloud Services..."' \
'/opt/axynera/bin/start.sh' \
'echo "[OK] Axynera VPS Node successfully rebooted!"' > "$AXY_BIN/reboot.sh"

# D. Uninstall / Clean Reset
printf '%s\n' \
'#!/bin/bash' \
'echo "[!] UNINSTALLING AXYNERA VPS SYSTEM..."' \
'/opt/axynera/bin/stop.sh' \
'userdel -r client1 2>/dev/null || true' \
'rm -f /etc/sudoers.d/client1' \
'rm -rf /opt/axynera' \
'echo "[OK] Axynera system completely removed."' > "$AXY_BIN/uninstall.sh"

chmod +x "$AXY_BIN/"*.sh

# ====================================================================
# 6. SYMLINK COMMAND SYSTEM
# ====================================================================
ln -sf "$AXY_BIN/start.sh" /usr/local/bin/axynera-start
ln -sf "$AXY_BIN/stop.sh" /usr/local/bin/axynera-stop
ln -sf "$AXY_BIN/reboot.sh" /usr/local/bin/axynera-reboot
ln -sf "$AXY_BIN/uninstall.sh" /usr/local/bin/axynera-reset

# Override perintah reboot standar Linux
ln -sf "$AXY_BIN/reboot.sh" /sbin/reboot 2>/dev/null || true
ln -sf "$AXY_BIN/reboot.sh" /usr/local/bin/reboot 2>/dev/null || true

# ====================================================================
# 7. EKSEKUSI PERTAMA KALI
# ====================================================================
echo "===================================================================="
echo "          Axynera VPS Installation Complete!                        "
echo "===================================================================="
/usr/local/bin/axynera-start
