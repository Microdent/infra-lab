#!/usr/bin/env bash
# =============================================================================
# Day 10 — Docker Swarm 集群 VM 创建指引
# 5 台 VM 由你在 GCP Console 手动创建，此脚本负责等待就绪并输出汇总
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

MGR="lab-swarm-manager"
WORKERS=("lab-swarm-worker-1" "lab-swarm-worker-2" "lab-swarm-worker-3" "lab-swarm-worker-4")

# 所有节点统一的 Docker 安装 startup script
DOCKER_STARTUP='#!/bin/bash
curl -fsSL https://get.docker.com | sh
usermod -aG docker microdent
systemctl enable docker
echo "DOCKER INSTALLED" > /dev/console'

echo "=================================================================="
echo "  Day 10 — Docker Swarm 集群"
echo "  需要手动创建 5 台 VM（1 Manager + 4 Workers）"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 依次创建以下 VM："
echo "  路径：Compute Engine → VM instances → CREATE INSTANCE"
echo ""
echo "  ┌─ VM 1：Swarm Manager（标准 VM，不要用 Spot）──────────┐"
echo "  │  名称        : lab-swarm-manager                        │"
echo "  │  区域        : us-central1 / us-central1-b            │"
echo "  │  机器类型    : e2-medium（2 vCPU / 4 GB）               │"
echo "  │  磁盘        : Debian 13，20 GB，Standard               │"
echo "  │  网络标签    : lab-fw                                    │"
echo "  │  Labels      : owner=lab, purpose=lab, day=d10, role=manager│"
echo "  │  VM provisioning model : Standard（默认）               │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ VM 2-5：Swarm Workers（使用 Spot VM 节省费用）────────┐"
echo "  │  名称        : lab-swarm-worker-1（到 worker-4，各一台）│"
echo "  │  区域        : us-central1 / us-central1-b            │"
echo "  │  机器类型    : e2-medium（2 vCPU / 4 GB）               │"
echo "  │  磁盘        : Debian 13，20 GB，Standard               │"
echo "  │  网络标签    : lab-fw                                    │"
echo "  │  Labels      : owner=lab, purpose=lab, day=d10, role=worker│"
echo "  │                                                          │"
echo "  │  ⚡ Spot VM 设置路径：                                   │"
echo "  │     Availability policies → VM provisioning model       │"
echo "  │     选择 Spot（preemptible）                             │"
echo "  │     On VM termination → Stop                            │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ 所有 5 台 VM 都需要填写的 Startup script ────────────┐"
echo "  │  Management → Automation → Startup script：            │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "${DOCKER_STARTUP}"
echo ""
echo "💡 体验提示："
echo "   - 创建 Spot VM 时，注意价格提示和标准 VM 价格的对比"
echo "   - 观察 Spot VM 的图标在 VM 列表中和标准 VM 的区别"
echo "   - Worker 的 Spot 标识说明 GCP 可能随时回收它们"
echo ""
read -rp "✅  5 台 VM 全部显示 Running 后，按 Enter 继续... "

echo ""
print_step 1 "等待所有 VM SSH 就绪"
wait_for_ssh "${MGR}"
for worker in "${WORKERS[@]}"; do
  wait_for_ssh "${worker}" &
done
wait

print_step 2 "等待所有 VM 上的 Docker startup script 完成"
for vm in "${MGR}" "${WORKERS[@]}"; do
  run_on_vm "${vm}" "until docker info &>/dev/null; do sleep 3; done; echo 'Docker ready'" &
done
wait
echo "  ✓ 所有节点 Docker 就绪"

# ---------- 汇总各节点 IP ----------
print_step 3 "汇总节点 IP"
MGR_IP=$(get_vm_external_ip "${MGR}")
MGR_INT=$(get_vm_internal_ip "${MGR}")

echo ""
echo "=================================================================="
echo "✅  所有 VM 就绪"
echo ""
printf "  %-26s %-18s %-18s\n" "VM 名称" "外网 IP" "内网 IP"
printf "  %-26s %-18s %-18s\n" "──────────────────────────" "──────────────────" "──────────────────"
printf "  %-26s %-18s %-18s\n" "${MGR}（Manager）" "${MGR_IP}" "${MGR_INT}"
for worker in "${WORKERS[@]}"; do
  W_EXT=$(get_vm_external_ip "${worker}")
  W_INT=$(get_vm_internal_ip "${worker}")
  printf "  %-26s %-18s %-18s\n" "${worker}（Worker）" "${W_EXT}" "${W_INT}"
done
echo ""
echo "  ⚠️  Swarm 集群内通信使用内网 IP，记录好 Manager 内网 IP"
echo "     Manager 内网 IP：${MGR_INT}"
echo ""
echo "📋 接下来初始化 Swarm："
echo "   bash ${SCRIPT_DIR}/init-swarm.sh"
echo ""
echo "💡 Console 体验提示："
echo "   - 打开 Manager 的 Monitoring 标签页，保持窗口"
echo "   - 后续部署服务后观察 CPU/网络流量的变化"
echo "=================================================================="
