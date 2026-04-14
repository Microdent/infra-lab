# Day 9 — Dokku（Heroku 风格单机 PaaS）

## 目标

- 体验 **git push 即部署** 的 Heroku 风格工作流
- 理解 **Buildpack** 和 **Dockerfile** 两种构建方式
- 掌握 **Dokku 插件系统**（postgres、redis、letsencrypt）
- 对比 Dokku 和 Coolify/Dokploy 的根本差异（CLI vs UI）

## 预估费用

~$0.55（`e2-medium` × 8 小时）

## 执行步骤

### 1. 创建 VM 并安装 Dokku

```bash
bash create.sh
```

### 2. 验证基础安装

```bash
VM_IP="YOUR_VM_IP"  # 从 create.sh 输出获取

# 用 Docker image 快速部署 whoami（无需本地代码）
gcloud compute ssh lab-d09-dokku --zone=us-central1-b \
  --command="sudo dokku git:from-image whoami traefik/whoami"

# 访问
curl http://whoami.${VM_IP}.nip.io
```

### 3. git push 部署体验（Heroku 经典方式）

在本地创建一个最小 Python/Node 应用：

```bash
# 本地创建示例应用
mkdir my-app && cd my-app
git init

# 创建最简单的 Python web 应用
cat > app.py << 'EOF'
from http.server import HTTPServer, BaseHTTPRequestHandler
import os

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(f"Hello from Dokku! hostname={os.environ.get('HOSTNAME')}".encode())

HTTPServer(('', int(os.environ.get('PORT', 5000))), Handler).serve_forever()
EOF

cat > Procfile << 'EOF'
web: python app.py
EOF

cat > runtime.txt << 'EOF'
python-3.11.x
EOF

git add .
git commit -m "initial"

# 添加 Dokku remote
git remote add dokku dokku@${VM_IP}:my-app

# 在 Dokku VM 上先创建应用
gcloud compute ssh lab-d09-dokku --zone=us-central1-b \
  --command="sudo dokku apps:create my-app"

# git push 触发自动构建和部署
git push dokku main
```

### 4. 探索 Dokku 插件

```bash
VM_SSH="gcloud compute ssh lab-d09-dokku --zone=us-central1-b --command"

# 查看已安装插件
${VM_SSH} "sudo dokku plugin:list"

# 查看数据库连接信息
${VM_SSH} "sudo dokku postgres:info memos-db"

# 查看环境变量（包含 DATABASE_URL）
${VM_SSH} "sudo dokku config:show memos"

# 安装 Let's Encrypt 插件（如果有真实域名）
${VM_SSH} "sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git"
${VM_SSH} "sudo dokku letsencrypt:set whoami email your@email.com"
${VM_SSH} "sudo dokku letsencrypt:enable whoami"
```

### 5. 扩容和管理

```bash
VM_SSH="gcloud compute ssh lab-d09-dokku --zone=us-central1-b --command"

# 查看应用状态
${VM_SSH} "sudo dokku apps:list"
${VM_SSH} "sudo dokku ps:report whoami"

# 查看日志
${VM_SSH} "sudo dokku logs whoami --tail"

# 扩容（Dokku 单机模式）
${VM_SSH} "sudo dokku ps:scale whoami web=2"
```

### 6. 清理

```bash
bash cleanup.sh
```

## Dokku 工作原理

```
git push dokku main
     ↓
Dokku SSH hook（检测到 push）
     ↓
检测构建方式：
  - 有 Dockerfile → Docker build
  - 有 Procfile  → Buildpack（herokuish）
     ↓
构建镜像 → 运行容器
     ↓
nginx 反代（dokku-managed nginx）
     ↓
http://appname.domain
```

## Dokku 插件生态

常用插件：

| 插件 | 用途 |
|------|------|
| `postgres` | PostgreSQL 数据库 |
| `redis` | Redis 缓存 |
| `mysql` | MySQL 数据库 |
| `letsencrypt` | 自动 HTTPS |
| `scheduler-k3s` | K3s 作为调度后端 |
| `registry` | 推送镜像到 Registry |

## Dokku vs Coolify/Dokploy

| 维度 | Dokku | Coolify / Dokploy |
|------|-------|------------------|
| 操作界面 | CLI + git push | Web UI |
| 学习曲线 | 低（git 就够）| 低（点击）|
| 可脚本化 | 极好 | 有限 |
| 版本控制友好 | 是（git 原生）| 部分 |
| 社区成熟度 | 极高（2013 年起）| 较新 |
| 企业特性 | 无 | 较多 |

## 今天的感受问题

1. `git push` 触发部署的体验，和你平时的部署流程相比如何？
2. Dokku 的 CLI 风格和 Coolify/Dokploy 的 UI 风格，哪个更符合你的工作方式？
3. 你会把 Dokku 用在什么样的项目上？
