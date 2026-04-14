# Day 14 — GKE Autopilot + Cloud Run（托管层）

## 目标

- 对比**自管 K3s**（Day 12）和 **GKE Autopilot**（托管 K8s）的体验差异
- 体验 **Cloud Run** Serverless 部署（冷启动、按请求计费）
- 理解"平台为你做什么 / 你负责什么"的边界在哪里
- 感受 Autopilot 的**按 Pod 计费**模型

## ⚠️ 费用说明

今天是 14 天中**费用最高**的一天：

| 资源 | 费用 |
|------|------|
| GKE Autopilot 集群管理费 | 每月 1 个免费（按月抵扣） |
| Pod 计算费（运行期间）| ~$0.003/vCPU-hr，~$0.0004/GB-hr |
| Cloud Run | 极低，免费额度足够实验 |
| GCP L4 LoadBalancer | ~$0.025/hr |
| **预估半天总费用** | **$4-8** |

**实验结束立即执行 `cleanup.sh`！**

## 执行步骤

### 上半天：GKE Autopilot

#### 1. 创建集群

```bash
bash create-gke.sh
```

需要 3-5 分钟。

#### 2. 部署应用

```bash
bash deploy-apps.sh
```

**首次部署注意**：Autopilot 需要时间分配节点（`Pending` 状态可能持续 2-3 分钟），这是正常现象。

```bash
# 观察 pod 启动过程
kubectl get pods -w
kubectl describe pod whoami-gke-xxx  # 查看事件
```

#### 3. 探索 GKE 特性

```bash
# 查看 GKE 节点（Autopilot 按需创建）
kubectl get nodes -o wide

# 注意：Autopilot 不暴露节点给用户（节点是 Google 管理的）
# 对比 K3s 你可以 SSH 进任何节点

# 查看 Storage Class（GCP Persistent Disk，对比 K3s 的 local-path）
kubectl get storageclass

# 查看 LB IP 的分配
kubectl get svc whoami-gke -w

# 测试自动扩缩容
kubectl scale deployment whoami-gke --replicas=5
kubectl get pods -o wide  # 观察分布
```

### 下半天：Cloud Run

#### 4. Cloud Run 基础体验

```bash
CR_URL=$(gcloud run services describe whoami-cloudrun \
  --region=us-central1 --format="get(status.url)")

# 正常访问
curl ${CR_URL}

# 测试冷启动（minScale=0 时，一段时间不访问后实例会缩到 0）
sleep 300  # 等待 5 分钟
time curl ${CR_URL}  # 首次请求会有冷启动延迟（约 1-2 秒）
```

#### 5. 查看 Cloud Run 监控

```bash
# 查看实例指标
gcloud run services describe whoami-cloudrun --region=us-central1

# 压测并观察实例扩缩
for i in {1..50}; do
  curl -s ${CR_URL} &
done
wait

# 查看并发实例数（需要几秒传播）
gcloud run revisions list --service=whoami-cloudrun --region=us-central1
```

#### 6. 使用 YAML 方式部署

```bash
# 修改 cloudrun/service.yaml 后
gcloud run services replace cloudrun/service.yaml \
  --region=us-central1
```

### 清理（必须！）

```bash
bash cleanup.sh
```

## GKE Autopilot vs Standard vs K3s

| 维度 | GKE Autopilot | GKE Standard | K3s（自管）|
|------|--------------|--------------|-----------|
| 控制面 | Google 完全管理 | Google 管理 | 你管理 |
| 节点 | Google 管理 | 你管理节点池 | 你管理 |
| 计费模式 | 按 Pod 资源 | 按节点 | 按 VM |
| 节点 SSH | 不可以 | 可以 | 可以 |
| 安全加固 | 自动（GKE Sandbox）| 需手动 | 需手动 |
| 升级 | 全自动 | 可配置 | 手动 |
| 灵活性 | 最低 | 中 | 最高 |
| 适合场景 | 生产、快速上线 | 精细控制 | 学习、小团队 |

## Cloud Run vs K8s Deployment

| 维度 | Cloud Run | K8s Deployment |
|------|-----------|---------------|
| 计费 | 按请求/资源秒 | 持续（Pod 运行就计费）|
| 冷启动 | 有（minScale=0 时）| 无（Pod 始终运行）|
| 有状态服务 | 不适合 | 适合（StatefulSet）|
| 长连接 / WebSocket | 支持（有限）| 完全支持 |
| 自动扩缩 | 0~N（完全自动）| HPA（需配置）|
| 配置复杂度 | 低 | 高 |
| 适合场景 | 无状态 API、事件处理 | 任意 |

## GCP Storage Class 对比（重要！）

Day 12（K3s）使用 `local-path`，Day 14（GKE）使用 GCP Persistent Disk：

```bash
# 查看 GKE 存储类
kubectl get storageclass

# standard-rwo    — pd-balanced（默认，推荐）
# premium-rwo     — pd-ssd（高性能，贵）
# standard        — pd-standard（便宜，慢）
```

GCP PD 的关键优势：Pod 可以调度到任意节点，磁盘跟随 Pod 重新挂载（local-path 不行）。

## 今天的感受问题

1. GKE Autopilot 的"不需要管节点"对你来说是解脱还是失控？
2. Cloud Run 的按请求计费，对什么样的应用最有吸引力？
3. 经过 14 天，你会选择哪条路线作为长期基础？为什么？
