# docker-learn2

**阅前必知：我的Ubuntu22.04.5系统用户名为：caleb**
**请自行替换**

### 第一步：新环境基础工具及docker安装

**1. 更换系统源为阿里云**

```bash
# 备份旧源
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 一键替换为阿里云源 (针对 Ubuntu 22.04)
sudo sed -i 's/http:\/\/.*archive.ubuntu.com/http:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list
sudo sed -i 's/http:\/\/.*security.ubuntu.com/http:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list

# 更新缓存并安装必备工具
sudo apt-get update
sudo apt-get install -y git vim curl net-tools ca-certificates gnupg lsb-release tree
```

**2. 安装 Docker (使用阿里云 APT 源，避开官网)**

```bash
# 1. 创建密钥目录
sudo mkdir -p /etc/apt/keyrings

# 2. 下载并添加阿里云 Docker GPG 密钥
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. 写入阿里云 Docker 仓库地址 
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. 更新源并安装 Docker 全家桶
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 5. 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

## 第二步：验证战果与权限防坑

安装完成后，我们验证一下这套“全栈标准环境”是不是到位了：

**1. 查看最新版本号：**

```bash
docker compose version
```

(你应该能看到类似 `Docker Compose version v2.x.x` 的字样)

**2. 重新打通你的 caleb 用户权限：**

```bash

# 以管理员身份，安全地把 caleb 追加到 docker 白名单组里

sudo usermod -aG docker caleb
newgrp docker

#newgrp命令是为了**免除重启/注销**，强制刷新当前终端窗口的组身份，让你立刻拥有 docker 组的施法权限
```
**3.创建并配置守护进程文件** 
这会覆盖或创建 `/etc/docker/daemon.json` 文件，解决Docker Hub 官方仓库网络连通性问题,并注入目前相对稳定的国内镜像代理源。

```Bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.nju.edu.cn",
    "https://dockerproxy.com"
  ]
}
EOF
```
## 第三步：docker 部署

既然环境现在是最新、最标准的了，我们把刚才没建完的数据基建目录一口气建好：

**1.创建目录**

```bash
mkdir -p /home/caleb/zabbix-docker
cd /home/caleb/zabbix-docker
mkdir -p mysql-data zabbix-server zabbix-web
```

**2.编写 docker-compose.yml**



```bash
cd /home/caleb/zabbix-docker
vim docker-compose.yml
```

```yaml
version: '3.8'

networks:
  zabbix-net:
    driver: bridge

services:
  mysql-server:
    image: mysql:8.0
    container_name: zabbix-mysql
    networks:
      - zabbix-net
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=root123
      - MYSQL_DATABASE=zabbix
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=zabbix
    volumes:
      - ./mysql-data:/var/lib/mysql
    command:
      - mysqld
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_bin
      - --default-authentication-plugin=mysql_native_password
      - --log_bin_trust_function_creators=1  # 放开函数创建权限


  zabbix-server:
    image: zabbix/zabbix-server-mysql:ubuntu-6.0-latest
    container_name: zabbix-server
    networks:
      - zabbix-net
    ports:
      - "10051:10051"
    environment:
      - DB_SERVER_HOST=mysql-server
      - MYSQL_DATABASE=zabbix
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=zabbix
    depends_on:
      - mysql-server
    volumes:
      - ./zabbix-server:/usr/lib/zabbix/alertscripts

  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:ubuntu-6.0-latest
    container_name: zabbix-web
    networks:
      - zabbix-net
    ports:
      - "80:8080"
    environment:
      - ZBX_SERVER_HOST=zabbix-server
      - DB_SERVER_HOST=mysql-server
      - MYSQL_DATABASE=zabbix
      - MYSQL_USER=zabbix
      - MYSQL_PASSWORD=zabbix
      - PHP_TZ=Asia/Shanghai
    depends_on:
      - mysql-server
      - zabbix-server    
```

## 第四步、启动与验证阶段

**1. 一键启动集群**
在 `docker-compose.yml` 所在的目录（`/home/caleb/zabbix-docker`）下，执行以下命令：

```bash
docker compose up -d
```


**2. 观察集群状态 (项目化思维)** 
在 Compose 的目录里，使用以下命令查看这组关联容器的状态：

```Bash
docker compose ps
```

确保这三个容器的 `STATUS` 都显示为 `Up`。

**3. 查看实时日志 (核心排错能力)** 
这是你验证数据库是否成功初始化的关键。由于我们配置了自动创建 `zabbix` 数据库，MySQL 首次启动时需要花费十几秒钟初始化。 执行以下命令实时观察启动日志：

```Bash
docker compose logs -f
```

如果你在日志中看到 `zabbix-server` 提示连接数据库成功，且没有不断重启的报错，按 `Ctrl+C` 退出日志跟踪。

**4. 终极验证** 打开你本机的浏览器，输入 `http://143主机的IP:80`。 你应该能直接看到 Zabbix 的登录界面（账号：`Admin`，密码：`zabbix`）。
