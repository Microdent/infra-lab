#!/usr/bin/env bash
# =============================================================================
# Day 9 — Dokku Heroku 风格 PaaS
# VM 由你在 GCP Console 手动创建，此脚本负责安装 Dokku
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config.sh"
source "${SCRIPT_DIR}/../lib/common.sh"

VM_NAME="lab-d09-dokku"

echo "=================================================================="
echo "  Day 9 — Dokku Heroku 风格 PaaS"
echo "=================================================================="
echo ""
echo "📋 请在 GCP Console 创建 VM，配置如下："
echo ""
echo "  ┌─ 基础配置 ─────────────────────────────────────────────┐"
echo "  │  名称        : lab-d09-dokku                            │"
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
echo "  │  Labels       : owner=lab, purpose=lab, day=d09         │"
echo "  └────────────────────────────────────────────────────────┘"
echo ""
read -rp "✅  VM 显示 Running 后，按 Enter 继续... "

echo ""
print_step 1 "读取 VM 公网 IP"
VM_IP=$(get_vm_external_ip "${VM_NAME}")
echo "  外部 IP：${VM_IP}"

print_step 2 "等待 SSH 就绪"
wait_for_ssh "${VM_NAME}"

print_step 3 "安装 Dokku"
run_on_vm_sudo "${VM_NAME}" "
  wget -NP /tmp https://dokku.com/bootstrap.sh
  DOKKU_TAG=v0.35.0 bash /tmp/bootstrap.sh
"

print_step 4 "配置 Dokku"
# 上传本地 SSH 公钥
LOCAL_PUBKEY="${HOME}/.ssh/google_compute_engine.pub"
[[ ! -f "${LOCAL_PUBKEY}" ]] && LOCAL_PUBKEY="${HOME}/.ssh/id_rsa.pub"
[[ ! -f "${LOCAL_PUBKEY}" ]] && LOCAL_PUBKEY="${HOME}/.ssh/id_ed25519.pub"

if [[ -f "${LOCAL_PUBKEY}" ]]; then
  cat "${LOCAL_PUBKEY}" | run_on_vm_sudo "${VM_NAME}" "dokku ssh-keys:add admin"
  echo "  ✓ SSH 公钥已添加"
else
  print_warn "未找到本地 SSH 公钥，请手动添加"
fi

# 用 nip.io 泛解析，无需真实域名
run_on_vm_sudo "${VM_NAME}" "dokku domains:set-global ${VM_IP}.nip.io"

print_step 5 "安装 Postgres 插件"
run_on_vm_sudo "${VM_NAME}" "
  dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
  dokku apps:create whoami
  dokku apps:create memos
  dokku postgres:create memos-db
  dokku postgres:link memos-db memos
  dokku ports:set whoami http:80:8080
"

echo ""
echo "=================================================================="
echo "✅  Dokku 就绪"
echo ""
echo "  VM IP：${VM_IP}"
echo "  whoami：http://whoami.${VM_IP}.nip.io（部署后可访问）"
echo ""
echo "📋 快速部署 whoami（在 VM 上用 Docker image 部署，无需 git push）："
echo "  gcloud compute ssh ${VM_NAME} --zone=${ZONE}"
echo "  sudo dokku git:from-image whoami traefik/whoami"
echo ""
echo "💡 Console 体验提示："
echo "   - 查看 VM 的 Monitoring 图表，对比 Day 7/8 的资源占用"
echo "   - Dokku 本身非常轻量，CPU/内存基本是应用在用，不是平台在用"
echo ""
echo "🧹 实验结束后执行："
echo "   bash ${SCRIPT_DIR}/cleanup.sh"
echo "=================================================================="
