#!/bin/bash
# ==========================================
# 脚本名称: backup_zabbix.sh
# 脚本功能: 备份 Zabbix 数据库并清理过期数据
# ==========================================

# 1. 拦截：检查当前用户是不是 root
if [ "$EUID" -ne 0 ]; then
  echo "❌ 错误: 请使用 sudo 执行此备份脚本！"
  exit 1
fi

# 2. 准备：定义核心变量 (路径和时间戳)
# 语法解析: $(date +%F) 会生成 2026-02-20 这样的标准格式
BACKUP_DIR="/home/caleb/zabbix-docker/backups"
TIMESTAMP=$(date +%F_%H-%M-%S)
BACKUP_FILE="${BACKUP_DIR}/zabbix_db_${TIMESTAMP}.sql"

# 检查并创建备份目录 (如果不存在则创建，-p 参数保证不报错)
if [ ! -d "$BACKUP_DIR" ]; then
  mkdir -p "$BACKUP_DIR"
  echo "📁 已自动创建备份目录: $BACKUP_DIR"
fi

echo "⏳ 开始执行 Zabbix 数据库备份..."
