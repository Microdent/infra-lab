#!/usr/bin/env bash
# =============================================================================
# Day 1 — startup-script.sh
# 此脚本由 GCE 在 VM 首次启动时以 root 身份自动执行
# 执行日志可通过 serial console 查看
# =============================================================================
set -euo pipefail

echo "========================================"
echo "  [STARTUP] 开始执行 startup script"
echo "  时间：$(date)"
echo "========================================"

# ---------- 安装 nginx ----------
echo "[STARTUP] 更新 apt 并安装 nginx..."
apt-get update -q
apt-get install -y -q nginx curl

# ---------- 从 metadata 服务读取实例信息 ----------
METADATA_BASE="http://169.254.169.254/computeMetadata/v1/instance"
METADATA_HEADER="Metadata-Flavor: Google"

HOSTNAME_VAL=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/hostname" || echo "unknown")
INTERNAL_IP=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/network-interfaces/0/ip" || echo "unknown")
ZONE_VAL=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/zone" || echo "unknown")
MACHINE_TYPE=$(curl -sf -H "${METADATA_HEADER}" "${METADATA_BASE}/machine-type" || echo "unknown")

echo "[STARTUP] 主机名：${HOSTNAME_VAL}"
echo "[STARTUP] 内网 IP：${INTERNAL_IP}"
echo "[STARTUP] 可用区：${ZONE_VAL}"
echo "[STARTUP] 机型：${MACHINE_TYPE}"

# ---------- 生成自定义首页 ----------
cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="UTF-8">
  <title>Day 1 — GCE Startup Script 实验</title>
  <style>
    body { font-family: monospace; background: #1a1a2e; color: #e0e0e0; padding: 2rem; }
    h1 { color: #4ecca3; }
    table { border-collapse: collapse; margin-top: 1rem; }
    td { padding: 0.4rem 1.2rem 0.4rem 0; }
    td:first-child { color: #a0a0c0; }
    .badge { background: #4ecca3; color: #1a1a2e; padding: 0.1rem 0.5rem; border-radius: 3px; }
  </style>
</head>
<body>
  <h1>🚀 Day 1 — GCE Startup Script 实验</h1>
  <p>这个页面由 <strong>startup script</strong> 生成，无需手动 SSH 配置。</p>
  <table>
    <tr><td>主机名</td><td><span class="badge">${HOSTNAME_VAL}</span></td></tr>
    <tr><td>内网 IP</td><td>${INTERNAL_IP}</td></tr>
    <tr><td>可用区</td><td>${ZONE_VAL}</td></tr>
    <tr><td>机型</td><td>${MACHINE_TYPE}</td></tr>
    <tr><td>启动时间</td><td>$(date)</td></tr>
  </table>
  <p style="margin-top:2rem;color:#606080;">
    日志查看：<code>gcloud compute instances get-serial-port-output $(hostname) --zone=${ZONE_VAL##*/}</code>
  </p>
</body>
</html>
HTML

# ---------- 启动 nginx ----------
systemctl enable nginx
systemctl start nginx

echo "========================================"
echo "  [STARTUP] 执行完成 ✓"
echo "  nginx 已启动，首页已生成"
echo "========================================"
