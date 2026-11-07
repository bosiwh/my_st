#!/usr/bin/env bash
# 单独启动 cloudflared 隧道（需 SillyTavern 已在 8000 端口运行）
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
CLOUDFLARED="./cloudflared"
PID_FILE="/tmp/st-cloudflared.pid"

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "cloudflared 已在运行 (PID $(cat "$PID_FILE"))"
        return 1
    fi
    [ ! -f "$CLOUDFLARED" ] && curl -Lo "$CLOUDFLARED" https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x "$CLOUDFLARED"
    echo "启动 cloudflared 隧道..."
    nohup ./cloudflared tunnel --url http://localhost:8000 --protocol http2 &>/tmp/st-cloudflared.log &
    echo $! > "$PID_FILE"
    echo "cloudflared PID: $(cat "$PID_FILE")"
    echo "日志: /tmp/st-cloudflared.log"
    echo "等待隧道 URL..."
    sleep 8
    grep -oP 'https://[^ ]*\.trycloudflare\.com' /tmp/st-cloudflared.log | tail -1
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null && echo "已停止 cloudflared (PID $PID)" || echo "cloudflared 已退出"
        rm -f "$PID_FILE"
    else
        echo "cloudflared 未运行"
    fi
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "cloudflared 运行中 (PID $(cat "$PID_FILE"))"
        grep -oP 'https://[^ ]*\.trycloudflare\.com' /tmp/st-cloudflared.log 2>/dev/null | tail -1
    else
        echo "cloudflared 未运行"
    fi
}

case "${1:-start}" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    *)      echo "用法: bash tunnel-cloudflared.sh {start|stop|status}" ;;
esac
