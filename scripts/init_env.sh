#!/bin/bash
# ==========================================
# 脚本名称: init_env.sh
# 脚本功能: Ubuntu 自动化换源与 Docker 静默安装
# ==========================================

# 1. 防爆破检测：必须以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "❌ 错误: 请使用 sudo 执行此脚本！"
  exit 1
fi
echo "✅ 权限检测通过，开始初始化环境..."

# 2. 幂等性检测：检查 Docker 是否已安装
if command -v docker &> /dev/null; then
    echo "⚠️ Docker 已安装，当前版本为: $(docker -v)"
    echo "⏭️ 跳过安装步骤。"
else
    echo "⏳ 开始替换阿里云源并安装依赖..."
    # 替换为阿里云源
    sed -i 's/http:\/\/.*archive.ubuntu.com/http:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list
    sed -i 's/http:\/\/.*security.ubuntu.com/http:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list
    
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release

    echo "⏳ 开始配置 Docker 官方 GPG 密钥与专属源..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "⏳ 开始静默安装 Docker 全家桶..."
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    echo "✅ Docker 安装成功！"
fi

# 3. 启动服务并设置开机自启
systemctl start docker
systemctl enable docker
echo "🚀 环境初始化完毕！请执行 'sudo usermod -aG docker \$USER' 将当前用户加入 docker 组。"
