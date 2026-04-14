#!/usr/bin/env bash
# =============================================================================
# Day 12 — 安装 K3s HA 集群
# server-1: 主节点（cluster-init）
# server-2: 加入主节点
# agents: 通过内部 LB 加入
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

SRV1="lab-k3s-server-1"
SRV2="lab-k3s-server-2"
AGENTS=("lab-k3s-agent-1" "lab-k3s-agent-2" "lab-k3s-agent-3")
FWD_NAME="lab-k3s-fwd"

echo "=================================================================="
echo "  初始化 K3s HA 集群"
echo "=================================================================="

# ---------- 获取 IP ----------
SRV1_INT=$(get_vm_internal_ip "${SRV1}")
SRV1_EXT=$(get_vm_external_ip "${SRV1}")

LB_IP=$(gcloud compute forwarding-rules describe "${FWD_NAME}" \
  --region="${REGION}" \
  --format="get(IPAddress)")

echo "  Server-1 内网 IP：${SRV1_INT}"
echo "  内部 LB IP：${LB_IP}"

# ---------- 安装 K3s Server-1（主节点，cluster-init）----------
print_step 1 "安装 K3s Server-1（--cluster-init，启用 HA 嵌入式 etcd）"
run_on_vm_sudo "${SRV1}" "
  curl -sfL https://get.k3s.io | sh -s - server \
    --cluster-init \
    --tls-san ${LB_IP} \
    --tls-san ${SRV1_INT} \
    --tls-san ${SRV1_EXT} \
    --disable traefik \
    --node-label role=server
"

# ---------- 等待 K3s Server-1 就绪 ----------
print_step 2 "等待 K3s Server-1 就绪"
run_on_vm "${SRV1}" "
  until kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes &>/dev/null; do
    echo 'waiting for k3s...'
    sleep 5
  done
  echo 'K3s server-1 ready'
"

# ---------- 获取 K3s Join Token ----------
print_step 3 "获取 K3s Join Token"
K3S_TOKEN=$(run_on_vm_sudo "${SRV1}" "cat /var/lib/rancher/k3s/server/node-token" | tr -d '[:space:]')
echo "  Token 已获取（前 20 字符）：${K3S_TOKEN:0:20}..."

# ---------- 安装 K3s Server-2 ----------
print_step 4 "安装 K3s Server-2（加入集群）"
run_on_vm_sudo "${SRV2}" "
  curl -sfL https://get.k3s.io | sh -s - server \
    --server https://${SRV1_INT}:6443 \
    --token ${K3S_TOKEN} \
    --tls-san ${LB_IP} \
    --disable traefik \
    --node-label role=server
"

# ---------- 安装 K3s Agents ----------
print_step 5 "安装 K3s Agents（通过内部 LB 加入，并行）"
for agent in "${AGENTS[@]}"; do
  run_on_vm_sudo "${agent}" "
    curl -sfL https://get.k3s.io | sh -s - agent \
      --server https://${LB_IP}:6443 \
      --token ${K3S_TOKEN} \
      --node-label role=agent
  " &
done
wait
echo "  ✓ 所有 Agents 安装完成"

# ---------- 下载 kubeconfig ----------
print_step 6 "下载 kubeconfig 到本地"
KUBECONFIG_LOCAL="${SCRIPT_DIR}/kubeconfig-lab.yaml"

copy_from_vm "${SRV1}" "/etc/rancher/k3s/k3s.yaml" "${KUBECONFIG_LOCAL}"

# 替换 kubeconfig 中的 server 地址（127.0.0.1 → Server-1 外网 IP）
sed -i.bak "s|https://127.0.0.1:6443|https://${SRV1_EXT}:6443|g" "${KUBECONFIG_LOCAL}"
chmod 600 "${KUBECONFIG_LOCAL}"
echo "  ✓ kubeconfig 已保存到 ${KUBECONFIG_LOCAL}"

# ---------- 部署 Traefik Ingress Controller ----------
print_step 7 "部署 Traefik Ingress Controller"
KUBECONFIG="${KUBECONFIG_LOCAL}" kubectl apply -f \
  https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd.yml 2>/dev/null || true

# ---------- 验证集群 ----------
print_step 8 "验证集群节点状态"
KUBECONFIG="${KUBECONFIG_LOCAL}" kubectl get nodes -o wide

echo ""
echo "=================================================================="
echo "✅  K3s HA 集群初始化完成"
echo ""
echo "  使用方式："
echo "  export KUBECONFIG=${KUBECONFIG_LOCAL}"
echo "  kubectl get nodes"
echo ""
echo "📋 接下来部署应用："
echo "   kubectl apply -f ${SCRIPT_DIR}/manifests/"
echo ""
echo "📋 Day 13：安装 ArgoCD（GitOps）："
echo "   bash ${SCRIPT_DIR}/argocd/install.sh"
echo "=================================================================="
