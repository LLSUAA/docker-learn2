# 1. 基础环境 (FROM): 站在巨人的肩膀上。我们直接拉取官方体积最小的 Python 3.9 环境。
FROM python:3.9-slim

# 2. 工作目录 (WORKDIR): 进入容器后的默认路径。如果目录不存在，系统会自动创建。
WORKDIR /app

# 3. 拷贝代码 (COPY): 把宿主机当前目录(.)的所有文件，拷贝到容器的 /app 目录(.)中。
COPY . .

# 4. 启动命令 (CMD): 容器启动时默认执行的指令。注意必须是 JSON 数组格式。
CMD ["python", "app.py"]
