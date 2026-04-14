#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

echo "=================================================================="
echo "  Day 7 — 清理资源"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 删除 VM："
echo "  Compute Engine → VM instances → 勾选 lab-d07-coolify → DELETE"
echo "  删除时勾选 "Delete boot disk""
echo ""
read -rp "✅  VM 已删除后，按 Enter 验证... "

if gcloud compute instances describe "lab-d07-coolify" \
    --zone="${ZONE}" --quiet 2>/dev/null; then
  print_warn "VM 仍然存在，请回到 Console 确认删除"
else
  echo "  ✓ lab-d07-coolify 已不存在"
  echo "✅  Day 7 资源清理完成"
fi
