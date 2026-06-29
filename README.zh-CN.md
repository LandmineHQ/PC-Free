# PC-Free - 在 GitHub Codespaces 中运行 Windows 10 | 免费在浏览器中运行 Windows 10

使用 Docker 和 GitHub Codespaces，在浏览器中运行完整的 Windows 10 环境。免费、快速，而且无需安装。

[![GitHub stars](https://img.shields.io/github/stars/jephersonRD/pc-free?style=social)](https://github.com/jephersonRD/pc-free/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/jephersonRD/pc-free?style=social)](https://github.com/jephersonRD/pc-free/network/members)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Windows 10](https://img.shields.io/badge/Windows-10-0078D6?style=flat&logo=windows&logoColor=white)](https://www.microsoft.com/windows)

**[西班牙语](#西班牙语)** • **[快速开始](#快速开始5-分钟运行-windows-10)** • **[文档](#文档)** • **[报告 Bug](https://github.com/jephersonRD/pc-free/issues)**

![浏览器中的 Windows 10 桌面](./images/windows10-desktop.png)

---

## PC-Free 是什么？

PC-Free 是一个开源项目，可让你使用 GitHub Codespaces 和 Docker 直接在网页浏览器中运行 Windows 10。无需本地安装，无需高性能硬件，而且完全免费。

### 主要优势

- ✅ **100% 免费** - 没有隐藏费用或订阅
- ✅ **基于浏览器** - 可从任意设备访问 Windows
- ✅ **5 分钟部署** - 几分钟内即可部署 Windows 10
- ✅ **无需 PC** - 不拥有 Windows PC 也能运行 Windows
- ✅ **Docker 容器** - 隔离、安全且便携
- ✅ **数据持久化** - 文件和应用在重启后仍会保留
- ✅ **开源** - MIT 许可，社区驱动

---

## 目录

- [功能](#功能)
- [使用场景](#使用场景什么时候使用-pc-free)
- [快速开始](#快速开始5-分钟运行-windows-10)
- [系统要求](#系统要求)
- [安装指南](#快速指南)
- [使用说明](#使用说明)
- [配置选项](#配置选项)
- [FAQ](#常见问题faq)
- [故障排查](#常见问题排查)
- [贡献](#贡献)
- [许可证](#许可证)

---

## 对比：PC-Free 与替代方案

将 PC-Free 与其他 Windows 云解决方案进行对比：

| 功能 | PC-Free | Azure Virtual Desktop | AWS WorkSpaces | 本地虚拟机 |
|------|---------|----------------------|----------------|------------|
| **月费用** | ✅ $0（免费） | ❌ $31-100+ | ❌ $25-75+ | ✅ $0（免费） |
| **设置时间** | ⚡ 5 分钟 | ⏱️ 30+ 分钟 | ⏱️ 30+ 分钟 | ⏱️ 15-30 分钟 |
| **硬件要求** | ✅ 无 | ✅ 无 | ✅ 无 | ❌ 需要高性能 PC |
| **浏览器访问** | ✅ 支持 | ✅ 支持 | ✅ 支持 | ⚠️ 有限 |
| **开源** | ✅ 是 | ❌ 否 | ❌ 否 | ⚠️ 部分 |
| **数据持久化** | ✅ 支持 | ✅ 支持 | ✅ 支持 | ✅ 支持 |

---

## 快速开始：5 分钟运行 Windows 10

### 方法 1：一键 GitHub Codespaces（推荐）

在浏览器中运行 Windows 10 的最快方式：

1. **Fork 此仓库** - 点击右上角的 "Fork" 按钮
2. **打开 Codespace** - 点击 "Code" → "Codespaces" → "Create codespace on main"
3. **等待设置完成** - 环境会自动加载（约 2 分钟）
4. **按照下面的快速指南继续操作**

### 方法 2：手动 Docker 设置

如需在本地安装 Docker，请参见下方完整指南。

---

## 一键脚本方式

如果不想逐条执行下面的命令，可以直接运行仓库提供的 bash 脚本：

```bash
bash scripts/pc-free.sh
```

这个脚本会按 `dockur/windows` 官方方式自动完成 `.env` 生成、`windows10.yml` 生成和容器启动，默认把 `./windows` 挂载到容器内 `/storage` 保存 Windows 数据。

分阶段执行时使用：

```bash
bash scripts/pc-free.sh config
bash scripts/pc-free.sh start
bash scripts/pc-free.sh stop
bash scripts/pc-free.sh restart
bash scripts/pc-free.sh logs
bash scripts/pc-free.sh status
```

完整说明见 [scripts/README.zh-CN.md](scripts/README.zh-CN.md)。

---

## 快速指南

### 1️⃣ 创建 `.env` 文件

```bash
cp .env.example .env
```

编辑 `.env`，设置你的 Windows 用户名和密码。

### 2️⃣ 启动 Windows 容器

```bash
docker compose -f windows10.yml up -d
```

### 3️⃣ 在浏览器中打开 Windows

在 GitHub Codespaces 中，打开转发的 `8006` 端口。

### 可选：使用辅助脚本

```bash
bash scripts/pc-free.sh
```

脚本会生成 `.env`，保持 `windows10.yml` 与 `dockur/windows` 用法一致，并启动容器。

---

## 🧱 `windows10.yml` 文件

```yaml
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "10"
      USERNAME: ${WINDOWS_USERNAME}
      PASSWORD: ${WINDOWS_PASSWORD}
      RAM_SIZE: "10G"
      CPU_CORES: "4"
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - ./windows:/storage
    devices:
      - "/dev/kvm:/dev/kvm"
      - "/dev/net/tun:/dev/net/tun"
    stop_grace_period: 2m
    restart: always
```

---

## 🗝️ `.env` 文件

```ini
WINDOWS_USERNAME=YourUsername
WINDOWS_PASSWORD=YourPassword
WINDOWS_STORAGE=./windows
```

### 🛑 将此文件添加到 `.gitignore`：

```bash
echo ".env" >> .gitignore
```

---

## ▶️ 启动容器

### 首次启动

```bash
docker-compose -f windows10.yml up
```

### 🔌 关闭 PC

```bash
docker stop windows
```

---

## 系统要求

### GitHub Codespaces（推荐）

- GitHub 账号（支持免费套餐）
- 现代网页浏览器（Chrome 90+、Firefox 88+、Edge 90+、Safari 14+）
- Codespace 中 10GB+ 可用存储空间
- 稳定的网络连接（建议 2 Mbps+）

### 本地 Docker 安装

- Docker Engine 20.10 或更高版本
- 20GB+ 可用磁盘空间
- 8GB+ RAM（推荐 16GB）
- KVM 支持（Linux 主机）或 Hyper-V（Windows 主机）
- 操作系统：Linux、macOS 或 Windows 10/11 Pro

---

## 使用说明

### 启动 Windows 环境

启动 Windows 容器：

```bash
docker-compose -f windows10.yml up -d
```

### 停止 Windows 环境

平滑停止 Windows 容器：

```bash
docker stop windows
```

### 重启 Windows

重启容器（在卡死后很有用）：

```bash
docker restart windows
```

### 查看容器日志

监控 Windows 容器活动：

```bash
docker logs -f windows
```

按 Ctrl+C 退出日志查看。

### 完全移除

移除容器和所有数据卷：

```bash
docker-compose -f windows10.yml down -v
```

**⚠️ 警告**：这会永久删除所有 Windows 数据。

---

## 配置选项

### 自定义系统资源

编辑 `windows10.yml` 以调整资源：

```yaml
environment:
  VERSION: "10"              # Windows 版本（10 或 11）
  RAM_SIZE: "10G"           # RAM 分配
  CPU_CORES: "4"            # CPU 核心数
  DISK_SIZE: "64G"          # 虚拟磁盘大小
  USERNAME: ${WINDOWS_USERNAME}
  PASSWORD: ${WINDOWS_PASSWORD}
```

### 切换到 Windows 11

在环境变量中更改 Windows 版本：

```yaml
environment:
  VERSION: "11"  # Windows 11
```

### 启用 RDP 访问

添加 RDP 端口映射，以使用原生远程桌面：

```yaml
ports:
  - "8006:8006"    # Web 界面（noVNC）
  - "3389:3389"    # RDP 协议
```

使用 RDP 客户端连接：`localhost:3389`

### 调整性能设置

对于较慢的系统，请降低资源分配：

```yaml
environment:
  RAM_SIZE: "6G"     # Windows 10 的最低建议值
  CPU_CORES: "2"     # 最低核心数
```

---

## 截图

### Windows 10 桌面界面
![Windows 10 桌面](./images/windows10-desktop.png)

### Windows 11 替代方案
![Windows 11 关于页面](./images/windows11-about.png)

### 基于浏览器的访问
![浏览器界面](./images/browser-interface.png)

---

## 常见问题（FAQ）

### Windows 启动需要多久？

- **首次启动**：5-10 分钟（需要下载 Windows 镜像）
- **后续启动**：2-3 分钟

### 我可以安装其他软件吗？

可以。你拥有完整的管理员权限。已安装的软件会保存在 Docker 数据卷中，并在重启后继续存在。

### 这能在 GitHub 免费套餐上运行吗？

可以。GitHub 免费套餐包含每月 60 小时的 Codespaces，用于常规测试和开发工作通常已经足够。

### 我可以用它玩游戏吗？

能力有限。Codespaces 没有 GPU 加速。轻量或较老的游戏可能可以运行，但现代 3D 游戏运行效果不会很好。

### 这样使用是合法的吗？

是的，前提是你拥有有效的 Windows 许可证。本项目使用官方 Windows 安装方式。请根据你的使用场景查看 Microsoft 的许可条款。

### 这个设置有多安全？

你的 Windows 环境会在私有 GitHub Codespace 中的隔离 Docker 容器内运行。除非你共享 Codespace 链接，否则只有你可以访问。

### 我能从外部访问我的文件吗？

可以，存储在 Docker 数据卷中的文件会在会话之间保留。你也可以挂载外部数据卷，或在 Windows 中使用云存储。

### 我需要多快的网速？

基础使用最低需要 2 Mbps。建议 5 Mbps 以上以获得更流畅的体验。首次设置需要下载约 4GB 的 Windows 镜像。

---

## 常见问题排查

### Windows 容器无法启动

查看 Docker 日志以获取错误信息：

```bash
docker logs windows
```

验证 KVM 访问权限（Linux）：

```bash
ls -la /dev/kvm
```

### 性能缓慢问题

1. 将 RAM 分配降低到 6G
2. 将 CPU 核心数降低到 2
3. 关闭其他资源占用较高的 Codespace 应用
4. 检查 Codespace 资源使用情况

### 无法访问 8006 端口

1. 转到 Codespace 的 "Ports" 标签页
2. 将端口 8006 的可见性设为 "Public"
3. 点击地球图标在浏览器中打开
4. 如果是在本地 Docker 上运行，请检查防火墙设置

### 存储空间已满错误

清理 Docker 缓存和未使用的镜像：

```bash
# 移除未使用的 Docker 数据
docker system prune -a

# 检查可用空间
df -h
```

### 容器不断重启

检查 KVM 是否可用：

```bash
# Linux
ls -l /dev/kvm

# 如果不可用，可能需要在 BIOS 中启用 KVM
```

### 登录后黑屏

1. 等待 2-3 分钟，让桌面加载
2. 尝试刷新浏览器
3. 检查容器是否仍在运行：`docker ps`
4. 重启容器：`docker restart windows`

---

## 路线图：即将推出的功能

- [x] Windows 10 支持
- [x] Docker Compose 设置
- [x] Web 界面（noVNC）
- [x] 持久化存储卷
- [x] Windows 11 支持
- [ ] 一键安装脚本
- [ ] GPU 直通（本地 Docker）
- [ ] 音频支持改进
- [ ] 剪贴板同步
- [ ] 预配置 Windows 模板
- [ ] 多个 Windows 实例
- [ ] 自动备份系统
- [ ] 性能优化指南

[为功能投票 →](https://github.com/jephersonRD/pc-free/discussions)

---

## 贡献

欢迎贡献。帮助改进 PC-Free：

1. **Fork** 项目仓库
2. **创建** 功能分支：`git checkout -b feature/AmazingFeature`
3. **提交** 更改：`git commit -m 'Add AmazingFeature'`
4. **推送** 到分支：`git push origin feature/AmazingFeature`
5. **发起** Pull Request

详细指南请参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

### 贡献方式

- 🐛 报告 Bug 和问题
- 💡 建议新功能
- 📝 改进文档
- 🔧 提交 Bug 修复
- ⭐ Star 并分享此项目

---

## 社区与支持

- 💬 [GitHub Discussions](https://github.com/jephersonRD/pc-free/discussions) - 提问
- 🐛 [Issue Tracker](https://github.com/jephersonRD/pc-free/issues) - 报告 Bug
- ⭐ [Star 此仓库](https://github.com/jephersonRD/pc-free) - 表示支持
- 👤 关注 [@jephersonRD](https://github.com/jephersonRD) 获取更新

---

## 文档

- 📖 [完整文档](https://github.com/jephersonRD/pc-free/wiki)
- 🚀 [高级设置指南](https://github.com/jephersonRD/pc-free/wiki/Advanced-Setup)
- 🔧 [故障排查指南](https://github.com/jephersonRD/pc-free/wiki/Troubleshooting)
- 🎯 [最佳实践](https://github.com/jephersonRD/pc-free/wiki/Best-Practices)

---

## 许可证

本项目根据 MIT License 分发。更多信息请参见 [LICENSE](LICENSE) 文件。

---

## 致谢

特别感谢：

- [dockur/windows](https://github.com/dockur/windows) - Docker Windows 镜像项目
- [GitHub Codespaces](https://github.com/features/codespaces) - 云开发环境
- 所有[优秀贡献者](https://github.com/jephersonRD/pc-free/graphs/contributors)

---

## 支持项目

如果 PC-Free 对你有帮助，可以考虑：

- ⭐ **Star** 此仓库
- 🐦 在社交媒体上**分享**
- 📝 写一篇关于它的博客文章
- 🤝 贡献代码或文档

---

## 西班牙语

### 西班牙语快速开始

1. Fork 此仓库
2. 在 Codespace 中打开
3. 按照上方快速指南操作
4. 访问端口 8006

[查看完整文档 →](https://github.com/jephersonRD/pc-free/wiki)

---

<div align="center">

**如果你觉得这个项目有帮助，请为此仓库 Star。**

为需要 Windows 但没有 PC 的开发者制作

[⬆ 返回顶部](#pc-free---在-github-codespaces-中运行-windows-10--免费在浏览器中运行-windows-10)

</div>
