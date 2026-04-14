# Day 10-11 — Docker Swarm 集群

## 目标

- **Day 10**：搭建 Docker Swarm 集群，理解集群架构和 overlay 网络
- **Day 11**：运维演练：滚动更新、回滚、节点 drain、服务迁移

## 集群架构

```
Manager (e2-medium，标准 VM)
  ├─ 运行控制面（Raft 状态机）
  ├─ 可以运行有状态服务（数据库、监控）
  └─ 标签：role=manager

Worker × 4 (e2-medium，Spot VM)
  ├─ 运行无状态服务（whoami、web 应用）
  └─ 标签：role=worker
```

## 预估费用

~$3.90（5 台 VM × 16 小时；Spot Worker 约 $0.014/hr vs 标准 $0.067/hr）

## Day 10 — 搭建集群

### 1. 创建 VM

```bash
bash create-vms.sh
```

### 2. 初始化 Swarm

```bash
bash init-swarm.sh
```

### 3. 部署服务

```bash
MGR="lab-swarm-manager"
ZONE="us-central1-b"

# 上传 stack 文件
gcloud compute scp --zone=${ZONE} stacks/whoami-stack.yml ${MGR}:/tmp/
gcloud compute scp --zone=${ZONE} stacks/memos-stack.yml ${MGR}:/tmp/
gcloud compute scp --zone=${ZONE} stacks/monitoring-stack.yml ${MGR}:/tmp/

# 部署 stack
gcloud compute ssh ${MGR} --zone=${ZONE} \
  --command="sudo docker stack deploy -c /tmp/whoami-stack.yml whoami-lab"

gcloud compute ssh ${MGR} --zone=${ZONE} \
  --command="sudo docker stack deploy -c /tmp/memos-stack.yml memos-lab"

gcloud compute ssh ${MGR} --zone=${ZONE} \
  --command="sudo docker stack deploy -c /tmp/monitoring-stack.yml monitor-lab"
```

### 4. 验证服务

```bash
MGR_IP=$(gcloud compute instances describe lab-swarm-manager \
  --zone=us-central1-b \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

# whoami（Routing Mesh — 访问任意节点 IP 都能到达服务）
curl http://${MGR_IP}  # 通过 Traefik

# memos
curl http://${MGR_IP}:3000

# uptime-kuma
echo "http://${MGR_IP}:3001"
```

```bash
# 在 Manager 上查看服务状态
gcloud compute ssh lab-swarm-manager --zone=us-central1-b \
  --command="sudo docker service ls"

gcloud compute ssh lab-swarm-manager --zone=us-central1-b \
  --command="sudo docker service ps whoami-lab_whoami"
```

## Day 11 — 运维演练

### 滚动更新

```bash
SSH="gcloud compute ssh lab-swarm-manager --zone=us-central1-b --command"

# 更新 whoami 服务镜像（触发滚动更新）
${SSH} "sudo docker service update \
  --image traefik/whoami:latest \
  --update-parallelism 1 \
  --update-delay 10s \
  whoami-lab_whoami"

# 查看更新进度
${SSH} "sudo docker service ps whoami-lab_whoami"
```

### 回滚

```bash
# 回滚到上一个版本
${SSH} "sudo docker service rollback whoami-lab_whoami"
```

### 扩缩容

```bash
# 扩容 whoami 到 6 副本
${SSH} "sudo docker service scale whoami-lab_whoami=6"

# 查看副本分布
${SSH} "sudo docker service ps whoami-lab_whoami"
```

### Drain 节点（模拟节点维护）

```bash
# Drain worker-1（服务任务迁移到其他节点）
${SSH} "sudo docker node update --availability drain lab-swarm-worker-1"

# 观察任务迁移
${SSH} "sudo docker service ps whoami-lab_whoami"

# 恢复节点
${SSH} "sudo docker node update --availability active lab-swarm-worker-1"
```

### Routing Mesh 验证

```bash
# 访问任意 Worker 节点的 IP，都能到达服务
for WORKER in lab-swarm-worker-1 lab-swarm-worker-2; do
  W_IP=$(gcloud compute instances describe ${WORKER} \
    --zone=us-central1-b \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
  echo "Worker ${WORKER} (${W_IP}):"
  curl -s http://${W_IP} | grep Hostname
done
```

## 关键概念

### Overlay 网络

Swarm 的 overlay 网络允许跨节点容器通信，使用 VXLAN 封装：

- 服务间通过服务名互联（`postgres`、`memos`）
- 流量加密（`--opt encrypted`）
- 外部访问通过 Routing Mesh 或 Host 模式端口

### Routing Mesh vs Host Mode

| | Routing Mesh（默认）| Host Mode |
|---|---|---|
| 访问方式 | 任意节点 IP | 只有运行任务的节点 |
| 负载均衡 | 内置（IPVS）| 外部 LB |
| 性能 | 略低（NAT）| 更高 |
| 配置 | 简单 | 复杂 |

### 有状态服务的 Placement

数据库类服务应通过 `placement.constraints` 固定到特定节点，避免因 Spot Worker 回收导致数据丢失：

```yaml
placement:
  constraints:
    - node.labels.role == manager
```

## 清理

```bash
bash cleanup.sh
```

## 今天的感受问题

1. Swarm 的 Routing Mesh 和 Nginx 手写负载均衡相比，复杂度差异如何？
2. 有状态服务（数据库）在 Swarm 中部署有什么困难？
3. Swarm 和 K3s（Day 12）的最大区别是什么？你预计会选哪个？
