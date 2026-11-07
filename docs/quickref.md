# SillyTavern 外网访问 — 命令速查

> 项目路径：`/home/builduser/sillytavern-test/SillyTavern-release/`

```bash
cd /home/builduser/sillytavern-test/SillyTavern-release
```

## 服务

```bash
bash start-public.sh      # 启动
bash stop-public.sh       # 关闭服务 + 全部隧道
```

## cloudflared（免费，无需注册，美国节点）

```bash
bash tunnel-cloudflared.sh start      # 启动
bash tunnel-cloudflared.sh status     # 查看 URL
bash tunnel-cloudflared.sh stop       # 停止
```

## ngrok（需注册，亚洲节点，延迟更低）

```bash
bash tunnel-ngrok.sh start            # 启动
bash tunnel-ngrok.sh status           # 查看 URL
bash tunnel-ngrok.sh stop             # 停止
```

## 同时开两个隧道

```bash
bash start-public.sh
bash tunnel-cloudflared.sh start &
bash tunnel-ngrok.sh start &
```

## 登录

| 字段 | 值 |
|------|-----|
| 用户名 | `user` |
| 密码 | `123456` |

> 详细说明：[docs/deploy.md](deploy.md)
