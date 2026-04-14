# Day 2 — Container-Optimized OS + cloud-init

**全程只需要 GCP Console + 浏览器，不需要任何本地工具。**

## 目标

- 理解 Container-Optimized OS 的设计理念（只读 rootfs、容器优先）
- 对比 cloud-init 和 Day 1 的 startup-script 的差异
- 体验"开机即容器"的工作方式

## 预估费用

~$0.25（`e2-medium` × 7 小时）

---

## 一、在 Console 创建 VM

路径：**Compute Engine → VM instances → CREATE INSTANCE**

### 基础配置

| 字段 | 值 |
|------|----|
| 名称 | `lab-d02-cos` |
| 区域 | `us-central1` |
| 地带 | `us-central1-b` |
| 机器类型 | `e2-medium`（2 vCPU / 4 GB） |

### 启动磁盘（点击 CHANGE）⚠️ 关键步骤

| 字段 | 值 |
|------|----|
| 操作系统 | **Container-Optimized OS** |
| 版本 | cos-stable（选最新 stable 版本） |
| 启动磁盘类型 | Standard persistent disk |
| 大小 | 20 GB |

> COS 和 Debian 在同一个下拉列表里，注意不要选错。

### Networking → Network tags

```
lab-fw
```

### Management → Labels

| Key | Value |
|-----|-------|
| `owner` | `lab` |
| `purpose` | `lab` |
| `day` | `d02` |

### Management → Metadata → ADD ITEM ⚠️ 不是 Startup script！

| Key | Value |
|-----|-------|
| `user-data` | 将以下 cloud-init 内容完整粘贴 |

**`user-data` 内容：**

```yaml
#cloud-config
runcmd:
  - docker pull traefik/whoami
  - docker pull louislam/uptime-kuma:1
  - |
    docker run -d \
      --name whoami \
      --restart unless-stopped \
      -p 8080:80 \
      -e WHOAMI_NAME="day02-cos-vm" \
      traefik/whoami
  - |
    docker run -d \
      --name uptime-kuma \
      --restart unless-stopped \
      -p 3001:3001 \
      -v uptime-kuma-data:/app/data \
      louislam/uptime-kuma:1
  - echo "CLOUD-INIT COMPLETE" > /dev/console
```

> **注意**：`user-data` 在 Metadata 里，不是在 Automation → Startup script 里。
> 两者是不同的机制，这正是今天要感受的区别。

点击 **CREATE**。

---

## 二、观察启动过程

### Serial console 查看 cloud-init 日志

VM 详情页 → **CONNECT TO SERIAL CONSOLE**

等待出现：
```
CLOUD-INIT COMPLETE
```

镜像拉取需要约 1-3 分钟（取决于镜像大小）。

### 访问服务

从 VM 列表复制 External IP：

```
http://EXTERNAL_IP:8080      ← whoami
http://EXTERNAL_IP:3001      ← uptime-kuma（首次访问需初始化）
```

---

## 三、SSH 进去探索 COS

VM 详情页 → **SSH** 按钮

```bash
# 查看容器运行状态
docker ps

# 查看容器日志
docker logs whoami

# 验证 cloud-init 执行状态
sudo cloud-init status

# 查看 cloud-init 详细日志
sudo cat /var/log/cloud-init-output.log

# 探索 COS 的特点
cat /etc/os-release         # Chromium OS 底层
mount | grep ' / '          # 看 rootfs 是否只读
ls /                        # 目录结构和 Debian 有什么不同

# 尝试 apt-get（会失败，理解 COS 的约束）
apt-get install vim         # ← 预期报错
```

### 在 Console 体验 VM 操作

- **STOP → START**：观察容器是否自动恢复（因为用了 `--restart unless-stopped`）
- **VM details → Boot disk**：注意 COS 镜像的描述和 Debian 的差异
- **Monitoring**：查看 CPU/内存使用图，对比 Day 1（两者都只跑了几个容器）

---

## 四、清理

**Compute Engine → VM instances → 勾选 `lab-d02-cos` → DELETE**

勾选 **"Also delete boot disk"**。

---

## 关键概念

### cloud-init vs startup-script

| | cloud-init | startup-script |
|---|---|---|
| 传入方式 | Metadata `user-data` | Metadata `startup-script` |
| 格式 | YAML（声明式） | Bash（命令式） |
| 执行时机 | 仅首次启动（默认） | **每次**重启 |
| 跨云标准 | 是（AWS/Azure/GCP 通用） | GCP 专有 |

### Container-Optimized OS 特点

| 特性 | 说明 |
|------|------|
| 只读 rootfs | 系统文件不可修改 |
| 无包管理器 | 不能 apt install |
| 内置 Docker | 预装，无需安装 |
| 自动更新 | 系统自动拉取安全补丁 |
| 最小攻击面 | 去掉了大多数 Linux 工具 |

### COS 的 cloud-init 限制

COS 只支持 cloud-init 的一个子集：

- ✅ `runcmd` — 执行命令
- ✅ `write_files` — 写文件（到可写目录，如 `/tmp/`、`/home/`）
- ❌ `packages` — 无法安装 apt 包

## 今天的感受问题

1. cloud-init 只在首次启动执行，这个设计和 startup-script 每次都执行，各适合什么场景？
2. COS 的只读 rootfs 带来了什么安全好处？有什么代价？
3. 如果需要在 COS 上持久化数据，应该放在哪里？（提示：`docker -v`）
