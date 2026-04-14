# Day 5 — Pulumi Python + GitHub Actions

## 目标

- 体验**编程语言式 IaC**（Python）与 Day 4 OpenTofu 的 HCL 风格对比
- 理解 Pulumi 的 **Stack** 概念（对标 Terraform workspace）
- 用 **GitHub Actions** 搭建最简单的 IaC CI/CD 流水线
- 体验"代码推送 → 自动部署"的 GitOps 前置感

## 前置条件

```bash
# 安装 Pulumi
curl -fsSL https://get.pulumi.com | sh

# 登录（免费 Pulumi Cloud 账号，存放 state）
pulumi login

# 安装 Python 依赖
cd day05-pulumi-gha
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 预估费用

~$0.40（`e2-medium` × 6 小时 + 静态 IP）

## 本地执行步骤

### 1. 配置栈变量

```bash
cd day05-pulumi-gha

# 初始化 dev 栈
pulumi stack init dev

# 设置 GCP 项目（或直接编辑 Pulumi.dev.yaml）
pulumi config set gcp:project YOUR_PROJECT_ID
pulumi config set gcp:zone us-central1-b
```

### 2. Preview（等同于 tofu plan）

```bash
pulumi preview
```

### 3. Up（创建资源）

```bash
pulumi up
```

记录输出的 `vm_external_ip`。

### 4. 访问服务

```bash
VM_IP=$(pulumi stack output vm_external_ip)
curl http://${VM_IP}:8080
```

### 5. 销毁

```bash
bash cleanup.sh
```

## GitHub Actions 配置步骤

### 1. 创建 GCP 服务账号

```bash
# 创建服务账号
gcloud iam service-accounts create pulumi-lab-sa \
  --display-name="Pulumi Lab Service Account"

# 授权（Compute Admin 足够本实验）
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:pulumi-lab-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# 生成 JSON key
gcloud iam service-accounts keys create /tmp/sa-key.json \
  --iam-account=pulumi-lab-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### 2. 在 GitHub 仓库设置 Secrets

```
Settings → Secrets and variables → Actions → New repository secret

GCP_SA_KEY      = 粘贴 /tmp/sa-key.json 的内容
PULUMI_ACCESS_TOKEN = 从 https://app.pulumi.com/account/tokens 获取
```

### 3. 触发工作流

```bash
# 推送代码（路径过滤：day05-pulumi-gha/**）
git add day05-pulumi-gha/
git commit -m "day05: update pulumi config"
git push origin main

# 或手动触发（可选择 up / preview / destroy）
# GitHub → Actions → Day 5 — Pulumi Deploy → Run workflow
```

## Pulumi vs OpenTofu 对比

| 维度 | OpenTofu (HCL) | Pulumi (Python) |
|------|---------------|-----------------|
| 语法 | 声明式 DSL | 真实编程语言 |
| 逻辑表达 | 有限（for_each, count）| 完整（循环、条件、函数）|
| 测试 | 有限（validate）| 单元测试（pytest）|
| 类型检查 | 运行时 | IDE 静态分析 |
| 学习曲线 | 低（针对 Ops）| 中（需要编程基础）|
| 生态成熟度 | 极高 | 中等 |
| State 存储 | 本地/GCS/S3 | Pulumi Cloud/本地/S3 |

### 什么时候选 Pulumi？

- 团队有强烈的编程背景，不喜欢 DSL
- 需要复杂逻辑（动态资源数量、条件创建）
- 想要单元测试基础设施代码
- 正在用 TypeScript 且希望 IaC 与应用代码同语言

### 什么时候选 OpenTofu？

- 团队以 Ops 为主，HCL 更直观
- 需要最大的 provider 和模块生态
- 希望降低 CI/CD 复杂度
- 现有大量 Terraform 代码需要迁移

## 今天的感受问题

1. Python 写 IaC 对你来说更自然还是更别扭？
2. GitHub Actions 触发 `pulumi up` 和手动执行有什么本质差异？
3. IaC 的 CI/CD 和应用代码的 CI/CD，职责边界在哪里？
