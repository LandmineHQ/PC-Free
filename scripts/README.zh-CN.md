# PC-Free 脚本使用说明

这个目录提供了一个统一的 bash 管理脚本，用于替代 README 中需要逐条执行的命令。

## 一键安装并启动

```bash
bash scripts/pc-free.sh
```

等价于：

```bash
bash scripts/pc-free.sh install
```

它会按 `dockur/windows` 官方方式生成配置并启动容器，默认把当前仓库下的 `./windows` 目录挂载到容器内 `/storage`。

它会依次执行：

1. 生成 `.env`，并自动探测宿主机 `RAM_SIZE` 和 `CPU_CORES`
2. 生成 `windows10.yml`
3. 启动 Windows 容器

启动后在 GitHub Codespaces 的端口面板中打开 `8006` 端口即可访问 Windows。

如果 `.env` 已存在，脚本会保留用户名和密码，只刷新 `RAM_SIZE` 与 `CPU_CORES`。如果你还需要重建整个 `.env` 或 `windows10.yml`：

```bash
bash scripts/pc-free.sh config --force
bash scripts/pc-free.sh start
```

## 分阶段执行

### 可选：配置 Docker daemon 存储

```bash
bash scripts/pc-free.sh storage
```

通常不需要执行这个命令。只有当 Docker 默认磁盘空间不足，且你明确想把 Docker daemon 的 `data-root` 改到其他目录时才使用它。

### 仅生成 `.env` 和 `windows10.yml`

```bash
bash scripts/pc-free.sh config
```

### 启动 Windows

```bash
bash scripts/pc-free.sh start
```

### 停止 Windows

```bash
bash scripts/pc-free.sh stop
```

### 重启 Windows

```bash
bash scripts/pc-free.sh restart
```

### 查看日志

```bash
bash scripts/pc-free.sh logs
```

### 查看状态

```bash
bash scripts/pc-free.sh status
```

### 完全移除容器和数据卷

```bash
bash scripts/pc-free.sh remove
```

这个命令会要求你输入 `DELETE` 进行确认。

## 常用选项

### 指定 Docker 数据目录

```bash
bash scripts/pc-free.sh storage --data-root /tmp/docker-data
```

这是给 `storage` 子命令使用的 Docker daemon 存储目录，不是 Windows 虚拟机的数据目录。

### 指定 Windows 数据目录

```bash
bash scripts/pc-free.sh install --storage ./windows
```

该目录会挂载到容器内 `/storage`，用于保存 Windows 数据。

### 重新生成配置文件

```bash
bash scripts/pc-free.sh config --force
```

### 跳过删除确认

```bash
bash scripts/pc-free.sh remove --yes
```
