#!/usr/bin/env bash
# =============================================================================
# Day 14 — 清理
# GKE 集群：GCP Console 手动删除
# Cloud Run 服务：脚本删除（命令更简洁）
# K8s 资源（LB 等）：脚本删除
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

CLUSTER_NAME="lab-d14-gke"

echo "=================================================================="
echo "  Day 14 — 清理 GKE 和 Cloud Run 资源"
echo "  ⚠️  这是今天费用最高的资源，务必完成清理！"
echo "=================================================================="
echo ""
echo "📋 【第一步】先删除 K8s 资源（释放 GCP LoadBalancer，否则 LB 继续计费）"
echo ""
if kubectl config current-context 2>/dev/null | grep -q "${CLUSTER_NAME}"; then
  echo "  正在删除 K8s 资源..."
  kubectl delete -f "${SCRIPT_DIR}/manifests/" --ignore-not-found=true 2>/dev/null || true
  echo "  等待 LoadBalancer 资源释放（约 30 秒）..."
  sleep 30
  echo "  ✓ K8s 资源已删除"
else
  print_warn "kubectl 未指向 GKE 集群，跳过 K8s 资源删除"
  echo "  如需手动删除：kubectl delete -f ${SCRIPT_DIR}/manifests/"
fi

echo ""
echo "📋 【第二步】请在 GCP Console 删除 GKE 集群："
echo ""
echo "  路径：Kubernetes Engine → Clusters"
echo "  点击 lab-d14-gke 旁边的 ⋮ → Delete"
echo "  或勾选集群 → DELETE"
echo ""
echo "  ⚠️  GKE 删除需要 3-5 分钟，等待完成再关闭页面"
echo "  ⚠️  注意 Console 的删除确认弹窗（需输入集群名称确认）"
echo ""
echo "💡 体验提示：GKE 删除确认比删除 VM 多一个"输入名称"步骤，"
echo "   这是 GKE 防止误删生产集群的保护机制"
echo ""
read -rp "✅  GKE 集群已删除后，按 Enter 继续清理 Cloud Run... "
echo ""

print_step 1 "删除 Cloud Run 服务"
gcloud run services delete "whoami-cloudrun" \
  --region="${REGION}" \
  --quiet \
  --project="${PROJECT_ID}" 2>/dev/null \
  && echo "  ✓ Cloud Run 服务已删除" \
  || print_warn "Cloud Run 服务不存在或已删除"

print_step 2 "验证清理完成"
echo ""
echo "  检查 GKE 集群..."
if gcloud container clusters describe "${CLUSTER_NAME}" \
    --region="${REGION}" --quiet 2>/dev/null; then
  print_warn "GKE 集群仍然存在，请确认删除"
else
  echo "  ✓ GKE 集群已不存在"
fi

echo ""
echo "  检查 Cloud Run 服务..."
CR_EXISTS=$(gcloud run services list \
  --region="${REGION}" \
  --filter="metadata.name=whoami-cloudrun" \
  --format="get(metadata.name)" 2>/dev/null || true)
if [[ -n "${CR_EXISTS}" ]]; then
  print_warn "Cloud Run 服务仍然存在"
else
  echo "  ✓ Cloud Run 服务已不存在"
fi

echo ""
echo "=================================================================="
echo "✅  Day 14 资源清理完成"
echo "=================================================================="
