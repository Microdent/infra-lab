#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

echo "=================================================================="
echo "  Day 10-11 — 清理 Swarm 集群资源（5 台 VM）"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 删除以下 5 台 VM："
echo "  Compute Engine → VM instances"
echo "  同时勾选全部，再点 DELETE："
echo ""
echo "    ☐ lab-swarm-manager"
echo "    ☐ lab-swarm-worker-1"
echo "    ☐ lab-swarm-worker-2"
echo "    ☐ lab-swarm-worker-3"
echo "    ☐ lab-swarm-worker-4"
echo ""
echo "  ⚠️  删除时勾选 "Delete boot disk""
echo "  ⚠️  Spot Worker 可能已被 GCP 回收，列表中不存在是正常的"
echo ""
read -rp "✅  VM 已删除后，按 Enter 验证... "
echo ""

ALL_VMS=("lab-swarm-manager" "lab-swarm-worker-1" "lab-swarm-worker-2" "lab-swarm-worker-3" "lab-swarm-worker-4")
for vm in "${ALL_VMS[@]}"; do
  if gcloud compute instances describe "${vm}" \
      --zone="${ZONE}" --quiet 2>/dev/null; then
    print_warn "${vm} 仍然存在"
  else
    echo "  ✓ ${vm} 已不存在（或已被 GCP 回收）"
  fi
done

echo ""
echo "✅  Day 10-11 资源清理完成"
