#!/usr/bin/env bash
# =============================================================================
# setup/create-firewall.sh — 创建实验用防火墙规则（只需执行一次）
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

echo "=================================================================="
echo "  创建实验防火墙规则"
echo "  项目：${PROJECT_ID}  网络：${NETWORK}"
echo "=================================================================="

# ---------- lab-allow-web ----------
# 面向公网的服务端口（所有带 lab-fw 标签的 VM 生效）
FW_WEB="lab-allow-web"
if gcloud compute firewall-rules describe "${FW_WEB}" --quiet 2>/dev/null; then
  print_warn "${FW_WEB} 已存在，跳过"
else
  print_step 1 "创建 ${FW_WEB}"
  gcloud compute firewall-rules create "${FW_WEB}" \
    --network="${NETWORK}" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules="tcp:80,tcp:443,tcp:8080,tcp:8443,tcp:3000,tcp:3001,tcp:9000" \
    --source-ranges="0.0.0.0/0" \
    --target-tags="${NETWORK_TAG}" \
    --description="Lab: Web services"
  echo "  ✓ ${FW_WEB} 创建完成"
fi

# ---------- lab-allow-ssh ----------
# 允许直接 SSH（GCP 默认已有 IAP SSH，这里确保直连也可以）
FW_SSH="lab-allow-ssh"
if gcloud compute firewall-rules describe "${FW_SSH}" --quiet 2>/dev/null; then
  print_warn "${FW_SSH} 已存在，跳过"
else
  print_step 2 "创建 ${FW_SSH}"
  gcloud compute firewall-rules create "${FW_SSH}" \
    --network="${NETWORK}" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules="tcp:22" \
    --source-ranges="0.0.0.0/0" \
    --target-tags="${NETWORK_TAG}" \
    --description="Lab: SSH access"
  echo "  ✓ ${FW_SSH} 创建完成"
fi

# ---------- lab-allow-cluster ----------
# 集群内通信端口（Swarm: 2377/7946, K3s: 6443, Portainer Agent: 2376）
FW_CLUSTER="lab-allow-cluster"
if gcloud compute firewall-rules describe "${FW_CLUSTER}" --quiet 2>/dev/null; then
  print_warn "${FW_CLUSTER} 已存在，跳过"
else
  print_step 3 "创建 ${FW_CLUSTER}"
  gcloud compute firewall-rules create "${FW_CLUSTER}" \
    --network="${NETWORK}" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules="tcp:2376,tcp:2377,tcp:6443,tcp:7946,udp:7946,udp:4789" \
    --source-tags="${NETWORK_TAG}" \
    --target-tags="${NETWORK_TAG}" \
    --description="Lab: Cluster internal communication"
  echo "  ✓ ${FW_CLUSTER} 创建完成"
fi

# ---------- lab-allow-healthcheck ----------
# GCP 健康检查 prober IP — K3s 内部 LB 需要
FW_HC="lab-allow-healthcheck"
if gcloud compute firewall-rules describe "${FW_HC}" --quiet 2>/dev/null; then
  print_warn "${FW_HC} 已存在，跳过"
else
  print_step 4 "创建 ${FW_HC}"
  gcloud compute firewall-rules create "${FW_HC}" \
    --network="${NETWORK}" \
    --direction=INGRESS \
    --priority=1000 \
    --action=ALLOW \
    --rules="tcp:6443" \
    --source-ranges="130.211.0.0/22,35.191.0.0/16" \
    --target-tags="${NETWORK_TAG}" \
    --description="Lab: GCP health check probers for internal LB"
  echo "  ✓ ${FW_HC} 创建完成"
fi

echo ""
echo "=================================================================="
echo "✅  防火墙规则创建完成"
echo ""
echo "验证："
echo "  gcloud compute firewall-rules list --filter=\"name~lab-\""
echo "=================================================================="
