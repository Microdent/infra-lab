#!/usr/bin/env bash
# =============================================================================
# lib/common.sh — 共享辅助函数库
# 使用方式：source "$(dirname "$0")/../lib/common.sh"
# （根据脚本所在层级调整相对路径）
# =============================================================================

# 颜色
_BOLD="\033[1m"
_GREEN="\033[0;32m"
_YELLOW="\033[0;33m"
_RED="\033[0;31m"
_RESET="\033[0m"

# -----------------------------------------------------------------------------
# print_step N "描述"
# 打印带编号的步骤提示
# -----------------------------------------------------------------------------
print_step() {
  local num="$1"
  local desc="$2"
  echo -e "\n${_BOLD}${_GREEN}[Step ${num}]${_RESET} ${desc}"
}

# -----------------------------------------------------------------------------
# print_warn "消息"
# -----------------------------------------------------------------------------
print_warn() {
  echo -e "${_YELLOW}⚠️  $1${_RESET}"
}

# -----------------------------------------------------------------------------
# print_error "消息"
# -----------------------------------------------------------------------------
print_error() {
  echo -e "${_RED}❌  $1${_RESET}" >&2
}

# -----------------------------------------------------------------------------
# get_vm_external_ip VM_NAME
# 返回 VM 的外部（公网）IP
# -----------------------------------------------------------------------------
get_vm_external_ip() {
  local vm_name="$1"
  gcloud compute instances describe "${vm_name}" \
    --zone="${ZONE}" \
    --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
}

# -----------------------------------------------------------------------------
# get_vm_internal_ip VM_NAME
# 返回 VM 的内部（私网）IP — Swarm/K3s 集群内通信专用
# -----------------------------------------------------------------------------
get_vm_internal_ip() {
  local vm_name="$1"
  gcloud compute instances describe "${vm_name}" \
    --zone="${ZONE}" \
    --format="get(networkInterfaces[0].networkIP)"
}

# -----------------------------------------------------------------------------
# wait_for_ssh VM_NAME [MAX_RETRIES]
# 等待 VM SSH 可用，默认最多重试 30 次（每次间隔 5 秒）
# -----------------------------------------------------------------------------
wait_for_ssh() {
  local vm_name="$1"
  local max_retries="${2:-30}"
  local attempt=0

  echo -n "  等待 ${vm_name} SSH 就绪"
  while [[ ${attempt} -lt ${max_retries} ]]; do
    if gcloud compute ssh "${vm_name}" \
        --zone="${ZONE}" \
        --command="echo ok" \
        --quiet \
        --ssh-flag="-o ConnectTimeout=5" \
        --ssh-flag="-o StrictHostKeyChecking=no" \
        2>/dev/null; then
      echo -e " ${_GREEN}✓${_RESET}"
      return 0
    fi
    echo -n "."
    sleep 5
    attempt=$((attempt + 1))
  done

  echo ""
  print_error "${vm_name} SSH 等待超时（${max_retries} 次重试）"
  return 1
}

# -----------------------------------------------------------------------------
# run_on_vm VM_NAME "命令"
# 在远端 VM 上执行命令
# -----------------------------------------------------------------------------
run_on_vm() {
  local vm_name="$1"
  local cmd="$2"
  gcloud compute ssh "${vm_name}" \
    --zone="${ZONE}" \
    --command="${cmd}" \
    --ssh-flag="-o StrictHostKeyChecking=no"
}

# -----------------------------------------------------------------------------
# run_on_vm_sudo VM_NAME "命令"
# 在远端 VM 上以 sudo 执行命令
# -----------------------------------------------------------------------------
run_on_vm_sudo() {
  local vm_name="$1"
  local cmd="$2"
  run_on_vm "${vm_name}" "sudo bash -c '${cmd}'"
}

# -----------------------------------------------------------------------------
# copy_to_vm LOCAL_PATH VM_NAME REMOTE_PATH
# 将本地文件/目录上传到 VM
# -----------------------------------------------------------------------------
copy_to_vm() {
  local local_path="$1"
  local vm_name="$2"
  local remote_path="$3"
  gcloud compute scp --recurse \
    "${local_path}" \
    "${vm_name}:${remote_path}" \
    --zone="${ZONE}" \
    --ssh-flag="-o StrictHostKeyChecking=no"
}

# -----------------------------------------------------------------------------
# copy_from_vm VM_NAME REMOTE_PATH LOCAL_PATH
# 从 VM 下载文件到本地
# -----------------------------------------------------------------------------
copy_from_vm() {
  local vm_name="$1"
  local remote_path="$2"
  local local_path="$3"
  gcloud compute scp --recurse \
    "${vm_name}:${remote_path}" \
    "${local_path}" \
    --zone="${ZONE}" \
    --ssh-flag="-o StrictHostKeyChecking=no"
}

# -----------------------------------------------------------------------------
# vm_exists VM_NAME
# 检查 VM 是否存在，返回 0（存在）或 1（不存在）
# -----------------------------------------------------------------------------
vm_exists() {
  local vm_name="$1"
  gcloud compute instances describe "${vm_name}" \
    --zone="${ZONE}" \
    --quiet 2>/dev/null
}

# -----------------------------------------------------------------------------
# delete_vm VM_NAME
# 静默删除 VM 及其磁盘
# -----------------------------------------------------------------------------
delete_vm() {
  local vm_name="$1"
  if vm_exists "${vm_name}"; then
    echo "  删除 ${vm_name} ..."
    gcloud compute instances delete "${vm_name}" \
      --zone="${ZONE}" \
      --delete-disks=all \
      --quiet
  else
    print_warn "${vm_name} 不存在，跳过删除"
  fi
}
