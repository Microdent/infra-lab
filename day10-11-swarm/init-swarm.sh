#!/usr/bin/env bash
# =============================================================================
# Day 10 — 初始化 Docker Swarm 集群
# 用内网 IP 通信，保证集群流量不走公网
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

MGR="lab-swarm-manager"
WORKERS=("lab-swarm-worker-1" "lab-swarm-worker-2" "lab-swarm-worker-3" "lab-swarm-worker-4")

echo "=================================================================="
echo "  初始化 Docker Swarm 集群"
echo "=================================================================="

# ---------- 等待 Docker 在所有节点安装完成 ----------
print_step 1 "等待 Docker 在所有节点就绪"
run_on_vm "${MGR}" "until docker info &>/dev/null; do sleep 2; done; echo 'Docker ready'"
for worker in "${WORKERS[@]}"; do
  run_on_vm "${worker}" "until docker info &>/dev/null; do sleep 2; done" &
done
wait
echo "  ✓ 所有节点 Docker 就绪"

# ---------- 获取 Manager 内网 IP ----------
MGR_INTERNAL_IP=$(get_vm_internal_ip "${MGR}")
echo "  Manager 内网 IP：${MGR_INTERNAL_IP}"

# ---------- 初始化 Swarm（在 Manager 上）----------
print_step 2 "初始化 Swarm（advertise-addr 使用内网 IP）"
run_on_vm "${MGR}" "
  docker swarm init --advertise-addr ${MGR_INTERNAL_IP} || echo 'Swarm already initialized'
"

# ---------- 获取 Join Token ----------
print_step 3 "获取 Worker Join Token"
JOIN_TOKEN=$(run_on_vm "${MGR}" "docker swarm join-token worker -q" | tr -d '[:space:]')
echo "  Join Token：${JOIN_TOKEN}"

# ---------- Workers 加入 Swarm ----------
print_step 4 "将所有 Worker 加入 Swarm（并行）"
for worker in "${WORKERS[@]}"; do
  run_on_vm "${worker}" "
    docker swarm join \
      --token ${JOIN_TOKEN} \
      ${MGR_INTERNAL_IP}:2377 \
    || echo 'Already in swarm'
  " &
done
wait

# ---------- 给 Worker 打标签 ----------
print_step 5 "给节点打标签"
run_on_vm "${MGR}" "
  docker node update --label-add role=worker lab-swarm-worker-1
  docker node update --label-add role=worker lab-swarm-worker-2
  docker node update --label-add role=worker lab-swarm-worker-3
  docker node update --label-add role=worker lab-swarm-worker-4
  docker node update --label-add role=manager lab-swarm-manager
"

# ---------- 验证 ----------
print_step 6 "验证集群状态"
run_on_vm "${MGR}" "docker node ls"

MGR_IP=$(get_vm_external_ip "${MGR}")

echo ""
echo "=================================================================="
echo "✅  Swarm 集群初始化完成"
echo ""
echo "  Manager 外网 IP：${MGR_IP}"
echo ""
echo "📋 接下来部署服务："
echo ""
echo "  1. 部署 whoami（3 副本，自动分布到 worker）："
echo "     gcloud compute ssh ${MGR} --zone=${ZONE} \\"
echo "       --command='sudo docker stack deploy -c /tmp/whoami-stack.yml whoami-lab'"
echo ""
echo "  或先上传 stack 文件再部署："
echo "     bash ${SCRIPT_DIR}/../lib/../day10-11-swarm/deploy-stacks.sh"
echo ""
echo "  2. 查看服务状态："
echo "     gcloud compute ssh ${MGR} --zone=${ZONE} --command='docker service ls'"
echo "=================================================================="
