# ============================================
# 全栈 Dockerfile — Java 后端 + Node.js 前端
# docker build -t app . && docker run -p 80:80 app
# ============================================

# Stage 1: 构建前端
FROM node:20-alpine AS frontend-builder
WORKDIR /app
RUN apk add --no-cache git
COPY repo/frontend/package*.json ./
RUN npm config set registry https://registry.npmmirror.com && npm install
COPY repo/frontend/ .
RUN npm run build

# Stage 2: 构建 Java 后端
FROM maven:3.9-eclipse-temurin-17 AS backend-builder
WORKDIR /app
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list && \
    apt-get update -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
COPY repo/backend/pom.xml .
RUN mvn dependency:go-offline -B
COPY repo/backend/src ./src
RUN mvn package -DskipTests

# Stage 3: 最终镜像（JRE + Nginx）
FROM tomcat:9.0-jdk17-openjdk-slim

# 安装 nginx 和 git
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list && \
    apt-get update -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends \
    nginx \
    git && \
    rm -rf /var/lib/apt/lists/*

# 部署 Java 后端
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=backend-builder /app/target/backend.war /usr/local/tomcat/webapps/ROOT.war

# 拷贝前端构建产物
COPY --from=frontend-builder /app/dist /usr/share/nginx/html

# 创建 /app 目录并复制源码和 Git 仓库用于开发调试
RUN mkdir -p /app && chmod 755 /app
COPY repo/ /app/
COPY .git /app/.git

# Nginx 配置：前端静态文件 + 反向代理后端 Tomcat
RUN printf 'server {\n\
    listen 80;\n\
    location / {\n\
        root /usr/share/nginx/html;\n\
        index index.html;\n\
        try_files \$uri \$uri/ /index.html;\n\
    }\n\
    location /api/ {\n\
        proxy_pass http://127.0.0.1:8080;\n\
        proxy_set_header Host \$host;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

# 启动脚本：启动后端 + Nginx
RUN printf '#!/bin/bash\nset -e\ncatalina.sh start\nnginx -g "daemon off;"' > /start.sh \
    && chmod +x /start.sh

EXPOSE 80
CMD ["/start.sh"]


# ========== SSH plugin (pluggable, for Cursor/Trae vibe coding) ==========
# Drop-in block: copy the same `ssh_plugin/` folder next to this Dockerfile
# and paste this block at the end of any business Dockerfile. Nothing else
# in the business logic needs to change.
#
# Optional customisation (add BEFORE this block if needed):
#   ENV SSH_PASSWORD=mysecret           # change root password (default: password)
#   ENV SSH_PORT=2222                   # change sshd port     (default: 22)
#   ENV ORIG_ENTRYPOINT=/docker-entrypoint.sh   # chain base image's ENTRYPOINT
#                                                # (e.g. postgres, mysql, jupyter)
#
# NOTE: this block runs as root (required to install sshd). If the base image
#       uses a non-root USER, restore it at the very end, e.g. `USER node`.
USER root
COPY ssh_plugin/ /opt/ssh_plugin/
RUN chmod +x /opt/ssh_plugin/*.sh && /opt/ssh_plugin/install_ssh.sh
EXPOSE 22
ENTRYPOINT ["/opt/ssh_plugin/entrypoint.sh"]
# USER <original-user>   # uncomment & set if the base image requires non-root
# ========== end SSH plugin ==========