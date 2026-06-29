# PC-Free

使用 `dockur/windows` 项目结构，通过 Docker 运行 Windows。

当前仓库只保留启动 Windows 容器所需的 Compose 配置和辅助脚本。

## 文件

- `windows10.yml` - Docker Compose 配置
- `.env.example` - 环境变量示例
- `scripts/pc-free.sh` - 设置和容器生命周期管理脚本
- `scripts/README.zh-CN.md` - 脚本使用说明

## 快速开始

生成 `.env` 并启动容器：

```bash
bash scripts/pc-free.sh
```

脚本会询问 Windows 用户名和密码，然后自动探测宿主机 RAM 与 CPU 核心数并写入 `.env`。

启动后，在浏览器中打开转发的 `8006` 端口访问 Windows 桌面。

## 手动启动

创建 `.env`：

```bash
cp .env.example .env
```

编辑 `.env`：

```ini
WINDOWS_USERNAME=pcfree
WINDOWS_PASSWORD=change-me
WINDOWS_STORAGE=./windows
RAM_SIZE=8G
CPU_CORES=4
```

启动：

```bash
docker compose -f windows10.yml up -d
```

## 配置

`windows10.yml` 使用 `dockur/windows` 发布的官方 Docker 镜像：

```yaml
image: dockurr/windows
```

Windows 持久化数据通过以下挂载保存：

```yaml
volumes:
  - ${WINDOWS_STORAGE:-./windows}:/storage
```

辅助脚本会自动写入：

```ini
RAM_SIZE=<自动探测的宿主机内存>
CPU_CORES=<自动探测的宿主机 CPU 核心数>
```

强制重新探测资源：

```bash
bash scripts/pc-free.sh config
```

重建 `.env` 和 `windows10.yml`：

```bash
bash scripts/pc-free.sh config --force
```

## 常用命令

```bash
bash scripts/pc-free.sh start
bash scripts/pc-free.sh stop
bash scripts/pc-free.sh restart
bash scripts/pc-free.sh logs
bash scripts/pc-free.sh status
bash scripts/pc-free.sh remove
```

`remove` 会在确认后删除 Compose 容器和数据卷。

## 要求

- Docker Engine 和 Docker Compose
- Linux KVM 支持，或兼容的 Codespaces 环境
- 足够存放 Windows 镜像和持久化数据的磁盘空间

## 说明

- GitHub 项目名是 `dockur/windows`。
- Docker 镜像名是 `dockurr/windows`。
- `.env` 和 `windows/` 已加入 git 忽略。
