# 定义基础镜像参数
ARG BASE_IMAGE=node:20-bullseye-slim

# 基础阶段：安装必要的构建工具
FROM $BASE_IMAGE AS base
RUN apt update && \
    apt install -y build-essential python3 && \
    rm -rf /var/lib/apt/lists/*

# 安装阶段：构建项目
FROM base AS install
WORKDIR /opt/openbmclapi
COPY package-lock.json package.json tsconfig.json ./
RUN npm ci
COPY src ./src
RUN npm run build

# 模块阶段：仅安装生产依赖
FROM base AS modules
WORKDIR /opt/openbmclapi
COPY package-lock.json package.json ./
RUN npm ci --omit=dev

# 构建阶段：最终镜像
FROM $BASE_IMAGE AS build

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y nginx tini && \
    rm -rf /var/lib/apt/lists/*

# 设置用户和权限
ARG USER=${USER:-openbmclapi}
RUN useradd -m $USER && \
    chown -R $USER /var/log/nginx /var/lib/nginx
USER $USER

# 工作目录和文件复制
WORKDIR /opt/openbmclapi
COPY --from=modules /opt/openbmclapi/node_modules ./node_modules
COPY --from=install /opt/openbmclapi/dist ./dist
COPY nginx/ /opt/openbmclapi/nginx
COPY package.json ./

# 环境变量和端口暴露
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT

# 挂载整个 /opt/openbmclapi
VOLUME /opt/openbmclapi

# 启动命令
CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]