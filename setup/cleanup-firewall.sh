#!/usr/bin/env bash
# =============================================================================
# setup/cleanup-firewall.sh — 删除实验防火墙规则
# 仅在 14 天全部结束后执行
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

FW_RULES=(
  "lab-allow-web"
  "lab-allow-ssh"
  "lab-allow-cluster"
  "lab-allow-healthcheck"
)

echo "=================================================================="
echo "  删除实验防火墙规则"
echo "=================================================================="
echo ""

for rule in "${FW_RULES[@]}"; do
  if gcloud compute firewall-rules describe "${rule}" --quiet 2>/dev/null; then
    echo "  删除 ${rule} ..."
    gcloud compute firewall-rules delete "${rule}" --quiet
    echo "  ✓ 已删除"
  else
    print_warn "${rule} 不存在，跳过"
  fi
done

echo ""
echo "✅  防火墙规则已清理"
