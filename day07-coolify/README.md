# Day 7 — Coolify PaaS

## 目标

- 体验开源自托管 PaaS 的完整工作流
- 理解 Coolify 的架构（内置 Traefik + Postgres + Redis + Soketi）
- 对比"有 PaaS 抽象层"和"直接管 Compose"的体验差异
- 感受域名/SSL/环境变量/日志的一体化管理

## 预估费用

~$0.55（`e2-standard-2` × 8 小时）

## 执行步骤

### 1. 创建 VM 并安装 Coolify

```bash
bash create.sh
```

安装过程约 3-5 分钟（拉取 Docker 镜像）。

### 2. 初始化 Coolify

```
浏览器打开：http://VM_IP:8000
1. 注册管理员账号
2. 完成引导向导
3. 添加 Server → Localhost（本机模式）
```

### 3. 部署 whoami（从 Docker Image）

```
Projects → New Project → "test"
Resources → + New → Docker Image
  Image: traefik/whoami
  Port: 80
  Domain: whoami.yourdomain.com（如果有域名）
Deploy
```

### 4. 部署 memos + postgres（从 Compose）

```
Resources → + New → Docker Compose
粘贴 Compose 内容（参考 day03 的 docker-compose.yml）
Deploy
```

### 5. 探索关键功能

- **日志**：Container → Logs（实时流式）
- **终端**：Container → Terminal（浏览器终端）
- **环境变量**：Service → Environment Variables
- **域名/SSL**：Coolify 自动配置 Traefik + Let's Encrypt
- **一键备份**：Settings → Backup（Coolify 内部 Postgres）

### 6. 清理

```bash
bash cleanup.sh
```

## Coolify 架构

```
外部流量
   ↓ 80/443
Traefik（Coolify 内置，自动管理路由规则）
   ├─→ Coolify UI（:8000）
   ├─→ 你的应用 A
   └─→ 你的应用 B

Coolify 控制面
   ├─ Postgres（存储 Coolify 配置）
   ├─ Redis（队列）
   └─ Soketi（WebSocket，UI 实时更新）
```

## Coolify vs Compose + Caddy + Ansible（Day 3）

| 维度 | Coolify | Day 3 手工方案 |
|------|---------|--------------|
| 部署方式 | UI 点击 | 命令行 + 代码 |
| 反代 / SSL | 自动 | Caddy 自动 |
| 日志 | UI 内置 | docker logs |
| 版本控制 | 部分支持（Git 部署）| 完全（代码在 git）|
| 可重复性 | 较差（UI 操作）| 极好（幂等 Ansible）|
| 多服务器 | 支持（SSH 接入）| 需要手写 Ansible |
| 自身资源占用 | 高（Traefik+PG+Redis）| 低（只有 Caddy）|

## 今天的感受问题

1. Coolify 的"UI 一体化"有没有覆盖到你的主要使用场景？
2. 什么情况下你会介意"控制面本身占资源"？
3. Coolify 和 Dokku（Day 9）的设计哲学有什么根本差异？
