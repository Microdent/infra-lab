#!/usr/bin/env bash
# =============================================================================
# Day 5 — 销毁 Pulumi 创建的所有资源
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo "=================================================================="
echo "  Day 5 — Pulumi destroy"
echo "=================================================================="

pulumi destroy --yes --stack dev

echo ""
echo "✅  Day 5 资源已销毁"
echo ""
echo "验证："
echo "  pulumi stack --stack dev  # 查看栈状态"
