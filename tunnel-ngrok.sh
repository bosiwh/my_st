#!/usr/bin/env bash
# 单独启动 ngrok 隧道（需 SillyTavern 已在 8000 端口运行）
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
NGROK="./ngrok"
PID_FILE="/tmp/st-ngrok.pid"
start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "ngrok 已在运行 (PID $(cat "$PID_FILE"))"
        return 1
    fi
    if [ ! -f "$NGROK" ]; then
        echo "下载 ngrok..."
        curl -Lo ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
        tar xzf ngrok.tgz ngrok && rm ngrok.tgz && chmod +x ngrok
    fi
    if ! grep -q "authtoken" ~/.config/ngrok/ngrok.yml 2>/dev/null; then
        echo "未配置 ngrok authtoken，请先运行: ./ngrok config add-authtoken <令牌>"
        exit 1
    fi
    echo "启动 ngrok 隧道..."
    nohup ./ngrok http 8000 --log=stdout &>/tmp/st-ngrok.log &
    echo $! > "$PID_FILE"
    echo "ngrok PID: $(cat "$PID_FILE")"
    echo "日志: /tmp/st-ngrok.log"
    echo "等待隧道 URL..."
    for i in $(seq 1 15); do
        URL=$(grep -oP 'url=https://\K[^ ]+' /tmp/st-ngrok.log 2>/dev/null | tail -1)
        [ -n "$URL" ] && echo "$URL" && break
        sleep 1
    done
    [ -z "$URL" ] && echo "(超时，查看日志: tail /tmp/st-ngrok.log)"
}

stop() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        kill "$PID" 2>/dev/null && echo "已停止 ngrok (PID $PID)" || echo "ngrok 已退出"
        rm -f "$PID_FILE"
    else
        echo "ngrok 未运行"
    fi
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "ngrok 运行中 (PID $(cat "$PID_FILE"))"
        grep -oP 'url=https://\K[^ ]+' /tmp/st-ngrok.log 2>/dev/null | tail -1
    else
        echo "ngrok 未运行"
    fi
}

case "${1:-start}" in
    start)  start ;;
    stop)   stop ;;
    status) status ;;
    *)      echo "用法: bash tunnel-ngrok.sh {start|stop|status}" ;;
esac
