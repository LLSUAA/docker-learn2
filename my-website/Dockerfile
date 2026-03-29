# 1. 使用轻量级的 Nginx alpine 版本作为底座
FROM nginx:alpine

# 2. 将宿主机当前目录的 index.html，覆盖到容器内 Nginx 的默认网页目录下
COPY index.html /usr/share/nginx/html/index.html

# (注：Nginx 镜像默认自带了启动命令，所以这里甚至不需要写 CMD)
