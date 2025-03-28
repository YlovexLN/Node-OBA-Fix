# 使用node官方镜像作为基础镜像
FROM node:20-bullseye-slim AS build

# 设置工作目录为 /opt/openbmclapi
WORKDIR /opt/openbmclapi

# 安装构建依赖项
RUN apt-get update && \
    apt-get install -y build-essential python3

# 复制项目文件
COPY package-lock.json package.json tsconfig.json ./
COPY copy-files.cjs ./
COPY src ./src

# 安装npm依赖项
RUN npm ci

# 构建项目
RUN npm run build

# 使用一个新的基础镜像来减小镜像体积
FROM node:20-bullseye-slim

# 安装运行时依赖项
RUN apt-get update && \
    apt-get install -y nginx tini && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录为 /opt/openbmclapi
WORKDIR /opt/openbmclapi

# 复制构建出的文件和运行时需要的文件
COPY --from=build /opt/openbmclapi/dist ./dist
COPY --from=build /opt/openbmclapi/node_modules ./node_modules
COPY package.json ./

# 假定配置文件已经在项目目录下
# 如果配置文件在其他位置，请调整路径
COPY nginx /opt/openbmclapi/nginx

# 设置环境变量和端口
ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT

# 设置用户权限
ARG USER=${USER:-root}
RUN chown -R $USER /var/log/nginx /var/lib/nginx
USER $USER

# 设置挂载卷
VOLUME /opt/openbmclapi

# 设置容器启动命令
CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]