# 这是什么？

OpenBMCLAPI 是一个高效、灵活的 Minecraft 资源分发系统，旨在为国内 Minecraft 社区提供稳定、快速的资源下载服务

它通过分布式节点的方式，将资源文件分发到各地的服务器上，从而提升玩家的下载体验

本项目是 OpenBMCLAPI 官方 Node.JS 客户端的一个改进版本，修复了原版中的一些问题，并增加了一些额外功能的支持

本项目主要为使用各网盘文件通过 302 重定向方式进行文件分发的节点提供额外支持

因此，通过简单的配置即可在低性能、低带宽服务器上搭建数个这样的 OpenBMCLAPI 节点

# 配置

| 环境变量                    | 必填 | 默认值                  | 说明                                                                                                                                          |
|----------------------------|------|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| CLUSTER_ID                 |  是  | -                      | 集群 ID                                                                                                                                       |
| CLUSTER_SECRET             |  是  | -                      | 集群密钥                                                                                                                                       |
| CLUSTER_IP                 |  否  | 自动获取公网出口IP      | 用户访问时使用的 IP 或域名                                                                                                                       |
| CLUSTER_PORT               |  否  | 4000                   | 监听端口                                                                                                                                       |
| CLUSTER_PUBLIC_PORT        |  否  | CLUSTER_PORT           | 对外端口                                                                                                                                       |
| CLUSTER_BYOC               |  否  | false                  | 是否使用自定义证书 (BYOC=Bring you own certificate, 当使用国内服务器需要备案时, 需要启用这个参数来使用你自己的带证书的域名, 需搭配下方SSL相关设置使用) |
| SSL_KEY                    |  否  | -                      | (仅当开启BYOC时) SSL 证书私钥, 可以直接粘贴证书内容，也可以填写文件名                                                                              |
| SSL_CERT                   |  否  | -                      | (仅当开启BYOC时) SSL 证书公钥, 可以直接粘贴证书内容，也可以填写文件名                                                                              |
| ENABLE_NGINX               |  否  | false                  | 使用 nginx 提供文件服务                                                                                                                         |
| DISABLE_ACCESS_LOG         |  否  | false                  | 禁用访问日志输出                                                                                                                                |
| ENABLE_UPNP                |  否  | false                  | 启用 UPNP 端口映射                                                                                                                             |
| RESTART_PROCESS            |  否  | true                   | 在当前进程意外退出后调用自身功能自动重启进程                                                                                                      |
| ENABLE_EXIT_DELAY          |  否  | false                  | 使用自定义固定秒数而非内置退避策略的重启前等待时间                                                                                                |
| EXIT_DELAY                 |  否  | 3                      | 在重启/退出前进行自定义秒数的延迟                                                                                                                |
| LOGLEVEL                   |  否  | info                   | 切换日志等级                                                                                                                                   |
| NO_DAEMON                  |  否  | false                  | 是否禁用子进程模式(推荐设置为false即不禁用, 禁用后无法使用自动重启或退出前延迟功能)                                                                 |
| STARTUP_LIMIT              |  否  | 90                     | 24h启动的最多次数(以请求上线次数为准, 超过后将定时刷新，等待24h内上线次数不超限时再启动，避免被主控封禁)                                              |
| STARTUP_LIMIT_WAIT_TIMEOUT |  否  | 600                    | 上线次数超限时等待响应的超时时间, 单位为秒, 一般10分钟即可无需修改                                                                                 |
| CLUSTER_NO_ENABLE          |  否  | false                  | 是否禁用节点上线（会正常走开启流程、同步，但不会请求上线，一般用于调试或同步文件，请勿在生产环境中使用）                                               |
| WEBHOOK_RECONNECT          |  否  | false                  | 是否启用节点重连时触发的 Webhook                                                                                                                 |
| WEBHOOK_STARTUP            |  否  | false                  | 是否启用节点上线时触发的 Webhook                                                                                                                 |
| WEBHOOK_SHUTDOWN           |  否  | false                  | 是否启用节点下线时触发的 Webhook                                                                                                                 |
| WEBHOOK_ERROR              |  否  | false                  | 是否启用节点工作进程异常退出时触发的 Webhook                                                                                                      |
| 对应webhook配置项_MESSAGE   |  否  | -                      | 自定义触发 Webhook 时发送的消息，如：WEBHOOK_ERROR_MESSAGE / WEBHOOK_SHUTDOWN_MESSAGE                                                            |
| WEBHOOK_URL                |  否  | -                      | Webhook URL，如：WEBHOOK_URL=http://127.0.0.1:8080/webhook                                                                                     |
| SYNC_CONCURRENCY           |  否  | -                      | 同步文件时并发数量，默认从主控获取（注：此配置项主要为主控不下发20并发的情况提供保底，因此设置的上限值为20，设置超过20时默认取最高值20）                  |
| NO_CONNECT                 |  否  | false                  | 禁用连接主控功能（也不会请求证书）（可配合CLUSTER_NO_ENABLE+自定义证书搭建针对单节点多线的多端负载均衡）                                              |
| DISABLE_OPTI_LOG           |  否  | false                  | 显示未优化的日志（请求地址会显示?后的部分，如优化后/measure/1，优化前/measure/1?s=w4Yh2cnF6Ctmo4CwUxZve2jN1UU&e=m8u973ob）                          |
| DISABLE_NEW_SYNC_STATUS    |  否  | false                  | 禁用新的同步状态显示，会显示单个文件的下载进度显示并更改为原版的排版                                                                                 |
| CLUSTER_NAME               |  否  | Cluster                | 自定义节点名称, 目前会在同步、webhook时应用: 同步文件显示为 [Sync-节点名称], webhook显示为 [Cluster] 节点已下线                                      |

备注：Webhook 的整体结构为 `[节点名称] 消息内容`，如：`[Cluster] 节点已下线`、`[Cluster] 节点已重连`

发送到 WEBHOOK_URL 设置的地址里, 结构为 { content: "发送的内容" }

在部分性能较低的设备上，程序内置的自动重启功能可能会导致重新连接时出现问题（例如卡死等）

为了避免这种情况，建议使用外部工具（如 MCSM 的自动重启功能）来管理程序的启动与重启

此时，您可以在配置文件中将 `RESTART_PROCESS` 设置为 `false`，以关闭程序自身的自动重启功能

当 `RESTART_PROCESS` 设置为 `false` 时，程序在意外退出后将不会自动重启，而是直接结束进程

如果启用了 `ENABLE_EXIT_DELAY`，程序在重启前会使用自定义的延迟时间。如果未设置 `EXIT_DELAY` 且 `ENABLE_EXIT_DELAY` 为 `true`，程序将默认使用 3 秒的延迟时间

如果未设置 `EXIT_DELAY` 且 `RESTART_PROCESS` 为 `false`，程序在退出前将强制使用默认的 3 秒延迟时间（此时 `ENABLE_EXIT_DELAY` 的设置将被忽略）

需要注意的是，如果您在源码中发现了其他环境变量，它们可能是为了方便开发而临时添加的，可能会随时更改，因此不建议在生产环境中使用这些变量

# 安装

## 所需环境

- Node.js 20 以上
- 一个支持 Node.js 的系统
- 一个支持 Node.js 的架构

## 安装包

### 下载

从 [Github Release](https://github.com/bangbang93/openbmclapi/releases) 中选择对应你的系统的最新版本

请跳转到[设置参数](#设置参数)部分

## 从源码安装

### 设置环境

1. 去 <https://nodejs.org/zh-cn/> 下载LTS版本的nodejs并安装

2. Clone 并安装依赖

```bash
git clone https://github.com/Zhang12334/node-oba-fix
cd node-oba-fix
## 安装依赖
npm i
## 编译
npm run build
## 运行
node dist/index.js
```

3. 如果你看到了 `CLUSTER_ID is not set` 的报错, 说明一切正常, 该设置参数了

## 设置参数

在项目根目录创建一个文件, 名为 `.env`

写入如下内容

```env
CLUSTER_ID=你的节点ID
CLUSTER_SECRET=你的节点密钥
CLUSTER_PORT=你的开放端口
# 更多变量请看上方变量的详细解释
```
## Alist使用方法
在.env中加上
```env
CLUSTER_STORAGE=alist
CLUSTER_STORAGE_OPTIONS={"url":"http://127.0.0.1:5244/dav","basePath":"oba","username":"admin","password":"admin" }
#                                      ↑AList地址(别忘了加/dav)         ↑文件路径          ↑账号(有webdav权限)  ↑密码
```
按照需要修改

## 温馨提示

如果您正在从 Go 端迁移至 Node 端，请确保 Alist 中的目录结构符合以下要求：

### 示例 1

如果您的目录结构如下：

```file_tree
oba/
├── download/
│   ├── 00/
│   ├── 01/
│   ├── 03/
│   └── xx/（其他文件夹）
├── measure/
│   ├── 1
│   ├── 2
│   └── 3
```

则 `basePath` 应设置为 `"oba/download"`

### 示例 2

如果您的目录结构如下：

```file_tree
download/
├── 00/
├── 01/
├── 03/
└── xx/（其他文件夹）
measure/
├── 1
├── 2
└── 3
```

则 `basePath` 应设置为 `"download"`

### 说明
- `basePath` 是 Alist 中资源文件的根目录路径，需根据实际目录结构填写
- 配置完成后，运行程序，它将自动拉取文件，并在文件同步完成后上线

# 同步数据

openbmclapi 会自行同步需要的文件, 但是初次同步可能会速度过慢, 如果您的节点是个全量节点, 可以通过以下命令使用rsync快速同步
以下三台rsync服务器是相同的, 你可以选择任意一台进行同步
- `rsync -rzvP openbmclapi@home.933.moe::openbmclapi cache`
- `rsync -avP openbmclapi@storage.yserver.ink::bmcl cache`
- `rsync -azvrhP openbmclapi@openbmclapi.home.mxd.moe::data cache`

# 致谢

- [**bangbang93**](https://github.com/bangbang93) 本项目 Fork 自 bangbang93 的 OpenBMCLAPI 项目
- [**ApliNi**](https://github.com/ApliNi) Dashboard API 改自 ApliNi 的 aplPanel 项目