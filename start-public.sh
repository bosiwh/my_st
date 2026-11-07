#!/usr/bin/env bash
# SillyTavern 外网访问 - 启动服务（不启动隧道，隧道单独管理）
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
PID_FILE="/tmp/st-server.pid"

cleanup() {
    echo ""
    echo "正在关闭 SillyTavern..."
    [ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null && rm -f "$PID_FILE"
    echo "已关闭"
    exit 0
}
trap cleanup SIGINT SIGTERM

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "SillyTavern 已在运行 (PID $(cat "$PID_FILE"))"
    exit 1
fi

echo "==== SillyTavern 服务启动 ===="
[ ! -d "node_modules" ] && export NODE_ENV=production && npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev
[ ! -f "config.yaml" ] && cp default/config.yaml config.yaml

node server.js --listen &
echo $! > "$PID_FILE"
echo "SillyTavern PID: $(cat "$PID_FILE")"

echo "等待服务就绪..."
for i in $(seq 1 30); do curl -s -o /dev/null http://localhost:8000 2>/dev/null && break; sleep 1; done
echo "==== 服务已就绪 http://localhost:8000 ===="
echo ""
echo "隧道管理:"
echo "  启动 cloudflared: bash tunnel-cloudflared.sh start"
echo "  启动 ngrok:       bash tunnel-ngrok.sh start"
echo "  查看状态:         bash tunnel-cloudflared.sh status"
echo "  Ctrl+C 关闭服务"
wait "$(cat "$PID_FILE")" 2>/dev/null || true
