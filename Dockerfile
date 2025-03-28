# 使用 node:20-bullseye-slim 作为基础镜像
ARG BASE_IMAGE=node:20-bullseye-slim

# 定义一个构建阶段用于 x64 平台
FROM ${BASE_IMAGE} AS builder-amd64
WORKDIR /opt/openbmclapi

# 更新 apt 并安装必要的依赖
RUN apt update && \
    apt install -y build-essential python3

# 复制 package-lock.json 和 package.json 文件
COPY package-lock.json package.json ./

# 安装项目依赖
RUN npm ci

# 复制源代码和 copy-files.cjs 文件
COPY src ./src
COPY copy-files.cjs ./

# 安装额外的依赖
RUN npm install @mongodb-js/zstd-linux-x64-gnu

# 构建项目
RUN npm run build

# 定义一个构建阶段用于 arm64 平台
FROM ${BASE_IMAGE} AS builder-arm64
WORKDIR /opt/openbmclapi

# 更新 apt 并安装必要的依赖
RUN apt update && \
    apt install -y build-essential python3

# 复制 package-lock.json 和 package.json 文件
COPY package-lock.json package.json ./

# 安装项目依赖
RUN npm ci

# 复制源代码和 copy-files.cjs 文件
COPY src ./src
COPY copy-files.cjs ./

# 安装额外的依赖
RUN npm install @mongodb-js/zstd-linux-arm64-gnu

# 构建项目
RUN npm run build

# 创建最终镜像
FROM ${BASE_IMAGE} AS final
WORKDIR /opt/openbmclapi

# 更新 apt 并安装必要的依赖
RUN apt-get update && \
    apt-get install -y nginx tini && \
    rm -rf /var/lib/apt/lists/*

# 设置用户变量，默认为 root
ARG USER=${USER:-root}

# 修改 nginx 日志和库目录的所有者
RUN chown -R $USER /var/log/nginx /var/lib/nginx

# 切换到指定用户
USER $USER

# 设置工作目录
WORKDIR /opt/openbmclapi

# 根据平台选择正确的构建结果和依赖
ARG TARGETPLATFORM
COPY --from=builder-${TARGETPLATFORM} /opt/openbmclapi/node_modules ./node_modules
COPY --from=builder-${TARGETPLATFORM} /opt/openbmclapi/dist ./dist

# 复制 nginx 配置文件
COPY nginx/ /opt/openbmclapi/nginx

# 复制 package.json 文件
COPY package.json ./

# 设置环境变量和暴露端口
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT

# 设置卷
VOLUME /opt/openbmclapi/cache
VOLUME /opt/openbmclapi/data
VOLUME /opt/openbmclapi/.env

# 设置容器启动时的默认命令
CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]