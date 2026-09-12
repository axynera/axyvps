cat > /opt/axynera/bin/start.sh << 'STARTSVC'
#!/bin/bash
AXY_LOG="/opt/axynera/logs"

echo "[+] Starting Axynera Cloud Services..."

if ! pgrep -x "sshd" > /dev/null; then
    /usr/sbin/sshd
    echo "[OK] OpenSSH Server running on port 22"
else
    echo "[INFO] OpenSSH Server is active."
fi

if ! pgrep -x "cloudflared" > /dev/null; then
    nohup /usr/local/bin/cloudflared tunnel run --token eyJhIjoiNmRkNWZhMWYwMjM2NzhlNGM5YmY5MzQyYWJjYzFjZDYiLCJ0IjoiMzQ1Y2VkYWItYjQ1NS00YTkzLTkzY2ItNWMyYTBiZTYyMjk3IiwicyI6Ik1tWXhZamN6TWpNdFpEaGpOUzAwTjJJMUxXRTBOR1l0T0daak9ETmpZakZtTnpoayJ9 > "$AXY_LOG/cloudflared.log" 2>&1 &
    echo "[OK] Cloudflare Backbone Tunnel active (Token Mode)."
else
    echo "[INFO] Cloudflare Tunnel is active."
fi

echo "[+] All Axynera Cloud services are live."
STARTSVC
chmod +x /opt/axynera/bin/start.sh
