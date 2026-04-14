# Day 6 — Portainer 多主机舰队管理

## 目标

- 理解"多主机舰队管理"和"真正集群调度"的本质差异
- 体验通过 Web UI 统一管理多台 Docker 主机
- 对比"有 UI 面板"和"手写 Ansible/Compose"的体验差距
- 了解 Portainer Agent 的工作原理

## 预估费用

~$1.60（3 台 VM × 8 小时：1 `e2-medium` + 2 `e2-micro`）

## 执行步骤

### 1. 创建环境

```bash
bash create.sh
```

脚本会自动：
1. 创建 3 台 VM
2. 安装 Docker
3. 启动 Portainer Server（manager）
4. 启动 Portainer Agent（两台 agent）

### 2. 初始化 Portainer

```
浏览器打开：http://MANAGER_IP:9000
⚠️ 必须在启动后 5 分钟内访问并设置管理员密码
```

### 3. 添加 Agent 环境

```
Portainer 左侧 → Settings → Environments → + Add Environment
选择 Agent
填写：
  Name: agent-1
  Agent URL: AGENT1_IP:9001
点 Connect
重复添加 agent-2
```

### 4. 在 Agent 上部署服务

```
选择 agent-1 环境 → Containers → + Add Container
Image: traefik/whoami
Port: 8080 → 80
Deploy
```

### 5. 在 Manager 上部署服务（Docker Standalone 环境）

```
选择 manager 环境（local）→ Stacks → + Add Stack
粘贴以下内容：
```

```yaml
version: "3"
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma-data:/app/data
volumes:
  uptime-kuma-data:
```

### 6. 清理

```bash
bash cleanup.sh
```

## 关键概念

### 多主机管理 ≠ 集群调度

| 能力 | Portainer 多主机 | Docker Swarm / K8s |
|------|-----------------|-------------------|
| 统一查看多台主机 | ✓ | ✓ |
| 服务跨主机自动调度 | ✗ | ✓ |
| 服务故障自动迁移 | ✗ | ✓ |
| 负载均衡 | ✗（需手动配置）| ✓（内置） |
| 适合场景 | 小规模手动管理 | 生产级高可用 |

### Portainer Agent vs Docker API

| 接入方式 | 安全性 | 配置复杂度 |
|---------|-------|-----------|
| Agent（端口 9001）| TLS 加密 | 低 |
| Docker API（端口 2376）| 需要额外 TLS 配置 | 中 |
| Docker socket 挂载 | 仅限本机 | 最低 |

### Portainer 免费版限制

Portainer CE（社区版）对节点数量无限制，但部分企业特性需要 BE（商业版）：
- 基于角色的访问控制（RBAC）需要 BE
- 审计日志需要 BE
- 多环境 Edge Agent 完整功能需要 BE

## 今天的感受问题

1. Portainer 的 UI 有没有让你想"扔掉 Ansible 和 Compose 文件"？
2. 在哪个规模下你会继续用 Portainer，在哪个规模下你会切换到 Swarm/K8s？
3. 有 UI 的代价是什么？（提示：可重复性、版本控制）
