#!/usr/bin/env bash
# =============================================================================
# Day 13 — 安装 ArgoCD 并配置 GitOps
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_FILE="${SCRIPT_DIR}/../kubeconfig-lab.yaml"
export KUBECONFIG="${KUBECONFIG_FILE}"

echo "=================================================================="
echo "  Day 13 — 安装 ArgoCD"
echo "=================================================================="

# ---------- 安装 ArgoCD ----------
echo "Step 1: 创建 argocd namespace 并安装"
kubectl create namespace argocd 2>/dev/null || echo "  namespace argocd 已存在"

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "  等待 ArgoCD 组件就绪（约 2-3 分钟）..."
kubectl wait --for=condition=available \
  --timeout=180s \
  -n argocd \
  deployment/argocd-server

# ---------- 获取初始密码 ----------
echo ""
echo "Step 2: 获取初始管理员密码"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "  初始密码：${ARGOCD_PASSWORD}"
echo "  用户名：admin"

# ---------- 将 argocd-server 改为 NodePort 访问 ----------
echo ""
echo "Step 3: 将 argocd-server 暴露为 NodePort"
kubectl patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "NodePort"}}'

NODE_PORT=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.spec.ports[?(@.port==443)].nodePort}')

SRV1_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || \
  gcloud compute instances describe lab-k3s-server-1 \
    --zone=us-central1-b \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo ""
echo "=================================================================="
echo "✅  ArgoCD 已安装"
echo ""
echo "  访问地址：https://${SRV1_IP}:${NODE_PORT}"
echo "  用户名：admin"
echo "  密码：${ARGOCD_PASSWORD}"
echo ""
echo "📋 接下来部署 GitOps Application："
echo ""
echo "  1. 编辑 argocd/app-whoami.yaml，填写你的 GitHub 仓库地址"
echo "  2. 执行："
echo "     kubectl apply -f ${SCRIPT_DIR}/app-whoami.yaml"
echo ""
echo "  3. 在 ArgoCD UI 中观察同步状态"
echo "  4. 修改 manifests/whoami-deployment.yaml 中的 replicas，推送到 GitHub"
echo "  5. 观察 ArgoCD 自动同步"
echo ""
echo "  ArgoCD CLI（可选）："
echo "     argocd login ${SRV1_IP}:${NODE_PORT} --username admin \\"
echo "       --password '${ARGOCD_PASSWORD}' --insecure"
echo "=================================================================="
