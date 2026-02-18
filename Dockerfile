FROM python:3.9-slim
WORKDIR /app
COPY . .
# 加上 -u 参数，强制 Python 实时输出日志，拒绝缓冲！
CMD ["python", "-u", "app.py"]
