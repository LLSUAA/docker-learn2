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
# 3. 执行：通过 docker exec 驱动容器内的 mysqldump 工具导出数据
# 注意：> 符号将容器内部的标准输出重定向到宿主机的物理文件中
docker exec zabbix-mysql mysqldump -uroot -proot123 zabbix > "$BACKUP_FILE"

# 4. 校验：捕获并判断上一条命令的退出状态码 ($?)
if [ $? -eq 0 ]; then
  echo "✅ 备份成功: $BACKUP_FILE"
  
  # 5. 收尾：仅在当前备份成功的前提下，执行过期数据清理，防止数据断档
  echo "🗑️ 开始清理 7 天前的旧备份..."
  # 语法解析: 查找备份目录下，名字匹配，且修改时间大于 7 天的文件，直接删除
  find "$BACKUP_DIR" -type f -name "zabbix_db_*.sql" -mtime +7 -delete
  
  echo "🏁 备份与清理流程执行完毕。"
else
  echo "❌ 致命错误: 数据库备份失败！"
  # 发生错误时，将刚才生成的 0 字节废文件删除，防止占用空间并干扰排错
  rm -f "$BACKUP_FILE"
  exit 1
fi
