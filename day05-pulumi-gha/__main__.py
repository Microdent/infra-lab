"""
Day 5 — Pulumi Python 程序
创建一台 GCE VM，运行 whoami 容器
"""

import pulumi
import pulumi_gcp as gcp

# ---------- 读取栈配置 ----------
config = pulumi.Config("gcp")
zone = config.get("zone") or "us-central1-b"
region = config.get("region") or "us-central1"

project = gcp.config.project

# ---------- 查找最新 Debian 12 镜像 ----------
debian_image = gcp.compute.get_image(
    family="debian-12",
    project="debian-cloud",
)

# ---------- 静态外部 IP ----------
static_ip = gcp.compute.Address(
    "lab-d05-ip",
    region=region,
    labels={
        "owner": "lab",
        "purpose": "lab",
        "day": "d05",
    },
)

# ---------- startup script ----------
startup_script = """#!/bin/bash
set -e
apt-get update -q
apt-get install -y -q ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
. /etc/os-release
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update -q
apt-get install -y -q docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker run -d --name whoami --restart unless-stopped -p 8080:80 traefik/whoami
echo "PULUMI STARTUP COMPLETE" > /dev/console
"""

# ---------- VM 实例 ----------
vm = gcp.compute.Instance(
    "lab-d05-app",
    name="lab-d05-app",
    machine_type="e2-medium",
    zone=zone,
    labels={
        "owner": "lab",
        "purpose": "lab",
        "day": "d05",
    },
    tags=["lab-fw"],
    boot_disk=gcp.compute.InstanceBootDiskArgs(
        initialize_params=gcp.compute.InstanceBootDiskInitializeParamsArgs(
            image=debian_image.self_link,
            size=20,
            type="pd-standard",
        )
    ),
    network_interfaces=[
        gcp.compute.InstanceNetworkInterfaceArgs(
            network="default",
            access_configs=[
                gcp.compute.InstanceNetworkInterfaceAccessConfigArgs(
                    nat_ip=static_ip.address,
                )
            ],
        )
    ],
    metadata={
        "startup-script": startup_script,
    },
    opts=pulumi.ResourceOptions(depends_on=[static_ip]),
)

# ---------- 输出 ----------
pulumi.export("vm_name", vm.name)
pulumi.export("vm_external_ip", static_ip.address)
pulumi.export("whoami_url", static_ip.address.apply(lambda ip: f"http://{ip}:8080"))
pulumi.export("ssh_command", vm.name.apply(lambda name: f"gcloud compute ssh {name} --zone={zone}"))
