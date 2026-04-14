#!/usr/bin/env bash
# =============================================================================
# Day 14 — 部署应用到 GKE 和 Cloud Run
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

CLUSTER_NAME="lab-d14-gke"

echo "=================================================================="
echo "  Day 14 — 部署应用"
echo "=================================================================="

# ---------- 确认 kubectl 指向 GKE ----------
print_step 1 "确认 kubectl 上下文"
CURRENT_CTX=$(kubectl config current-context)
echo "  当前 context：${CURRENT_CTX}"

if [[ "${CURRENT_CTX}" != *"${CLUSTER_NAME}"* ]]; then
  print_warn "当前 context 可能不是 GKE 集群，切换中..."
  gcloud container clusters get-credentials "${CLUSTER_NAME}" \
    --region="${REGION}" \
    --project="${PROJECT_ID}"
fi

# ---------- 部署到 GKE（K8s manifests）----------
print_step 2 "部署 whoami 到 GKE"
kubectl apply -f "${SCRIPT_DIR}/manifests/whoami.yaml"

print_step 3 "等待 whoami 就绪（Autopilot 首次 pod 需要 2-3 分钟分配节点）"
echo "  Autopilot 正在按需分配节点，请耐心等待..."
kubectl wait --for=condition=available \
  --timeout=300s \
  deployment/whoami-gke

print_step 4 "获取 GKE whoami 的 LoadBalancer IP"
echo "  等待 LoadBalancer 分配外部 IP（约 1-2 分钟）..."
for i in {1..20}; do
  LB_IP=$(kubectl get svc whoami-gke \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  if [[ -n "${LB_IP}" ]]; then
    echo "  ✓ GKE whoami LB IP：${LB_IP}"
    break
  fi
  echo -n "."
  sleep 10
done

# ---------- 部署到 Cloud Run ----------
print_step 5 "部署 whoami 到 Cloud Run（serverless）"
gcloud run deploy whoami-cloudrun \
  --image="${WHOAMI_IMAGE}" \
  --region="${REGION}" \
  --platform=managed \
  --allow-unauthenticated \
  --port=80 \
  --labels="owner=lab,purpose=lab,day=d14" \
  --project="${PROJECT_ID}"

CR_URL=$(gcloud run services describe whoami-cloudrun \
  --region="${REGION}" \
  --format="get(status.url)" \
  --project="${PROJECT_ID}")

echo ""
echo "=================================================================="
echo "✅  应用部署完成"
echo ""
echo "  GKE whoami（LoadBalancer）：http://${LB_IP:-PENDING}"
echo "  Cloud Run whoami（serverless）：${CR_URL}"
echo ""
echo "📋 对比体验："
echo ""
echo "  1. 压测 Cloud Run（观察冷启动）："
echo "     for i in {1..10}; do curl -w '%{time_total}\\n' -o /dev/null -s ${CR_URL}; done"
echo ""
echo "  2. 查看 GKE Pod 分布（Autopilot 自动调度）："
echo "     kubectl get pods -o wide"
echo ""
echo "  3. 查看 GKE 节点（Autopilot 按需创建）："
echo "     kubectl get nodes"
echo ""
echo "  4. 查看 Cloud Run 监控（请求量、延迟、实例数）："
echo "     gcloud run services describe whoami-cloudrun --region=${REGION}"
echo ""
echo "🧹 实验结束后务必清理（GKE + Cloud Run 都在计费）："
echo "   bash ${SCRIPT_DIR}/cleanup.sh"
echo "=================================================================="
