# 故障排查记录：Zabbix-Server 容器启动异常与 MySQL 8.0 初始化失败

**日期：** 2026-02-17
**环境：** Ubuntu 143 (Docker 容器化部署)
**架构栈：** Docker Compose + MySQL 8.0 + Zabbix Server 6.0 + Zabbix Web (Nginx/PHP)

---

## 1. 故障现象 (Symptom)
执行 `docker compose up -d` 首次拉起架构后，通过 `docker compose ps` 检查状态，发现 `zabbix-mysql` 和 `zabbix-web` 状态为 `Up`，但 `zabbix-server` 容器未在运行列表中。
通过 `docker compose ps -a` 确认，`zabbix-server` 容器处于 `Exited` (异常退出) 状态。

## 2. 排查过程 (Troubleshooting Process)
针对退出的 `zabbix-server` 容器，提取其生命周期最后的运行日志进行溯源：
`docker compose logs zabbix-server`

在日志中抓取到两条核心的致命报错线索：
> **线索一（中断点）：** > `ERROR 1419 (HY000) at line 2124: You do not have the SUPER privilege and binary logging is enabled (you *might* want to use the less safe log_bin_trust_function_creators variable)`
> 
> **线索二（致死因）：** > `cannot use database "zabbix": its "users" table is empty`

## 3. 根本原因 (Root Cause Analysis)
这是一起典型的**“数据库初始化中断导致脏数据残留”**故障，逻辑链如下：
1. **安全策略冲突：** Zabbix Server 首次启动时会自动向 MySQL 导入初始表结构和数据。当导入到第 2124 行执行创建触发器/函数的 SQL 时，触发了 MySQL 8.0 默认的严格二进制日志安全策略（不允许普通用户创建函数）。
2. **产生半成品库：** SQL 导入动作瞬间报错中断，导致 `zabbix` 数据库建了一半，关键表（如 `users` 表）未创建。
3. **数据持久化副作用：** 由于配置了宿主机目录挂载 (`volumes: ./mysql-data:/var/lib/mysql`)，这个残缺的“半成品”数据库被永久保存在了宿主机硬盘上。
4. **服务崩溃：** Zabbix Server 重启重试时，发现 `zabbix` 数据库存在，但读取不到 `users` 表，判定数据库结构损坏，抛出 Fatal Error 并崩溃退出。

## 4. 解决方案 (Solution)
要彻底修复此问题，必须同时解决“权限问题”和“脏数据问题”，步骤如下：

**Step 1: 销毁当前破损集群**
```bash
docker compose down
