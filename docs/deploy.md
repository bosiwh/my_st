# SillyTavern 外网访问部署记录

> 部署时间：2026-08-09
> 部署路径：`/home/builduser/sillytavern-test/SillyTavern-release/`
> 环境：WSL2 Ubuntu + Node.js v20.20.2

---

## 架构

```
手机/平板/其他设备 ──HTTPS──▶ Cloudflare Tunnel ──▶ localhost:8000 (SillyTavern)
```

通过 Cloudflare 临时隧道（Quick Tunnel），将本地 SillyTavern 服务暴露到公网，生成一个 `*.trycloudflare.com` 的 HTTPS 链接，任何设备可访问。

---

## 关键文件清单

| 文件 | 说明 |
|------|------|
| `start-public.sh` | 启动 SillyTavern 服务 |
| `stop-public.sh` | 一键关闭服务 + 全部隧道 |
| `tunnel-cloudflared.sh` | 独立管理 cloudflared 隧道 |
| `tunnel-ngrok.sh` | 独立管理 ngrok 隧道 |
| `config.yaml` | 服务配置（外网监听 + 安全认证） |
| `cloudflared` | Cloudflare Tunnel 客户端 v2026.7.3 |
| `node_modules/` | Node.js 生产依赖（627 包） |

---

## 配置摘要

### 网络与安全

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `listen` | `true` | 监听所有网络接口（`0.0.0.0`） |
| `port` | `8000` | 服务端口 |
| `whitelistMode` | `true` | IP 白名单已开启 |
| `whitelist` | `127.0.0.1`, `::1` | 本地地址（cloudflared 代理后请求来自本地） |
| `basicAuthMode` | `true` | 基本认证已开启 |
| `basicAuthUser.username` | `user` | 登录用户名 |
| `basicAuthUser.password` | `st-tavern-9f7a2b` | 登录密码 |
| `enableUserAccounts` | `true` | 多用户账号系统已开启 |
| `enableDiscreetLogin` | `true` | 登录页隐藏用户列表 |
| `ssl.enabled` | `false` | SSL 由 Cloudflare 处理（HTTPS 已加密） |

### 其他

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `browserLaunch.enabled` | `false` | WSL 无 GUI 浏览器，已关闭自动打开 |

---

## 使用方法

### 架构

Server 和隧道拆分为**独立进程**，各自启停互不干扰：

```
SillyTavern Server (localhost:8000)
├── cloudflared 隧道 → *.trycloudflare.com
└── ngrok 隧道      → *.ngrok-free.app
```

| 脚本 | 用途 |
|------|------|
| `start-public.sh` | 启动/停止 SillyTavern 服务 |
| `stop-public.sh` | 一键关闭服务 + 全部隧道 |
| `tunnel-cloudflared.sh` | 独立管理 cloudflared 隧道 |
| `tunnel-ngrok.sh` | 独立管理 ngrok 隧道 |

### 启动

```bash
cd /home/builduser/sillytavern-test/SillyTavern-release

# 1. 启动 SillyTavern 服务
bash start-public.sh

# 2. 按需启动隧道（可同时运行多个）
bash tunnel-cloudflared.sh start    # Cloudflare，无需注册
bash tunnel-ngrok.sh start          # ngrok，需先注册，亚洲节点

# 3. 查看隧道地址和状态
bash tunnel-cloudflared.sh status
bash tunnel-ngrok.sh status
```

### 关闭

```bash
# 停止单个隧道
bash tunnel-cloudflared.sh stop
bash tunnel-ngrok.sh stop

# 一键关闭全部（server + 所有隧道）
bash stop-public.sh
```

> `start-public.sh` 的 Ctrl+C 只会关闭 server，隧道需单独 stop 或用 `stop-public.sh`。

### 同时运行两个隧道

两个隧道指向同一个 `localhost:8000`，互不冲突：

```bash
bash start-public.sh                          # 启动 server
bash tunnel-cloudflared.sh start &            # 启动 cloudflared
bash tunnel-ngrok.sh start &                  # 启动 ngrok
# 同时获得 trycloudflare 和 ngrok-free 两个公网地址
```

适用场景：对比测试两个隧道的延迟、稳定性。

### 访问

1. 查看隧道 URL：`bash tunnel-cloudflared.sh status`
2. 在任意设备浏览器打开该链接
3. 输入用户名 `user`，密码 `st-tavern-9f7a2b`
4. 进入后可注册独立账号（多用户模式）

---

## 注意事项

- **临时链接**：cloudflared Quick Tunnel 的 URL 每次启动会变化，免费无需注册 Cloudflare 账号
- **安全性**：已开启 basicAuth + 多用户账号双重保护，但建议自行修改密码
- **修改密码**：编辑 `config.yaml` 中 `basicAuthUser.password`，然后重启
- **7x24 运行**：如需长期运行，可考虑写 systemd service 或用 `nohup` / `screen` / `tmux`
- **固定域名**：如需固定 URL，参考 [docs.sillytavern.app](https://docs.sillytavern.app/usage/remoteconnections/)

---

## 认证机制说明

SillyTavern 配置了**两层认证**保护：

### 第一层：HTTP Basic Auth（浏览器原生弹窗）

打开链接后，浏览器会弹出原生的用户名/密码对话框（不是网页表单）：

| 字段 | 值 |
|------|-----|
| 用户名 | `user` |
| 密码 | `st-tavern-9f7a2b` |

> ⚠️ **常见问题**：部分浏览器（尤其是移动端）可能不显示 Basic Auth 弹窗，或弹窗一闪而过。如果遇到此问题：
> 1. 换一个浏览器试试（Chrome/Edge/Firefox）
> 2. 手动在 URL 前加上凭据（仅作为临时方案）：`https://user:st-tavern-9f7a2b@xxxx.trycloudflare.com`

### 第二层：多用户账号系统

通过 Basic Auth 后，进入 SillyTavern 登录页。已预置一个管理员账号：

| 字段 | 值 |
|------|-----|
| 用户名 | `default-user` |
| 角色 | admin（管理员） |

> **注意**：`default-user` 未设置密码（登录页会提示），建议首次登录后在 Admin Panel 中设置密码。

新用户可以自行注册独立账号（`enableUserAccounts: true`），每个账号拥有独立的角色卡、聊天记录等数据。

### 修改密码

```bash
# 修改 Basic Auth 密码
# 编辑 config.yaml 第 68 行，修改 basicAuthUser.password，然后重启

# 修改 default-user 密码
# 登录后在 Admin Panel → User Settings 中设置
```

---

## 已知问题与修复

### 2026-08-09：公网访问返回 403

**现象**：Cloudflare 隧道连接成功，但公网访问返回 HTTP 403。

**原因**：`enableForwardedWhitelist: true` 导致服务器检查 `X-Forwarded-For` 头中的真实客户端 IP，而白名单只允许 `127.0.0.1` 和 `::1`。cloudflared 转发请求时会在 `X-Forwarded-For` 中带入真实客户端 IP，触发白名单拦截。

**修复**：将 `enableForwardedWhitelist` 设为 `false`，仅检查直连 IP（cloudflared 从 `127.0.0.1` 连接，可通过白名单）。basicAuth 仍然提供用户认证保护。

```yaml
# config.yaml
enableForwardedWhitelist: false  # 改为 false
```

### 2026-08-09：端口 8000 被占用

**现象**：启动时 `EADDRINUSE: address already in use 0.0.0.0:8000`。

**原因**：上次未正常关闭的 node 进程仍占用端口。

**修复**：
```bash
kill $(ss -tlnp | grep 8000 | grep -oP 'pid=\K\d+')
```

### 2026-08-09：hostWhitelist 拦截公网请求

**现象**：所有配置正确，但公网访问仍被拒绝，日志显示 `Request from untrusted host: xxx.trycloudflare.com`。

**原因**：`hostWhitelist.scan: true` 会检查请求的 Host 头，trycloudflare.com 域名不在 `hostWhitelist.hosts` 白名单中。

**修复**：添加 `.trycloudflare.com` 到 hostWhitelist（前面的点表示匹配所有子域名）：

```yaml
# config.yaml
hostWhitelist:
  enabled: true
  scan: true
  hosts:
    - .trycloudflare.com
```

### 2026-08-09：Cloudflare 隧道 QUIC 连接不稳定

**现象**：cloudflared QUIC 连接超时，precheck 报告 region2 不可达。

**修复**：改用 HTTP2 协议（`start-public.sh` 中 `cloudflared tunnel` 添加 `--protocol http2`）。HTTP2 走标准 HTTPS 端口 443，兼容性更好。

### 2026-08-09：网页加载极慢（每次重新下载 25MB 静态资源）

**现象**：首次访问慢（可接受），但刷新或再次访问仍然很慢，浏览器 DevTools 显示大量 200 响应（非 304），每次传输约 25MB。

**原因**：Express 默认 `express.static()` 不带缓存配置，`Cache-Control: public, max-age=0` 导致浏览器**每次访问都重新下载全部静态资源**（脚本 7.6MB + 字体 9.4MB + 库 2.7MB + 语言包 2.2MB + 其他 ≈ 25MB），叠加 Cloudflare 隧道跨境延迟（中国→美国 LA 单次 RTT 200-500ms），数十个请求串行加载导致页面白屏时间长。

**诊断方法**：
```bash
# 检查静态资源缓存头
curl -s -I -u "user:password" http://localhost:8000/script.js | grep Cache-Control
# 修复前: Cache-Control: public, max-age=0
# 修复后: Cache-Control: public, max-age=604800, immutable
```

**修复**：修改 `src/server-main.js:218`，为 `express.static` 添加差异化缓存策略：

```js
// 修改前
app.use(express.static(path.join(serverDirectory, 'public'), {}));

// 修改后
app.use(express.static(path.join(serverDirectory, 'public'), {
    maxAge: '7d',
    setHeaders(res, filePath) {
        if (filePath.endsWith('.html') || filePath.endsWith('manifest.json')) {
            // HTML 不缓存，确保前端更新即时生效
            res.setHeader('Cache-Control', 'no-cache');
        } else if (/\.(js|css|woff2?|ttf|eot|png|jpg|jpeg|gif|svg|ico|mp3|wav)$/.test(filePath)) {
            // 静态资源 7 天强缓存，immutable 禁止浏览器验证
            res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
        }
    },
}));
```

**缓存策略对比**：

| 资源类型 | 修改前 | 修改后 | 刷新/回访效果 |
|----------|--------|--------|--------------|
| `*.js`、`*.css`、字体、图片 | `max-age=0` | `max-age=604800, immutable` | 0 字节，直接读缓存 |
| `*.html`、`manifest.json` | `max-age=0` | `no-cache` | 仅验证 304（几百字节） |

**影响**：**首次访问仍然慢**（25MB 跨境传输不可避免），但**第二次及以后访问几乎秒开**——浏览器直接从本地缓存加载，无需网络请求。DevTools Network 面板中大部分资源显示为 `(disk cache)`。

### 2026-08-09：跨境网络延迟 —— ngrok 替代方案

**背景**：cloudflared Quick Tunnel 免费且无需注册，但服务器固定在美国 LA，中国用户访问延迟高（每次往返 200-500ms），首次加载 25MB 静态资源体验差。

**方案**：增加 ngrok 作为可选隧道（亚洲节点），脚本支持两种模式自由切换。

**ngrok vs cloudflared 对比**：

| 维度 | cloudflared | ngrok |
|------|-------------|-------|
| 注册 | 不需要 | 需要 GitHub 登录 |
| 域名格式 | `*.trycloudflare.com` | `*.ngrok-free.app` |
| 服务器区域 | 美国 LA | **自动最优**（v3 已弃用 `--region` 参数） |
| 中国访问延迟 | 高 | **较低** |
| 固定域名 | ❌ 每次变 | ✅ 免费 1 个 |
| 会话时长 | 无限制 | 免费版约 2 小时 |
| 适合场景 | 临时测试 | 日常使用 |

**使用方法**：

```bash
# cloudflared（默认，无需配置）
bash start-public.sh

# ngrok（自动选择最优区域，需先注册）
bash tunnel-ngrok.sh start
```

**ngrok 首次配置**：

```bash
# 1. 访问 https://dashboard.ngrok.com/signup，用 GitHub 账号登录
# 2. 复制 authtoken: https://dashboard.ngrok.com/get-started/your-authtoken
# 3. 配置令牌（只需一次）
./ngrok config add-authtoken <你的令牌>
# 4. 启动
bash start-public.sh ngrok
# 终端显示 https://xxxx.ngrok-free.app 链接
```
