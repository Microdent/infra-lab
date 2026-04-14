#!/usr/bin/env bash
# =============================================================================
# Day 12-13 — 清理
# VM：GCP Console 手动删除
# LB 相关资源：脚本删除（Console 操作过于繁琐）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

echo "=================================================================="
echo "  Day 12-13 — 清理 K3s 集群资源"
echo "=================================================================="
echo ""
echo "📋 【第一步】请在 GCP Console 删除以下 5 台 VM："
echo "  Compute Engine → VM instances"
echo "  同时勾选全部，再点 DELETE（勾选 Delete boot disk）："
echo ""
echo "    ☐ lab-k3s-server-1"
echo "    ☐ lab-k3s-server-2"
echo "    ☐ lab-k3s-agent-1"
echo "    ☐ lab-k3s-agent-2"
echo "    ☐ lab-k3s-agent-3"
echo ""
echo "  ⚠️  Spot Agent 可能已被 GCP 回收，列表中不存在是正常的"
echo ""
read -rp "✅  VM 已删除后，按 Enter 继续清理 LB 资源... "
echo ""

print_step 1 "删除内部 LB 资源（转发规则 → 后端服务 → 实例组 → 健康检查）"

gcloud compute forwarding-rules delete "lab-k3s-fwd" \
  --region="${REGION}" --quiet 2>/dev/null && echo "  ✓ 转发规则已删除" || print_warn "转发规则不存在"

gcloud compute backend-services delete "lab-k3s-backend" \
  --region="${REGION}" --quiet 2>/dev/null && echo "  ✓ 后端服务已删除" || print_warn "后端服务不存在"

gcloud compute instance-groups unmanaged delete "lab-k3s-backend-ig" \
  --zone="${ZONE}" --quiet 2>/dev/null && echo "  ✓ 实例组已删除" || print_warn "实例组不存在"

gcloud compute health-checks delete "lab-k3s-hc" \
  --global --quiet 2>/dev/null && echo "  ✓ 健康检查已删除" || print_warn "健康检查不存在"

print_step 2 "清理本地 kubeconfig"
if [[ -f "${SCRIPT_DIR}/kubeconfig-lab.yaml" ]]; then
  rm "${SCRIPT_DIR}/kubeconfig-lab.yaml"
  rm -f "${SCRIPT_DIR}/kubeconfig-lab.yaml.bak"
  echo "  ✓ 本地 kubeconfig 已删除"
fi

echo ""
echo "✅  Day 12-13 资源清理完成"
echo ""
echo "验证 VM 状态："
for vm in "lab-k3s-server-1" "lab-k3s-server-2" "lab-k3s-agent-1" "lab-k3s-agent-2" "lab-k3s-agent-3"; do
  if gcloud compute instances describe "${vm}" \
      --zone="${ZONE}" --quiet 2>/dev/null; then
    print_warn "${vm} 仍然存在"
  else
    echo "  ✓ ${vm} 已不存在"
  fi
done
