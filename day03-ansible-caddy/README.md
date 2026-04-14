# Day 3 — Ansible + Docker Compose + Caddy 单机标准形态

## 目标

- 掌握 **Ansible** 的核心概念：playbook、role、inventory、幂等性
- 建立 Docker Compose 单机生产基线：多服务栈 + 数据持久化
- 体验 **Caddy 自动 HTTPS**：配置一行域名，自动签发和续期证书
- 理解"无面板，但完全可管"的单机形态

## 前置条件

Ansible 安装在你的 ops 机器上（Cloud Shell 或 ops VM）：

```bash
pip install ansible
```

## 一、在 Console 创建 VM

路径：**Compute Engine → VM instances → CREATE INSTANCE**

| 字段 | 值 |
|------|----|
| 名称 | `lab-d03-app` |
| 区域/地带 | `us-central1 / us-central1-b` |
| 机器类型 | `e2-medium`（2 vCPU / 4 GB） |
| 启动磁盘 | Debian 13，30 GB，Standard persistent disk |
| Network tags | `lab-fw` |
| Labels | `owner=lab, purpose=lab, day=d03` |

> 不需要填 Startup script，所有配置由 Ansible 完成。

VM 显示 Running 后，从列表复制 **External IP**，然后：

```bash
bash create.sh <External IP>
```

这个脚本只做一件事：生成 `ansible/inventory.ini`。

## 预估费用

~$0.55（`e2-medium` × 8 小时）

## 执行步骤

### 1. 创建 VM

```bash
bash create.sh
```

记录打印出的 VM 外部 IP。

### 2. 配置域名（关键步骤）

在你的 DNS 提供商处添加 A 记录：

```
whoami.yourdomain.com  →  VM外部IP
memos.yourdomain.com   →  VM外部IP
uptime.yourdomain.com  →  VM外部IP
```

编辑变量文件：

```bash
vim ansible/group_vars/all.yml
# 修改 domain: "lab.yourdomain.com" 为你的真实域名
```

### 3. 运行 Ansible

```bash
cd day03-ansible-caddy

# 先做 dry-run，查看将要发生什么
ansible-playbook ansible/playbook.yml --check --diff

# 实际执行
ansible-playbook ansible/playbook.yml
```

### 4. 按角色分步执行（学习用）

```bash
# 只安装 Docker
ansible-playbook ansible/playbook.yml --tags docker

# 只部署应用栈（需要 Docker 已安装）
ansible-playbook ansible/playbook.yml --tags app

# 只配置 Caddy（需要域名已解析到 VM）
ansible-playbook ansible/playbook.yml --tags caddy
```

### 5. 验证

```bash
# 等待 DNS 生效后（nslookup whoami.yourdomain.com）
curl https://whoami.yourdomain.com      # 自动 HTTPS
curl https://memos.yourdomain.com       # memos 应用
# 浏览器打开 https://uptime.yourdomain.com 进行初始化设置
```

### 6. 重复执行验证幂等性

```bash
# 再次执行，所有任务应显示 "ok"，没有 "changed"
ansible-playbook ansible/playbook.yml
```

### 7. 清理

```bash
bash cleanup.sh
```

## 目录结构

```
day03-ansible-caddy/
├── create.sh                  # 创建 VM，生成 inventory.ini
├── cleanup.sh                 # 删除 VM
├── ansible.cfg                # Ansible 配置（SSH 用户、inventory 路径等）
├── ansible/
│   ├── inventory.ini          # 由 create.sh 生成（gitignored）
│   ├── playbook.yml           # 主 playbook：三角色顺序执行
│   ├── group_vars/
│   │   └── all.yml            # 全局变量：domain、镜像版本、端口
│   └── roles/
│       ├── docker/            # 安装 Docker CE
│       ├── app-stack/         # 部署 Compose 栈
│       └── caddy/             # 安装 Caddy，配置 HTTPS 反代
```

## 关键概念

### Ansible 幂等性

- `apt` 模块：`state: present` = 已安装则跳过
- `copy` 模块：文件内容无变化则跳过
- `systemd` 模块：服务已运行则跳过
- 执行结果显示 `ok` 而非 `changed` = 未改变状态

### Caddy 自动 HTTPS 工作原理

1. Caddy 检测到域名配置
2. 向 Let's Encrypt 发起 ACME HTTP-01 挑战
3. Let's Encrypt 访问 `http://yourdomain.com/.well-known/acme-challenge/...`
4. 验证通过后签发证书
5. Caddy 自动续期（在证书过期前 30 天）

**前提**：
- 域名 DNS A 记录已指向 VM 公网 IP
- 端口 80 和 443 对公网开放

### Ansible check mode

```bash
# --check：不实际执行，模拟运行
# --diff：显示文件变更内容
ansible-playbook playbook.yml --check --diff
```

### 应用栈架构

```
公网
  ↓ 443
Caddy (自动 HTTPS)
  ├─→ :8080  whoami
  ├─→ :3000  memos ←→ postgres:5432
  └─→ :3001  uptime-kuma
```

## 今天的感受问题

1. Ansible 的"幂等性"相比手动 SSH 执行命令有什么实际好处？
2. Caddy 自动签证书和 Nginx + Certbot 相比，复杂度差异有多大？
3. 这套"Compose + Caddy + Ansible"组合，对你来说是否已经够用？什么场景会让你觉得不够用？
