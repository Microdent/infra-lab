#!/usr/bin/env bash
# =============================================================================
# Day 12 — K3s HA 集群 VM 创建指引 + 内部 LB（脚本创建）
# 5 台 VM 由你在 GCP Console 手动创建
# 内部 TCP 负载均衡器通过 gcloud 脚本创建（Console 操作过于繁琐）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

SRV1="lab-k3s-server-1"
SRV2="lab-k3s-server-2"
AGENTS=("lab-k3s-agent-1" "lab-k3s-agent-2" "lab-k3s-agent-3")
HC_NAME="lab-k3s-hc"
BS_NAME="lab-k3s-backend"
FWD_NAME="lab-k3s-fwd"

echo "=================================================================="
echo "  Day 12 — K3s HA 集群"
echo "  需要手动创建 5 台 VM（2 Server + 3 Agent）"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 创建以下 VM："
echo "  路径：Compute Engine → VM instances → CREATE INSTANCE"
echo ""
echo "  ┌─ VM 1：K3s Server 1（主控制面，标准 VM）──────────────┐"
echo "  │  名称        : lab-k3s-server-1                         │"
echo "  │  区域        : us-central1 / us-central1-b            │"
echo "  │  机器类型    : e2-standard-2（2 vCPU / 8 GB）           │"
echo "  │  磁盘        : Debian 13，20 GB，Standard               │"
echo "  │  网络标签    : lab-fw                                    │"
echo "  │  Labels      : owner=lab, purpose=lab, day=d12, role=server│"
echo "  │  Provisioning: Standard                                  │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ VM 2：K3s Server 2（HA 备用控制面，标准 VM）─────────┐"
echo "  │  名称        : lab-k3s-server-2                         │"
echo "  │  机器类型    : e2-medium（2 vCPU / 4 GB）               │"
echo "  │  其余配置    : 同 Server 1，Labels 中 role=server        │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ┌─ VM 3-5：K3s Agent 1/2/3（工作节点，Spot VM）─────────┐"
echo "  │  名称        : lab-k3s-agent-1 / agent-2 / agent-3      │"
echo "  │  机器类型    : e2-medium（2 vCPU / 4 GB）               │"
echo "  │  磁盘        : Debian 13，20 GB，Standard               │"
echo "  │  网络标签    : lab-fw                                    │"
echo "  │  Labels      : owner=lab, purpose=lab, day=d12, role=agent│"
echo "  │  ⚡ Spot VM：Availability policies → Spot               │"
echo "  │              On VM termination → Stop                   │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
echo "  ⚠️  所有 5 台 VM 都不需要 Startup script（K3s 通过 SSH 安装）"
echo ""
echo "💡 体验提示："
echo "   - 对比 Server（e2-standard-2）和 Agent（e2-medium）的配置页面"
echo "   - 观察 Spot VM 的价格提示"
echo ""
read -rp "✅  5 台 VM 全部显示 Running 后，按 Enter 继续... "

echo ""
print_step 1 "等待所有 VM SSH 就绪"
wait_for_ssh "${SRV1}"
wait_for_ssh "${SRV2}"
for agent in "${AGENTS[@]}"; do
  wait_for_ssh "${agent}" &
done
wait
echo "  ✓ 所有节点 SSH 就绪"

# ---------- 创建内部 TCP LB（Console 操作过于繁琐，保持脚本）----------
print_step 2 "创建内部 TCP 负载均衡器（K3s API HA 入口，port 6443）"
echo "  注：内部 LB 创建步骤较多，保持脚本自动完成"

gcloud compute health-checks create tcp "${HC_NAME}" \
  --port=6443 \
  --check-interval=10s \
  --timeout=5s \
  --healthy-threshold=2 \
  --unhealthy-threshold=3 \
  --global 2>/dev/null || echo "  健康检查已存在，跳过"

gcloud compute instance-groups unmanaged create "${BS_NAME}-ig" \
  --zone="${ZONE}" 2>/dev/null || echo "  实例组已存在，跳过"

gcloud compute instance-groups unmanaged add-instances "${BS_NAME}-ig" \
  --zone="${ZONE}" \
  --instances="${SRV1},${SRV2}" 2>/dev/null || true

gcloud compute backend-services create "${BS_NAME}" \
  --load-balancing-scheme=INTERNAL \
  --protocol=TCP \
  --health-checks="${HC_NAME}" \
  --global-health-checks \
  --region="${REGION}" 2>/dev/null || echo "  后端服务已存在，跳过"

gcloud compute backend-services add-backend "${BS_NAME}" \
  --instance-group="${BS_NAME}-ig" \
  --instance-group-zone="${ZONE}" \
  --region="${REGION}" 2>/dev/null || true

gcloud compute forwarding-rules create "${FWD_NAME}" \
  --load-balancing-scheme=INTERNAL \
  --network="${NETWORK}" \
  --region="${REGION}" \
  --ports=6443 \
  --backend-service="${BS_NAME}" \
  --backend-service-region="${REGION}" \
  --labels="${BASE_LABELS},day=d12" 2>/dev/null || echo "  转发规则已存在，跳过"

LB_IP=$(gcloud compute forwarding-rules describe "${FWD_NAME}" \
  --region="${REGION}" \
  --format="get(IPAddress)")

echo "  ✓ 内部 LB IP：${LB_IP}"

# ---------- 汇总 IP ----------
print_step 3 "汇总节点 IP"
SRV1_EXT=$(get_vm_external_ip "${SRV1}")
SRV1_INT=$(get_vm_internal_ip "${SRV1}")
SRV2_INT=$(get_vm_internal_ip "${SRV2}")

echo ""
echo "=================================================================="
echo "✅  所有 VM 和 LB 就绪"
echo ""
printf "  %-26s %-18s %-18s\n" "VM 名称" "外网 IP" "内网 IP"
printf "  %-26s %-18s %-18s\n" "──────────────────────────" "──────────────────" "──────────────────"
printf "  %-26s %-18s %-18s\n" "${SRV1}（Server）" "${SRV1_EXT}" "${SRV1_INT}"
printf "  %-26s %-18s %-18s\n" "${SRV2}（Server）" "$(get_vm_external_ip ${SRV2})" "${SRV2_INT}"
for agent in "${AGENTS[@]}"; do
  A_EXT=$(get_vm_external_ip "${agent}")
  A_INT=$(get_vm_internal_ip "${agent}")
  printf "  %-26s %-18s %-18s\n" "${agent}（Agent, Spot）" "${A_EXT}" "${A_INT}"
done
echo ""
echo "  内部 LB IP（K3s API 入口）：${LB_IP}"
echo ""
echo "📋 接下来初始化 K3s："
echo "   bash ${SCRIPT_DIR}/init-k3s.sh"
echo ""
echo "💡 Console 体验提示："
echo "   - 打开 Network services → Load balancing，可以看到刚创建的内部 LB"
echo "   - 查看 Health checks，观察两台 Server 的健康状态（K3s 安装前是 Unhealthy）"
echo "=================================================================="
