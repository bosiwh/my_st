#!/usr/bin/env bash
# SillyTavern 外网访问 - 关闭所有服务（server + 隧道）

echo "==== 关闭 SillyTavern 全部服务 ===="

# 停止 server
if [ -f /tmp/st-server.pid ]; then
    PID=$(cat /tmp/st-server.pid)
    kill "$PID" 2>/dev/null && echo "已停止 SillyTavern (PID $PID)" || echo "SillyTavern 已退出"
    rm -f /tmp/st-server.pid
else
    # fallback: 按端口杀
    FALLBACK=$(ss -tlnp 2>/dev/null | grep 8000 | grep -oP 'pid=\K\d+' | head -1)
    if [ -n "$FALLBACK" ]; then
        kill "$FALLBACK" 2>/dev/null && echo "已停止 SillyTavern (PID $FALLBACK)"
    else
        echo "SillyTavern 未运行"
    fi
fi

# 停止 cloudflared
bash "$(dirname "$0")/tunnel-cloudflared.sh" stop 2>/dev/null

# 停止 ngrok
bash "$(dirname "$0")/tunnel-ngrok.sh" stop 2>/dev/null

echo "==== 全部已关闭 ===="
