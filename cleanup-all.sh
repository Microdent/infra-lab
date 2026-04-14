#!/usr/bin/env bash
# =============================================================================
# cleanup-all.sh — 全局资源检查与清理引导
# VM 删除：引导在 GCP Console 手动操作
# LB/GKE/Cloud Run 等：脚本自动删除
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/lib/common.sh"

echo ""
echo "=================================================================="
echo "  全局资源检查"
echo "  项目：${PROJECT_ID}  区域：${REGION}"
echo "=================================================================="
echo ""

# ---------- 列出所有实验资源 ----------
echo "📋 当前 lab 资源列表："
echo ""
echo "--- Compute Instances ---"
gcloud compute instances list \
  --filter="labels.purpose=lab" \
  --format="table(name,zone,status,machineType)" \
  2>/dev/null || echo "  (无)"

echo ""
echo "--- GKE Clusters ---"
gcloud container clusters list \
  --filter="resourceLabels.purpose=lab" \
  --format="table(name,location,status)" \
  2>/dev/null || echo "  (无)"

echo ""
echo "--- Cloud Run Services ---"
gcloud run services list \
  --region="${REGION}" \
  --filter="metadata.labels.purpose=lab" \
  --format="table(metadata.name,status.url)" \
  2>/dev/null || echo "  (无)"

echo ""
echo "--- Forwarding Rules（内部 LB）---"
gcloud compute forwarding-rules list \
  --filter="labels.purpose=lab" \
  --format="table(name,region,IPAddress)" \
  2>/dev/null || echo "  (无)"

echo ""
echo "--- Compute Disks（残留未挂载）---"
gcloud compute disks list \
  --filter="labels.purpose=lab AND -users:*" \
  --format="table(name,zone,sizeGb,status)" \
  2>/dev/null || echo "  (无)"

echo ""
echo "=================================================================="
echo ""

# ---------- VM 引导手动删除 ----------
VM_LIST=$(gcloud compute instances list \
  --filter="labels.purpose=lab" \
  --format="csv[no-heading](name,zone)" 2>/dev/null || true)

if [[ -n "${VM_LIST}" ]]; then
  echo "🖥️  发现实验 VM，请在 GCP Console 手动删除："
  echo ""
  echo "  路径：Compute Engine → VM instances"
  echo "  全选以下 VM，点击 DELETE，勾选 "Delete boot disk""
  echo ""
  while IFS=',' read -r name zone; do
    echo "    ☐ ${name}（${zone}）"
  done <<< "${VM_LIST}"
  echo ""
  read -rp "✅  VM 已全部删除后，按 Enter 继续清理其他资源... "
  echo ""
fi

# ---------- 自动删除 LB 资源 ----------
FWD_RULES=$(gcloud compute forwarding-rules list \
  --filter="labels.purpose=lab" \
  --format="csv[no-heading](name,region)" 2>/dev/null || true)

if [[ -n "${FWD_RULES}" ]]; then
  print_step 1 "删除内部 LB 转发规则"
  while IFS=',' read -r name region; do
    gcloud compute forwarding-rules delete "${name}" \
      --region="${region}" --quiet 2>/dev/null \
      && echo "  ✓ ${name} 已删除" || print_warn "${name} 删除失败"
  done <<< "${FWD_RULES}"
fi

# ---------- 自动删除 Cloud Run ----------
CR_LIST=$(gcloud run services list \
  --region="${REGION}" \
  --filter="metadata.labels.purpose=lab" \
  --format="csv[no-heading](metadata.name)" 2>/dev/null || true)

if [[ -n "${CR_LIST}" ]]; then
  print_step 2 "删除 Cloud Run 服务"
  while IFS= read -r name; do
    gcloud run services delete "${name}" \
      --region="${REGION}" --quiet 2>/dev/null \
      && echo "  ✓ ${name} 已删除" || print_warn "${name} 删除失败"
  done <<< "${CR_LIST}"
fi

# ---------- GKE 引导手动删除 ----------
GKE_LIST=$(gcloud container clusters list \
  --filter="resourceLabels.purpose=lab" \
  --format="csv[no-heading](name,location)" 2>/dev/null || true)

if [[ -n "${GKE_LIST}" ]]; then
  echo ""
  echo "☸️  发现 GKE 集群，请在 GCP Console 手动删除："
  echo "  路径：Kubernetes Engine → Clusters → 勾选集群 → DELETE"
  echo ""
  while IFS=',' read -r name location; do
    echo "    ☐ ${name}（${location}）"
  done <<< "${GKE_LIST}"
  echo ""
  read -rp "✅  GKE 集群已删除后，按 Enter 继续... "
fi

# ---------- 清理残留磁盘 ----------
DISK_LIST=$(gcloud compute disks list \
  --filter="labels.purpose=lab AND -users:*" \
  --format="csv[no-heading](name,zone)" 2>/dev/null || true)

if [[ -n "${DISK_LIST}" ]]; then
  print_step 3 "删除残留磁盘"
  while IFS=',' read -r name zone; do
    gcloud compute disks delete "${name}" \
      --zone="${zone}" --quiet 2>/dev/null \
      && echo "  ✓ 磁盘 ${name} 已删除" || print_warn "${name} 删除失败"
  done <<< "${DISK_LIST}"
fi

echo ""
echo "=================================================================="
echo "📋 最终验证："
echo ""
echo "  gcloud compute instances list --filter=\"labels.purpose=lab\""
echo "  gcloud compute disks list --filter=\"labels.purpose=lab\""
echo "  gcloud container clusters list --filter=\"resourceLabels.purpose=lab\""
echo "=================================================================="
