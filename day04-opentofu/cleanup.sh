#!/usr/bin/env bash
# =============================================================================
# Day 4 — 销毁 OpenTofu 创建的所有资源
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "  Day 4 — OpenTofu destroy"
echo "=================================================================="

cd "${SCRIPT_DIR}"

if [[ ! -f "terraform.tfvars" ]]; then
  echo "❌ 未找到 terraform.tfvars，请先复制 terraform.tfvars.example 并填写"
  exit 1
fi

tofu destroy -auto-approve

echo ""
echo "✅  Day 4 资源已销毁"
echo ""
echo "验证："
echo "  tofu show  # 应为空"
