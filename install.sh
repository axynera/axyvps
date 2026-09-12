#!/bin/sh
set -e

# ====================================================================
# AXYNERA VPS - PLAYIT.GG INSTALLER SCRIPT (ARM64)
# ====================================================================

AXY_DIR="/opt/axynera"
AXY_BIN="$AXY_DIR/bin"
AXY_LOG="$AXY_DIR/logs"

echo "[+] Mempersiapkan direktori Playit.gg..."
mkdir -p "$AXY_BIN" "$AXY_LOG"

echo "[+] Membersihkan instalasi bekas/terdampak error..."
pkill -x playit 2>/dev/null || true
rm -f /usr/local/bin/playit "$AXY_BIN/playit.sh"

echo "[+] Mengunduh binary resmi Playit.gg (AArch64 / ARM64)..."
curl -SsL "https://github.com/playit-cloud/playit-agent/releases/download/v1.0.10/playit-cli-linux-aarch64" -o /usr/local/bin/playit

echo "[+] Mengatur izin eksekusi..."
chmod +x /usr/local/bin/playit

# Uji validitas binary yang terunduh
if ! head -n 1 /usr/local/bin/playit | grep -q "ELF"; then
    echo "[!] ERROR: Binary terunduh bukan format ELF yang valid!"
    exit 1
fi

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
echo "[!] Buka link claim yang muncul di layar pada browser:"
echo "===================================================================="
echo ""

# Menjalankan playit interaktif agar link claim muncul di terminal
/usr/local/bin/playit
