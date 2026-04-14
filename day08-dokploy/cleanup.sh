#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

echo "=================================================================="
echo "  Day 8 — 清理资源"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 删除 VM："
echo "  Compute Engine → VM instances → 勾选 lab-d08-dokploy → DELETE"
echo ""
read -rp "✅  VM 已删除后，按 Enter 验证... "

if gcloud compute instances describe "lab-d08-dokploy" \
    --zone="${ZONE}" --quiet 2>/dev/null; then
  print_warn "VM 仍然存在"
else
  echo "  ✓ lab-d08-dokploy 已不存在"
  echo "✅  Day 8 资源清理完成"
fi
