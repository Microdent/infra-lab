#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

echo "=================================================================="
echo "  Day 6 — 清理资源（3 台 VM）"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 删除以下 3 台 VM："
echo "  Compute Engine → VM instances"
echo "  同时勾选以下 3 台，再点 DELETE："
echo ""
echo "    ☐ lab-d06-portainer-mgr"
echo "    ☐ lab-d06-portainer-a1"
echo "    ☐ lab-d06-portainer-a2"
echo ""
echo "  ⚠️  删除时勾选 "Delete boot disk""
echo ""
echo "💡 体验提示：批量删除和逐个删除的 Console 操作有什么区别？"
echo ""
read -rp "✅  3 台 VM 已删除后，按 Enter 验证... "
echo ""

for vm in "lab-d06-portainer-mgr" "lab-d06-portainer-a1" "lab-d06-portainer-a2"; do
  if gcloud compute instances describe "${vm}" \
      --zone="${ZONE}" --quiet 2>/dev/null; then
    print_warn "${vm} 仍然存在"
  else
    echo "  ✓ ${vm} 已不存在"
  fi
done

echo ""
echo "✅  Day 6 资源清理完成"
