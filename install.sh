#!/bin/sh
set -e

# ====================================================================
# AXYNERA VPS - PLAYIT.GG INSTALLER SCRIPT
# ====================================================================

AXY_DIR="/opt/axynera"
AXY_BIN="$AXY_DIR/bin"
AXY_LOG="$AXY_DIR/logs"

echo "[+] Mempersiapkan direktori Playit.gg..."
mkdir -p "$AXY_BIN" "$AXY_LOG"

echo "[+] Membersihkan binary Playit lama (jika ada)..."
pkill -x playit 2>/dev/null || true
rm -f /usr/local/bin/playit "$AXY_BIN/playit.sh"

echo "[+] Mengunduh binary resmi Playit.gg (ARM64 Native)..."
curl -SsL "https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-cli-linux-aarch64" -o /usr/local/bin/playit

echo "[+] Mengatur izin eksekusi binary..."
chmod +x /usr/local/bin/playit

# ====================================================================
# MEMBUAT SERVICE CONTROLLER PLAYIT
# ====================================================================
echo "[+] Menyiapkan controller service Playit.gg..."
printf '%s\n' \
'#!/bin/bash' \
'AXY_LOG="/opt/axynera/logs"' \
'if ! pgrep -x "playit" > /dev/null; then' \
'    nohup /usr/local/bin/playit > "$AXY_LOG/playit.log" 2>&1 &' \
'    echo "[OK] Playit.gg Direct TCP Tunnel active in background."' \
'else' \
'    echo "[INFO] Playit.gg Tunnel is already running."' \
'fi' > "$AXY_BIN/playit.sh"

chmod +x "$AXY_BIN/playit.sh"

echo "===================================================================="
echo "          Playit.gg Installation Complete!                          "
echo "===================================================================="
echo "[!] Menjalankan Playit.gg untuk proses Claim / Setup awal..."
echo "[!] Catat/buka link claim yang muncul di bawah pada browser:"
echo "===================================================================="
echo ""

# Menjalankan playit secara interaktif agar link klaim muncul di layar
/usr/local/bin/playit
