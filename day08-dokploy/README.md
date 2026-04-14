# Day 8 — Dokploy PaaS

## 目标

- 对比 Dokploy 与 Coolify（Day 7）的使用体验
- 体验 Dokploy 的多服务器（Swarm 后端）能力
- 感受不同 PaaS 的抽象层次和操作心智

## 预估费用

~$0.55（`e2-medium` × 8 小时）

## 执行步骤

### 1. 创建 VM 并安装 Dokploy

```bash
bash create.sh
```

### 2. 访问 Dokploy

```
浏览器：http://VM_IP:3000
注册管理员账号
```

### 3. 部署应用

```
Projects → Create Project → "lab"
Applications → Create Application
  Type: Docker Image
  Image: traefik/whoami
  Port: 80 → 8080
Deploy
```

### 4. 部署 memos（Compose 方式）

```
Applications → Create Application
  Type: Docker Compose
  粘贴 compose 内容
Deploy
```

### 5. 对比关注点

与 Coolify 做横向对比：
- 部署流程流畅度
- 域名/SSL 配置方式
- 日志和终端体验
- 环境变量管理
- 多服务器支持（Dokploy 底层用 Docker Swarm）

### 6. 清理

```bash
bash cleanup.sh
```

## Dokploy vs Coolify

| 维度 | Dokploy | Coolify |
|------|---------|---------|
| 底层集群 | Docker Swarm | 单机 Docker |
| 多服务器 | 原生支持 | SSH 远端 |
| 开源协议 | MIT | Apache 2.0 |
| UI 成熟度 | 较新 | 更成熟 |
| GitHub 集成 | 支持 | 支持 |
| 自身资源 | 中 | 较高 |

## 今天的感受问题

1. Dokploy 和 Coolify 你更愿意长期用哪个？理由是什么？
2. 这类"UI PaaS"的核心价值是什么？核心限制是什么？
3. 对于独立开发者的个人项目，你会选这类工具还是继续 Compose + Caddy？
