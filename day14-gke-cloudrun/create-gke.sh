#!/usr/bin/env bash
# =============================================================================
# Day 14 — GKE Autopilot 集群创建指引
# 集群由你在 GCP Console 手动创建，此脚本负责获取凭据和验证
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

CLUSTER_NAME="lab-d14-gke"

echo "=================================================================="
echo "  Day 14 — GKE Autopilot 集群"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 创建 GKE Autopilot 集群："
echo ""
echo "  路径：Kubernetes Engine → Clusters → CREATE"
echo "         选择 Autopilot（不是 Standard）"
echo ""
echo "  ┌─ 基础配置 ─────────────────────────────────────────────┐"
echo "  │  集群名称    : lab-d14-gke                              │"
echo "  │  区域        : us-central1  │"
echo "  │              Autopilot 是区域级（多可用区），不是单区   │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ Networking（可保持默认）──────────────────────────────┐"
echo "  │  Network     : default                                  │"
echo "  │  Node subnet : default                                  │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ Labels（Advanced options → Labels）──────────────────┐"
echo "  │  owner   = lab                                          │"
echo "  │  purpose = lab                                          │"
echo "  │  day     = d14                                          │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "💡 体验提示："
echo "   - 注意 Autopilot 创建页面和 Standard 的差异（节点配置不可选）"
echo "   - 观察 Console 上集群状态从 Provisioning → Running（需 3-5 分钟）"
echo "   - 看 Autopilot 的定价说明：按 Pod 计费，不按节点"
echo ""
echo "  ⚠️  费用提醒："
echo "   - GKE Autopilot 集群管理费（前 1 个/月免费）"
echo "   - Pod 计算费按实际使用量计费"
echo "   - 预计半天费用 \$3-6，实验结束立即删除"
echo ""
read -rp "✅  集群状态显示 Running 后，按 Enter 继续... "

echo ""
print_step 1 "获取集群凭据（更新本地 kubeconfig）"
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}"

print_step 2 "验证集群连接"
kubectl get nodes

echo ""
echo "=================================================================="
echo "✅  GKE Autopilot 集群已就绪"
echo ""
echo "  当前 kubectl context 已切换到 GKE 集群"
echo ""
echo "📋 接下来部署应用："
echo "   bash ${SCRIPT_DIR}/deploy-apps.sh"
echo ""
echo "💡 Console 体验提示："
echo "   - Kubernetes Engine → Workloads：查看 Pod 调度状态"
echo "   - Kubernetes Engine → Services & Ingress：查看 LoadBalancer IP 分配"
echo "   - Kubernetes Engine → Nodes：Autopilot 的节点由 GKE 管理，你不拥有它们"
echo ""
echo "🧹 实验结束后务必执行（GKE 按小时计费）："
echo "   bash ${SCRIPT_DIR}/cleanup.sh"
echo "=================================================================="
