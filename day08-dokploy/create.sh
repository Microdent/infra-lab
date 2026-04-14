#!/usr/bin/env bash
# =============================================================================
# Day 8 — Dokploy PaaS
# VM 由你在 GCP Console 手动创建，此脚本负责安装 Dokploy
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

VM_NAME="lab-d08-dokploy"

echo "=================================================================="
echo "  Day 8 — Dokploy PaaS"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 创建 VM，配置如下："
echo ""
echo "  ┌─ 基础配置 ─────────────────────────────────────────────┐"
echo "  │  名称        : lab-d08-dokploy                          │"
echo "  │  区域        : us-central1 / us-central1-b            │"
echo "  │  机器类型    : e2-medium（2 vCPU / 4 GB）               │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ 启动磁盘 ─────────────────────────────────────────────┐"
echo "  │  OS：Debian 13，30 GB，Standard persistent disk         │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ 网络标签 / Labels ─────────────────────────────────────┐"
echo "  │  Network tags : lab-fw                                  │"
echo "  │  Labels       : owner=lab, purpose=lab, day=d08         │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "💡 体验提示：对比 Day 7 的 e2-standard-2，今天用 e2-medium 够吗？"
echo "   Dokploy 比 Coolify 更轻量，e2-medium 应该足够"
echo ""
read -rp "✅  VM 显示 Running 后，按 Enter 继续... "

echo ""
print_step 1 "读取 VM 公网 IP"
VM_IP=$(get_vm_external_ip "${VM_NAME}")
echo "  外部 IP：${VM_IP}"

print_step 2 "等待 SSH 就绪"
wait_for_ssh "${VM_NAME}"

print_step 3 "安装 Dokploy"
run_on_vm_sudo "${VM_NAME}" "curl -sSL https://dokploy.com/install.sh | sh"

echo ""
echo "=================================================================="
echo "✅  Dokploy 安装完成"
echo ""
echo "  VM IP：${VM_IP}"
echo ""
echo "🌐 访问 Dokploy（安装后约 1-2 分钟）："
echo "   http://${VM_IP}:3000"
echo ""
echo "🧹 实验结束后执行："
echo "   bash ${SCRIPT_DIR}/cleanup.sh"
echo "=================================================================="
