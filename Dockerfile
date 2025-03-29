# 使用 node:20-bullseye-slim 作为基础镜像
ARG BASE_IMAGE=node:20-bullseye-slim
FROM $BASE_IMAGE AS install

# 设置工作目录
WORKDIR /opt/openbmclapi

# 更新 apt 并安装必要的依赖
RUN apt update && \
    apt install -y build-essential python3 libzstd-dev

# 复制 package-lock.json, package.json 和 tsconfig.json 文件
COPY package-lock.json package.json tsconfig.json ./

# 安装项目依赖并重建二进制模块
RUN npm ci && npm rebuild

# 复制源代码和 copy-files.cjs 文件
COPY src ./src
COPY copy-files.cjs ./

# 构建项目
RUN npm run build

# 使用基础镜像创建 modules 阶段
FROM $BASE_IMAGE AS modules
WORKDIR /opt/openbmclapi

# 更新 apt 并安装必要的依赖
RUN apt update && \
    apt install -y build-essential python3 libzstd-dev

# 复制 package-lock.json 和 package.json 文件
COPY package-lock.json package.json ./

# 安装生产环境依赖
RUN npm i --omit=dev

# 使用基础镜像创建 build 阶段
FROM $BASE_IMAGE AS build

# 更新 apt 并安装 nginx 和 tini，并清理 apt 缓存
RUN apt-get update && \
    apt-get install -y nginx tini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置用户变量，默认为 node
ARG USER=node

# 修改 nginx 日志和库目录的所有者
RUN chown -R $USER /var/log/nginx /var/lib/nginx

# 切换到指定用户
USER $USER

# 设置工作目录
WORKDIR /opt/openbmclapi

# 复制 node_modules 和构建的 dist 文件夹
COPY --from=modules /opt/openbmclapi/node_modules ./node_modules
COPY --from=install /opt/openbmclapi/dist ./dist

# 复制 nginx 配置文件
COPY nginx/ /opt/openbmclapi/nginx

# 复制 package.json 文件
COPY package.json ./

# 设置环境变量和暴露端口
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT

# 设置卷
VOLUME /opt/openbmclapi/dist
VOLUME /opt/openbmclapi/node_modules
VOLUME /opt/openbmclapi/cache
VOLUME /opt/openbmclapi/data
VOLUME /opt/openbmclapi/.env

# 设置容器启动时的默认命令
CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]