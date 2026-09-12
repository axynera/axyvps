#!/bin/sh
set -e

# ====================================================================
# AXYNERA VPS - OFFICIAL PLAYIT.GG REPO INSTALLER
# ====================================================================

AXY_DIR="/opt/axynera"
AXY_BIN="$AXY_DIR/bin"
AXY_LOG="$AXY_DIR/logs"

echo "[+] Mempersiapkan direktori Axynera..."
mkdir -p "$AXY_BIN" "$AXY_LOG"

echo "[+] Menginstal dependency dasar (bash, curl, openrc)..."
apk update
apk add bash curl openrc shadow coreutils gnupg wget grep

echo "[+] Mengunduh & menjalankan Official Installer Playit.gg (-y Mode)..."
curl -SsL "https://packages.playit.gg/install.sh" | bash -s -- -y

# Check apakah playit berhasil terpasang di sistem
if ! command -v playit >/dev/null 2>&1; then
    echo "[!] Warning: Paket apk playit tidak ditemukan, mengunduh biner cadangan..."
    curl -SsL "https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-cli-linux-aarch64" -o /usr/local/bin/playit
    chmod +x /usr/local/bin/playit
fi

# ====================================================================
# MEMBUAT SERVICE CONTROLLER PLAYIT
# ====================================================================
echo "[+] Menyiapkan controller service Playit.gg..."
printf '%s\n' \
'#!/bin/bash' \
'AXY_LOG="/opt/axynera/logs"' \
'if ! pgrep -x "playit" > /dev/null; then' \
'    nohup playit > "$AXY_LOG/playit.log" 2>&1 &' \
'    echo "[OK] Playit.gg Direct TCP Tunnel active in background."' \
'else' \
'    echo "[INFO] Playit.gg Tunnel is already running."' \
'fi' > "$AXY_BIN/playit.sh"

chmod +x "$AXY_BIN/playit.sh"

echo "===================================================================="
echo "          Playit.gg Official Installation Complete!                  "
echo "===================================================================="
echo "[!] Menjalankan Playit.gg untuk proses Claim / Setup awal..."
echo "[!] Buka link claim yang muncul di terminal pada browser kamu:"
echo "===================================================================="
echo ""

# Jalankan playit untuk memunculkan link Claim Code ke layar
playit
