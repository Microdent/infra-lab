#!/usr/bin/env bash
# =============================================================================
# Day 3 — 清理本地生成文件
# VM 在 GCP Console 手动删除：Compute Engine → VM instances → lab-d03-app → DELETE
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📋 请在 GCP Console 删除 VM："
echo "  Compute Engine → VM instances → 勾选 lab-d03-app → DELETE"
echo "  勾选 Also delete boot disk"
echo ""

# 清理本地生成的 inventory（包含 IP，不提交到 git）
if [[ -f "${SCRIPT_DIR}/ansible/inventory.ini" ]]; then
  rm "${SCRIPT_DIR}/ansible/inventory.ini"
  echo "✓ ansible/inventory.ini 已删除"
fi
