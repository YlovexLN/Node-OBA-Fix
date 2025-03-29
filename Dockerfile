ARG BASE_IMAGE=node:20-bullseye-slim
FROM $BASE_IMAGE AS install

WORKDIR /opt/openbmclapi

# 安装必要的系统依赖
RUN apt update && \
    apt install -y build-essential python3 && \
    rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY package-lock.json package.json tsconfig.json ./
# 添加这一行，确保 copy-files.cjs 被复制
COPY copy-files.cjs ./

# 安装依赖
RUN npm ci

# 复制源代码
COPY src ./src

# 构建项目
RUN npm run build

FROM $BASE_IMAGE AS modules
WORKDIR /opt/openbmclapi

# 安装生产环境依赖
RUN apt update && \
    apt install -y build-essential python3 && \
    rm -rf /var/lib/apt/lists/*

COPY package-lock.json package.json ./
RUN npm ci --omit=dev

FROM $BASE_IMAGE AS build

# 安装 Nginx 和 Tini
RUN apt-get update && \
    apt-get install -y nginx tini && \
    rm -rf /var/lib/apt/lists/*

ARG USER=${USER:-root}

# 设置权限
RUN chown -R $USER /var/log/nginx /var/lib/nginx

USER $USER

WORKDIR /opt/openbmclapi

# 从 modules 阶段复制 node_modules
COPY --from=modules /opt/openbmclapi/node_modules ./node_modules

# 从 install 阶段复制构建产物
COPY --from=install /opt/openbmclapi/dist ./dist

# 复制其他文件
COPY nginx/ /opt/openbmclapi/nginx
COPY package.json ./

# 配置环境变量和暴露端口
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT
VOLUME /opt/openbmclapi/cache

CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]