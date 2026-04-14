#!/usr/bin/env bash
# =============================================================================
# Day 3 — 生成 Ansible inventory.ini
# 用法：bash create.sh <VM外部IP>
# 例如：bash create.sh 34.89.123.45
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -eq 0 ]]; then
  echo "用法：bash create.sh <VM外部IP>"
  echo "例如：bash create.sh 34.89.123.45"
  echo ""
  echo "VM 的外部 IP 可以在 GCP Console → Compute Engine → VM instances 里找到"
  exit 1
fi

EXTERNAL_IP="$1"
VM_NAME="lab-d03-app"

cat > "${SCRIPT_DIR}/ansible/inventory.ini" << INI
[webserver]
${VM_NAME} ansible_host=${EXTERNAL_IP} ansible_user=microdent ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INI

echo "✓ ansible/inventory.ini 已生成"
echo "  ${VM_NAME} → ${EXTERNAL_IP}"
echo ""
echo "接下来："
echo "  1. 编辑 ansible/group_vars/all.yml，填写你的域名"
echo "  2. cd ${SCRIPT_DIR} && ansible-playbook ansible/playbook.yml"
