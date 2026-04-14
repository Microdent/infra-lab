# Day 1 — GCE Startup Script 单机实验

**全程只需要 GCP Console + 浏览器，不需要任何本地工具。**

## 目标

- 理解 GCE startup script 的执行机制
- 掌握 metadata 服务 API（`169.254.169.254`）
- 学会通过 serial console 查看启动日志
- 感受"开机即服务"的最简部署方式

## 预估费用

~$0.25（`e2-medium` × 7 小时）

---

## 一、在 Console 创建 VM

路径：**Compute Engine → VM instances → CREATE INSTANCE**

### 基础配置

| 字段 | 值 |
|------|----|
| 名称 | `lab-d01-app` |
| 区域 | `us-central1` |
| 地带 | `us-central1-b` |
| 机器系列 | E2 |
| 机器类型 | `e2-medium`（2 vCPU / 4 GB） |

### 启动磁盘（点击 CHANGE）

| 字段 | 值 |
|------|----|
| 操作系统 | Debian |
| 版本 | Debian GNU/Linux 13 (trixie) |
| 启动磁盘类型 | Standard persistent disk |
| 大小 | 20 GB |

### Networking → Network tags

```
lab-fw
```

### Management → Labels → ADD LABEL

| Key | Value |
|-----|-------|
| `owner` | `lab` |
| `purpose` | `lab` |
| `day` | `d01` |

### Management → Automation → Startup script

将以下内容**完整粘贴**到 Startup script 文本框：

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo "  [STARTUP] 开始执行 startup script"
echo "  时间：$(date)"
echo "========================================"

apt-get update -q
apt-get install -y -q nginx curl

METADATA_BASE="http://169.254.169.254/computeMetadata/v1/instance"
METADATA_HEADER="Metadata-Flavor: Google"

HOSTNAME_VAL=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/hostname" || echo "unknown")
INTERNAL_IP=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/network-interfaces/0/ip" || echo "unknown")
ZONE_VAL=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/zone" || echo "unknown")
MACHINE_TYPE=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/machine-type" || echo "unknown")

cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="UTF-8">
  <title>Day 1 — GCE Startup Script</title>
  <style>
    body { font-family: monospace; background: #1a1a2e; color: #e0e0e0; padding: 2rem; }
    h1 { color: #4ecca3; }
    table { border-collapse: collapse; margin-top: 1rem; }
    td { padding: 0.4rem 1.2rem 0.4rem 0; }
    td:first-child { color: #a0a0c0; }
    .badge { background: #4ecca3; color: #1a1a2e; padding: 0.1rem 0.5rem; border-radius: 3px; }
  </style>
</head>
<body>
  <h1>🚀 Day 1 — GCE Startup Script</h1>
  <p>这个页面由 startup script 生成，无需手动 SSH 配置。</p>
  <table>
    <tr><td>主机名</td><td><span class="badge">${HOSTNAME_VAL}</span></td></tr>
    <tr><td>内网 IP</td><td>${INTERNAL_IP}</td></tr>
    <tr><td>可用区</td><td>${ZONE_VAL}</td></tr>
    <tr><td>机型</td><td>${MACHINE_TYPE}</td></tr>
    <tr><td>启动时间</td><td>$(date)</td></tr>
  </table>
</body>
</html>
HTML

systemctl enable nginx
systemctl start nginx

echo "========================================"
echo "  [STARTUP] 执行完成 ✓"
echo "========================================"
```

点击 **CREATE** 创建 VM。

---

## 二、观察启动过程

### 查看 Serial console 日志（推荐先做）

VM 详情页 → 右上角 **CONNECT TO SERIAL CONSOLE**（或左侧菜单 → Serial port 1）

等待出现以下内容即表示 startup script 执行完毕：

```
[STARTUP] 执行完成 ✓
```

> startup script 执行时间约 60-90 秒（主要是 `apt-get update`）。

### 访问 nginx 首页

从 VM 列表复制 **External IP**，浏览器打开：

```
http://EXTERNAL_IP
```

应该能看到显示主机名、内网 IP、可用区、机型的页面。

---

## 三、SSH 进去探索 metadata

VM 详情页 → 右上角 **SSH** 按钮（Console 内置，浏览器直接打开终端）

```bash
# 读取实例 hostname
curl -sf -H "Metadata-Flavor: Google" \
  http://169.254.169.254/computeMetadata/v1/instance/hostname

# 读取内网 IP
curl -sf -H "Metadata-Flavor: Google" \
  http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/ip

# 浏览所有可用 metadata（tree 结构）
curl -sf -H "Metadata-Flavor: Google" \
  "http://169.254.169.254/computeMetadata/v1/instance/?recursive=true" \
  | python3 -m json.tool

# 查看 startup script 的 systemd 日志
sudo journalctl -u google-startup-scripts.service --no-pager
```

### 在 Console 体验 VM 操作

- **STOP** → 观察状态从 Running → Stopping → Terminated
- **START** → 观察状态恢复，**startup script 会再次执行**
- **EDIT** → 修改标签、修改 Startup script 内容（改完重启才生效）
- **VM details → Disks / Network** → 查看磁盘和网络接口详情

---

## 四、清理

**Compute Engine → VM instances → 勾选 `lab-d01-app` → DELETE**

删除时勾选 **"Also delete boot disk"**，避免磁盘继续计费。

---

## 关键概念

### Startup script 执行时机

- VM 启动后，网络就绪时自动以 **root** 身份运行
- 输出写入 serial console
- **每次重启都会执行**（与 cloud-init 首次执行的区别）

### Metadata 服务

所有 GCE 实例都可以通过 `169.254.169.254` 访问实例信息，必须携带 header：

```
Metadata-Flavor: Google
```

| 端点 | 内容 |
|------|------|
| `/instance/hostname` | 完整主机名 |
| `/instance/network-interfaces/0/ip` | 内网 IP |
| `/instance/zone` | 可用区 |
| `/instance/machine-type` | 机型 |
| `/instance/attributes/` | 自定义 metadata（含 startup-script）|

## 今天的感受问题

1. startup script 执行失败了怎么调试？（提示：serial console）
2. 每次重启都执行 startup script，这个设计有什么用处？有什么风险？
3. metadata 服务能解决什么问题？（提示：服务发现、动态配置注入）
