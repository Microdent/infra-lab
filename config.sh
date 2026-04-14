#!/usr/bin/env bash
# =============================================================================
# config.sh — 全局配置，所有脚本通过 source 引用
# 使用前必须填写 PROJECT_ID
# =============================================================================

# ---------------- 必填项 ----------------
PROJECT_ID="YOUR_PROJECT_ID_HERE"

# ---------------- 区域与可用区 ----------------
REGION="us-central1"
ZONE="us-central1-b"

# ---------------- 操作系统镜像 ----------------
# 当前使用 Debian 13 (Bookworm)，GCP 上最新稳定版
# 检查 Debian 13 是否可用：
#   gcloud compute images list --filter="family~debian-13" --project=debian-cloud
IMAGE_FAMILY="debian-13"
IMAGE_PROJECT="debian-cloud"

# COS (Container-Optimized OS) — Day 2 专用
COS_IMAGE_FAMILY="cos-stable"
COS_IMAGE_PROJECT="cos-cloud"

# ---------------- 机型 ----------------
MACHINE_STANDARD="e2-medium"      # 2 vCPU / 4 GB — 大多数单机实验
MACHINE_LARGE="e2-standard-2"     # 2 vCPU / 8 GB — Coolify/Swarm manager/K3s server
MACHINE_SMALL="e2-micro"          # 1 vCPU / 1 GB — 轻量 agent 节点

# ---------------- 网络 ----------------
NETWORK_TAG="lab-fw"              # 防火墙目标标签，所有实验 VM 共用
NETWORK="default"

# ---------------- 资源标签 ----------------
BASE_LABELS="owner=lab,purpose=lab"

# ---------------- 应用镜像版本（跨天统一，改一处全部生效）----------------
WHOAMI_IMAGE="traefik/whoami"
MEMOS_IMAGE="ghcr.io/usememos/memos:latest"
POSTGRES_IMAGE="postgres:16-alpine"
UPTIME_KUMA_IMAGE="louislam/uptime-kuma:1"

# ---------------- SSH 用户 ----------------
SSH_USER="microdent"

# =============================================================================
# 安全检查 — 防止忘记填写 PROJECT_ID 就执行脚本
# =============================================================================
if [[ "${PROJECT_ID}" == "YOUR_PROJECT_ID_HERE" ]]; then
  echo "❌  错误：请先编辑 config.sh，填写真实的 GCP Project ID"
  echo "    将 PROJECT_ID=\"YOUR_PROJECT_ID_HERE\" 替换为你的项目 ID"
  echo "    查询方法：gcloud projects list"
  exit 1
fi
