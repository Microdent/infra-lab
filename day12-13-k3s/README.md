# Day 12-13 — K3s HA + GitOps（ArgoCD / Flux）

## 目标

- **Day 12**：搭建 K3s HA 集群，体验 Kubernetes 的核心资源模型
- **Day 13**：用 ArgoCD 或 Flux 实现 GitOps，感受"Git 是唯一真相"

## 集群架构

```
内部 TCP LB（port 6443）
  ├─→ Server-1（lab-k3s-server-1，e2-standard-2）
  └─→ Server-2（lab-k3s-server-2，e2-medium）

Agents（Spot VM，e2-medium）
  ├─ lab-k3s-agent-1
  ├─ lab-k3s-agent-2
  └─ lab-k3s-agent-3
```

## 预估费用

~$4.50（5 台 VM × 16 小时 + 内部 LB；Spot Agent 节省约 40%）

## Day 12 — 搭建 K3s HA 集群

### 1. 创建 VM 和内部 LB

```bash
bash create-vms.sh
```

### 2. 初始化 K3s

```bash
bash init-k3s.sh
```

脚本自动完成：
- Server-1：`--cluster-init` 启动嵌入式 etcd HA
- Server-2：加入 Server-1
- Agents：通过内部 LB 加入
- 下载 kubeconfig 到本地

### 3. 使用集群

```bash
export KUBECONFIG=day12-13-k3s/kubeconfig-lab.yaml

# 查看节点
kubectl get nodes -o wide

# 查看节点标签
kubectl get nodes --show-labels
```

### 4. 部署应用

```bash
# 部署所有 manifest
kubectl apply -f day12-13-k3s/manifests/

# 查看状态
kubectl get pods,svc,ingress -o wide

# 等待 whoami 就绪
kubectl rollout status deployment/whoami
```

### 5. 访问服务

```bash
SRV1_IP=$(kubectl get nodes -l role=server \
  -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || \
  gcloud compute instances describe lab-k3s-server-1 \
    --zone=us-central1-b \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

# whoami（通过 NodePort 或 Traefik Ingress）
curl http://${SRV1_IP}:$(kubectl get svc whoami -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "80")
```

## Day 13 — GitOps with ArgoCD

### 前提

将 `infra-lab` 推送到 GitHub（public repo，或配置 ArgoCD 私有仓库认证）：

```bash
git add .
git commit -m "day12-13: k3s manifests"
git push origin main
```

### 安装 ArgoCD

```bash
bash argocd/install.sh
```

### 配置 GitOps Application

```bash
# 编辑 argocd/app-whoami.yaml，填写真实仓库地址
vim argocd/app-whoami.yaml
# 修改：repoURL: https://github.com/YOUR_GITHUB_USERNAME/infra-lab.git

# 应用
kubectl apply -f argocd/app-whoami.yaml
```

### 体验 GitOps 同步

```bash
# 修改 whoami 副本数
sed -i 's/replicas: 3/replicas: 5/' manifests/whoami-deployment.yaml
git add manifests/whoami-deployment.yaml
git commit -m "scale whoami to 5 replicas"
git push origin main

# 在 ArgoCD UI 中观察自动同步（约 3 分钟）
# 或手动触发：
kubectl annotate application whoami -n argocd \
  argocd.argoproj.io/refresh=normal
```

## 备选：Flux CD

```bash
# 需要 GITHUB_TOKEN 和 GITHUB_USER
export GITHUB_TOKEN=ghp_xxx
export GITHUB_USER=your_username

bash flux/install.sh
```

## ArgoCD vs Flux 对比

| 维度 | ArgoCD | Flux |
|------|--------|------|
| UI | 丰富的 Web UI | 无（CLI 为主）|
| 架构 | 单体应用 | 多控制器（模块化）|
| Pull 间隔 | 3 分钟（默认）| 1 分钟（默认）|
| 多租户 | 项目/团队隔离 | 好（Namespace 级别）|
| Helm 支持 | 是 | 是（HelmRelease）|
| Kustomize | 是 | 是（Kustomization）|
| CNCF 状态 | 毕业 | 毕业 |
| 学习曲线 | 低（UI 友好）| 中（纯 GitOps 思维）|

## K3s vs Swarm（Day 10-11）对比

| 维度 | K3s | Docker Swarm |
|------|-----|-------------|
| API 标准 | Kubernetes API | Docker API |
| 复杂度 | 高 | 低 |
| 生态 | 极丰富（Helm 等）| 有限 |
| 有状态服务 | StatefulSet + PVC | Stack + Volume |
| 调试 | kubectl + 多层抽象 | docker service |
| 适用规模 | 任意（推荐中大型）| 小型 |

## 关键 K8s 概念

### local-path Provisioner（K3s 内置）

K3s 自带 `local-path-provisioner`，PVC 会自动在节点本地创建目录。

**注意**：local-path 数据绑定到特定节点，Pod 被调度到其他节点时数据不跟随。生产环境需使用网络存储（GCP Persistent Disk、Longhorn 等）。

### HA 嵌入式 etcd

K3s 的 HA 模式使用嵌入式 etcd（基于 K3s 的 kine 抽象）：
- 3 个 server 节点才能容错 1 个故障（Raft 算法）
- 本实验 2 个 server 节点可用性提升，但不能容错节点故障

## 清理

```bash
bash cleanup.sh
```

## 今天的感受问题

1. K3s 和 Swarm 的复杂度差异，对你来说值得换来的能力是什么？
2. GitOps（ArgoCD）和传统 CI/CD 的最大思维转变是什么？
3. 如果你有一个中小型项目，你会选 K3s + ArgoCD 还是 Swarm + Portainer？
