# infra-lab — 14 天 GCP 服务运维体验实验室

用 $300 GCP 赠金，14 天系统体验从单机到集群的全套服务运维体系。

---

## 前置条件

```bash
# 1. 安装 gcloud CLI
#    https://cloud.google.com/sdk/docs/install

# 2. 登录并设置项目
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 3. 启用必要 API
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  run.googleapis.com

# 4. 填写配置
cp config.sh.example config.sh  # 或直接编辑 config.sh
# 将 PROJECT_ID="YOUR_PROJECT_ID_HERE" 改为你的项目 ID

# 5. 创建实验防火墙规则（只需执行一次）
bash setup/create-firewall.sh

# 6. 建议：在 GCP Billing Console 设置预算告警
#    建议三档：$30 / $100 / $200
```

本地还需要安装（按需，在对应实验日再装）：

| 工具 | 安装日 |
|------|--------|
| `ansible` | Day 3 |
| `tofu` (OpenTofu) | Day 4 |
| `pulumi` | Day 5 |
| `kubectl` | Day 12-14 |
| `flux` CLI | Day 13（可选） |
| `argocd` CLI | Day 13（可选） |

---

## 实验日历

| 天 | 目录 | 主题 | VM 数量 | 预估费用 |
|----|------|------|---------|---------|
| Day 01 | [day01-gce-startup/](day01-gce-startup/) | GCE Startup Script 单机 | 1 | ~$0.25 |
| Day 02 | [day02-cos-cloud-init/](day02-cos-cloud-init/) | Container-Optimized OS + cloud-init | 1 | ~$0.25 |
| Day 03 | [day03-ansible-caddy/](day03-ansible-caddy/) | Ansible + Compose + Caddy 单机标准形态 | 1 | ~$0.55 |
| Day 04 | [day04-opentofu/](day04-opentofu/) | OpenTofu IaC | 1 | ~$0.40 |
| Day 05 | [day05-pulumi-gha/](day05-pulumi-gha/) | Pulumi + GitHub Actions | 1 | ~$0.40 |
| Day 06 | [day06-portainer/](day06-portainer/) | Portainer 多主机舰队管理 | 3 | ~$1.60 |
| Day 07 | [day07-coolify/](day07-coolify/) | Coolify PaaS | 1 | ~$0.55 |
| Day 08 | [day08-dokploy/](day08-dokploy/) | Dokploy PaaS | 1 | ~$0.55 |
| Day 09 | [day09-dokku/](day09-dokku/) | Dokku Heroku 风格 PaaS | 1 | ~$0.55 |
| Day 10-11 | [day10-11-swarm/](day10-11-swarm/) | Docker Swarm 集群（跨 2 天） | 5 | ~$3.90 |
| Day 12-13 | [day12-13-k3s/](day12-13-k3s/) | K3s HA + GitOps（跨 2 天） | 5 | ~$4.50 |
| Day 14 | [day14-gke-cloudrun/](day14-gke-cloudrun/) | GKE Autopilot + Cloud Run | 托管 | ~$6-10 |

**14 天总预估：$20-25**（$300 的 92% 留给深入学习）

---

## 统一约定

### 命名规则

```
lab-d01-app-01
lab-d06-portainer-manager
lab-swarm-worker-1
lab-k3s-server-1
```

### 标签规则

所有资源统一打标签，便于追踪和清理：

```
owner=lab
purpose=lab
day=d01   # 对应实验天
```

### 端口约定

| 服务 | 端口 |
|------|------|
| whoami (traefik/whoami) | 8080 |
| memos | 3000 |
| uptime-kuma | 3001 |
| postgres | 5432（内部） |
| portainer | 9000 |
| HTTP | 80 |
| HTTPS | 443 |

### Spot VM 策略

- **Worker/Agent 节点**：全部用 Spot VM（节省 60-91%）
- **Manager/Server 节点**：标准 VM
- Spot VM 最长存活 24 小时，实验中断后需重建

---

## 清理

每天实验结束后执行对应目录的 `cleanup.sh`。

紧急情况（如忘记清理）：

```bash
# 查看所有实验资源
gcloud compute instances list --filter="labels.purpose=lab"

# 一键清理全部
bash cleanup-all.sh
```

---

## 目录结构

```
infra-lab/
├── config.sh              # 全局配置（填写 PROJECT_ID）
├── cleanup-all.sh         # 紧急全局清理
├── lib/common.sh          # 共享函数库
├── setup/                 # 一次性防火墙配置
├── day01-gce-startup/
├── day02-cos-cloud-init/
├── day03-ansible-caddy/
├── day04-opentofu/
├── day05-pulumi-gha/
├── day06-portainer/
├── day07-coolify/
├── day08-dokploy/
├── day09-dokku/
├── day10-11-swarm/
├── day12-13-k3s/
└── day14-gke-cloudrun/
```
