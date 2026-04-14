# Day 4 — OpenTofu IaC

## 目标

- 理解 **Infrastructure as Code** 的核心理念
- 掌握 OpenTofu 的 **Write → Plan → Apply → Destroy** 工作流
- 体会"资源声明式管理"和"手动点控制台"的本质差异
- 了解 **state 文件**的作用和为什么要保护它

## 前置条件

```bash
# 安装 OpenTofu
# macOS
brew install opentofu
# Linux
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh

# 验证
tofu version
```

认证方式（选一）：

```bash
# 方式 1：使用 gcloud 用户凭据（实验推荐）
gcloud auth application-default login

# 方式 2：服务账号 JSON key（CI/CD 推荐）
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

## 预估费用

~$0.40（`e2-medium` × 6 小时 + 静态 IP × 6 小时）

## 执行步骤

### 1. 配置变量

```bash
cd day04-opentofu
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # 填写 project_id
```

### 2. 初始化（下载 provider）

```bash
tofu init
```

### 3. Plan（预览将要创建的资源）

```bash
tofu plan
```

仔细阅读输出：

- `+` = 将要创建
- `-` = 将要删除
- `~` = 将要修改

### 4. Apply（执行）

```bash
tofu apply
# 输入 yes 确认
```

记录输出的 `vm_external_ip`。

### 5. 访问服务

```bash
# 等待约 60 秒（startup script 安装 Docker）
curl http://$(tofu output -raw vm_external_ip):8080
```

### 6. 修改 → 看 Plan 变化

尝试修改 `variables.tf` 中的 `machine_type` 默认值，或修改 `main.tf` 中的 labels，然后：

```bash
tofu plan   # 查看 "will be updated in-place" vs "must be replaced"
```

### 7. 查看 state

```bash
tofu show          # 当前 state 的人类可读版
tofu state list    # 所有受管资源
```

### 8. 销毁（⚠️ 删除所有资源）

```bash
bash cleanup.sh
# 或直接
tofu destroy
```

## 关键概念

### State 文件

`terraform.tfstate` 是 OpenTofu 的"真相来源"：

- 记录 OpenTofu 认为"现在存在"的资源
- **不要手动编辑**
- **不要提交到 git**（包含敏感信息）
- 生产环境应存放在远端 backend（GCS、S3）

```bash
# 查看 state 内容
cat terraform.tfstate | python3 -m json.tool | head -50
```

### Plan = 安全机制

`tofu plan` 会对比：
- **期望态**：`.tf` 文件声明的
- **当前态**：`tfstate` 记录的
- **实际态**：GCP 真实存在的

三者一致则无变化；有差异则输出变更计划。

### in-place update vs replacement

| 变更类型 | 行为 |
|---------|------|
| 标签、metadata | in-place update（不重建 VM）|
| 机型（某些情况）| in-place（需停机）|
| 磁盘、镜像 | must replace（删重建）|
| 网络接口 | must replace |

### OpenTofu vs Terraform

OpenTofu 是 HashiCorp Terraform 的开源分支（2023 年 BSL 许可证变更后分叉）：
- 完全兼容 Terraform 配置语法（HCL）
- 兼容 Terraform provider 生态
- 社区治理，CNCF 项目

## 今天的感受问题

1. `tofu plan` 给你的信心感，和"手动操作后再验证"相比如何？
2. state 文件带来了什么问题？（提示：多人协作时）
3. OpenTofu 和 Day 3 的 Ansible 各自负责什么层面？能否结合使用？
