#!/usr/bin/env bash
# =============================================================================
# Day 13 — Flux CD 安装（ArgoCD 的备选方案）
# Flux 更原生 K8s，无 UI，纯 CLI 和 CRD 操作
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KUBECONFIG="${SCRIPT_DIR}/../kubeconfig-lab.yaml"

echo "=================================================================="
echo "  Day 13 — Flux CD 安装（ArgoCD 备选）"
echo "  前提：需要 GITHUB_TOKEN 和 GITHUB_USER 环境变量"
echo "=================================================================="

if [[ -z "${GITHUB_TOKEN:-}" ]] || [[ -z "${GITHUB_USER:-}" ]]; then
  echo "❌  请先设置环境变量："
  echo "    export GITHUB_TOKEN=ghp_your_token"
  echo "    export GITHUB_USER=your_github_username"
  echo ""
  echo "    GitHub Token 需要 repo 权限"
  echo "    创建方式：GitHub → Settings → Developer settings → Personal access tokens"
  exit 1
fi

GITHUB_REPO="${GITHUB_REPO:-infra-lab}"

# ---------- 安装 flux CLI（如果未安装）----------
if ! command -v flux &>/dev/null; then
  echo "安装 flux CLI..."
  curl -s https://fluxcd.io/install.sh | bash
fi

# ---------- 检查集群兼容性 ----------
echo "Step 1: 检查集群兼容性"
flux check --pre

# ---------- Bootstrap（关联 GitHub 仓库）----------
echo ""
echo "Step 2: Bootstrap Flux 到 GitHub 仓库"
echo "  仓库：${GITHUB_USER}/${GITHUB_REPO}"
echo "  路径：day12-13-k3s/flux/clusters/lab"
echo ""

flux bootstrap github \
  --owner="${GITHUB_USER}" \
  --repository="${GITHUB_REPO}" \
  --branch=main \
  --path=day12-13-k3s/flux/clusters/lab \
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller

echo ""
echo "=================================================================="
echo "✅  Flux 已 Bootstrap"
echo ""
echo "📋 Flux 操作方式（对比 ArgoCD）："
echo ""
echo "  # 查看 Flux 组件状态"
echo "  flux get all"
echo ""
echo "  # 手动触发同步（不等 Git polling）"
echo "  flux reconcile kustomization flux-system"
echo ""
echo "  # 查看同步日志"
echo "  flux logs --all-namespaces"
echo ""
echo "  # 暂停同步"
echo "  flux suspend kustomization flux-system"
echo ""
echo "  如需在 Git 中添加 Kustomization，在以下路径创建文件："
echo "  day12-13-k3s/flux/clusters/lab/whoami-kustomization.yaml"
echo "=================================================================="
