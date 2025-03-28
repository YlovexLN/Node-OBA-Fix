ARG BASE_IMAGE=node:20-bullseye-slim
FROM $BASE_IMAGE AS install

WORKDIR /opt/openbmclapi
RUN apt update && \
    apt install -y build-essential python3
COPY package-lock.json package.json tsconfig.json ./
COPY copy-files.cjs ./
RUN npm ci
COPY src ./src
RUN npm run build

# 添加这些行来创建并填充 nginx 目录
RUN mkdir -p /opt/openbmclapi/nginx
COPY path/to/local/nginx/config/files /opt/openbmclapi/nginx/

FROM $BASE_IMAGE AS modules
WORKDIR /opt/openbmclapi

RUN apt update && \
    apt install -y build-essential python3
COPY package-lock.json package.json ./
RUN npm ci --omit=dev

FROM $BASE_IMAGE AS build

RUN apt-get update && \
    apt-get install -y --fix-missing nginx tini && \
    rm -rf /var/lib/apt/lists/*

ARG USER=${USER:-root}

RUN chown -R $USER /var/log/nginx /var/lib/nginx

USER $USER

WORKDIR /opt/openbmclapi
COPY --from=modules /opt/openbmclapi/node_modules ./node_modules
COPY --from=install /opt/openbmclapi/dist ./dist
COPY --from=install /opt/openbmclapi/nginx ./nginx
COPY package.json ./

ENV CLUSTER_PORT=4000
EXPOSE $CLUSTER_PORT
VOLUME /opt/openbmclapi
CMD ["tini", "--", "node", "--enable-source-maps", "dist/index.js"]