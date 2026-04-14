#!/usr/bin/env bash
# =============================================================================
# Day 6 — Portainer 多主机舰队管理
# 3 台 VM 由你在 GCP Console 手动创建，此脚本负责安装 Docker 和 Portainer
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

MGR="lab-d06-portainer-mgr"
AGENT1="lab-d06-portainer-a1"
AGENT2="lab-d06-portainer-a2"

# Docker 安装脚本（粘贴到 Console 的 Startup script）
DOCKER_STARTUP_CONTENT='#!/bin/bash
curl -fsSL https://get.docker.com | sh
usermod -aG docker microdent
systemctl enable docker
echo "DOCKER INSTALLED" > /dev/console'

echo "=================================================================="
echo "  Day 6 — Portainer 多主机舰队管理"
echo "  需要手动创建 3 台 VM"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 依次创建以下 3 台 VM："
echo "  路径：Compute Engine → VM instances → CREATE INSTANCE"
echo ""
echo "  ┌─ VM 1：Portainer Manager ──────────────────────────────┐"
echo "  │  名称     : lab-d06-portainer-mgr                       │"
echo "  │  区域/带  : us-central1 / us-central1-b               │"
echo "  │  机器类型 : e2-medium（2 vCPU / 4 GB）                  │"
echo "  │  磁盘     : Debian 13，30 GB，Standard persistent disk  │"
echo "  │  网络标签 : lab-fw                                       │"
echo "  │  Labels   : owner=lab, purpose=lab, day=d06, role=manager│"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ VM 2：Portainer Agent 1 ──────────────────────────────┐"
echo "  │  名称     : lab-d06-portainer-a1                        │"
echo "  │  区域/带  : us-central1 / us-central1-b               │"
echo "  │  机器类型 : e2-micro（1 vCPU / 1 GB）                   │"
echo "  │  磁盘     : Debian 13，20 GB，Standard persistent disk  │"
echo "  │  网络标签 : lab-fw                                       │"
echo "  │  Labels   : owner=lab, purpose=lab, day=d06, role=agent │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ VM 3：Portainer Agent 2 ──────────────────────────────┐"
echo "  │  名称     : lab-d06-portainer-a2                        │"
echo "  │  （配置同 Agent 1，名称改为 lab-d06-portainer-a2）       │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ 3 台 VM 都需要填写的 Startup script ─────────────────┐"
echo "  │  Management → Automation → Startup script：            │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "${DOCKER_STARTUP_CONTENT}"
echo ""
echo "💡 体验提示："
echo "   - 连续创建 3 台 VM，感受批量操作的重复性"
echo "   - 观察 3 台 VM 同时处于 Provisioning 状态"
echo "   - 这正是 IaC（Terraform/Pulumi）存在的原因之一"
echo ""
read -rp "✅  3 台 VM 全部显示 Running 后，按 Enter 继续... "

echo ""
print_step 1 "等待所有 VM SSH 就绪"
wait_for_ssh "${MGR}"
wait_for_ssh "${AGENT1}"
wait_for_ssh "${AGENT2}"

print_step 2 "等待 Docker startup script 完成（约 60 秒）"
for vm in "${MGR}" "${AGENT1}" "${AGENT2}"; do
  run_on_vm "${vm}" "until docker info &>/dev/null; do sleep 3; done; echo 'Docker ready on ${vm}'" &
done
wait
echo "  ✓ 所有 VM Docker 已就绪"

print_step 3 "在 ${MGR} 上安装 Portainer Server"
run_on_vm_sudo "${MGR}" "
  docker volume create portainer_data
  docker run -d \
    --name portainer \
    --restart always \
    -p 9000:9000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest
"

print_step 4 "在 Agent VM 上安装 Portainer Agent"
AGENT_CMD="
  docker run -d \
    --name portainer_agent \
    --restart always \
    -p 9001:9001 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    portainer/agent:latest
"
run_on_vm_sudo "${AGENT1}" "${AGENT_CMD}" &
run_on_vm_sudo "${AGENT2}" "${AGENT_CMD}" &
wait

MGR_IP=$(get_vm_external_ip "${MGR}")
A1_IP=$(get_vm_external_ip "${AGENT1}")
A2_IP=$(get_vm_external_ip "${AGENT2}")

echo ""
echo "=================================================================="
echo "✅  Portainer 环境就绪"
echo ""
echo "  Manager IP  : ${MGR_IP}"
echo "  Agent 1 IP  : ${A1_IP}"
echo "  Agent 2 IP  : ${A2_IP}"
echo ""
echo "🌐 访问 Portainer（⚠️ 首次打开需在 5 分钟内设置管理员密码）："
echo "   http://${MGR_IP}:9000"
echo ""
echo "📋 在 Portainer UI 中添加 Agent："
echo "   Settings → Environments → + Add Environment → Agent"
echo "   Agent 1 地址：${A1_IP}:9001"
echo "   Agent 2 地址：${A2_IP}:9001"
echo ""
echo "💡 Console 体验提示："
echo "   - 同时打开 3 台 VM 的监控图表（CPU/网络），对比资源占用"
echo "   - 试试 STOP 其中一台 Agent，观察 Portainer UI 中 Environment 状态变化"
echo "   - 再 START 回来，看 Portainer 能否自动重连"
echo ""
echo "🧹 实验结束后执行："
echo "   bash ${SCRIPT_DIR}/cleanup.sh"
echo "=================================================================="
