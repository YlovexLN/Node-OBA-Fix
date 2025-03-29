ARG BASE_IMAGE=node:20-bullseye-slim
FROM $BASE_IMAGE AS install

WORKDIR /opt/openbmclapi

# 安装系统依赖以编译原生模块
RUN apt update && \
    apt install -y build-essential python3 pkg-config libzstd-dev && \
    rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY package-lock.json package.json tsconfig.json ./
COPY copy-files.cjs ./

# 安装所有依赖（包括dev）
RUN npm ci

# 复制源代码并构建
COPY src ./src
RUN npm run build

FROM $BASE_IMAGE AS modules
WORKDIR /opt/openbmclapi

# 安装编译所需的系统依赖
RUN apt update && \
    apt install -y build-essential python3 pkg-config libzstd-dev && \
    rm -rf /var/lib/apt/lists/*

# 复制包管理文件并安装依赖
COPY package-lock.json package.json ./
# 先安装全部依赖（含dev），编译后移除dev依赖
RUN npm ci && npm prune --production

FROM $BASE_IMAGE AS build

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y nginx tini && \
    rm -rf /var/lib/apt/lists/*

ARG USER=${USER:-root}
RUN chown -R $USER /var/log/nginx /var/lib/nginx
USER $USER

WORKDIR /opt/openbmclapi

# 从各阶段复制必要文件
COPY --from=modules /opt/openbmclapi/node_modules ./node_modules
COPY --from=install /opt/openbmclapi/dist ./dist
COPY nginx/ /opt/openbmclapi/nginx
COPY package.json ./

# 配置和启动
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT
VOLUME /opt/openbmclapi/cache
VOLUME /opt/openbmclapi/.env

CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]