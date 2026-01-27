# THDN-PrintServer OpenWrt17 固件定制项目

基于 OpenWrt 17.01.7 稳定版，为 Atheros AR9531/9533 SoC 定制的打印服务器固件，集成 CUPS 中文打印服务和 HP LaserJet 1020/1020plus 驱动。

## 🎯 项目特色

- **即插即用打印服务**：集成 CUPS 2.4.x 中文打印服务
- **完整驱动支持**：预装 HP LaserJet 1020/1020plus 驱动
- **USB打印机支持**：自动检测和配置 USB 打印机
- **智能定时重启**：每日凌晨 4:00 自动重启，保持系统稳定
- **中文界面**：完整的简体中文 Web 管理界面
- **一键编译**：自动化构建脚本，直接输出可用固件

## 📋 默认配置

| 配置项 | 默认值 |
|--------|--------|
| LAN IP地址 | 192.168.10.1 |
| Web管理账号 | admin |
| Web管理密码 | thdn12345678 |
| Wi-Fi SSID | THDN-dayin |
| Wi-Fi密码 | thdn12345678 |
| 主机名 | THDN-PrintServer |

## 🏗️ 技术规格

### 硬件要求
- **目标芯片**：Atheros AR9531/9533 SoC
- **Flash存储**：16MB+
- **RAM内存**：64MB+
- **USB接口**：支持 USB 2.0

### 软件版本
- **OpenWrt版本**：17.01.7 (ar71xx/generic)
- **CUPS版本**：2.4.x (最新稳定版)
- **HPLIP版本**：3.23.x (最新稳定版)
- **构建环境**：Ubuntu 22.04 LTS

## 🚀 快速开始

### 1. 一键构建
```bash
# 克隆项目
git clone https://github.com/your-repo/thdn-printserver.git
cd thdn-printserver

# 运行构建脚本
./build.sh
```

### 2. 固件刷入
构建完成后，固件文件位于 `output/` 目录：
- `sysupgrade.bin` - 系统升级固件
- `factory.bin` - 工厂固件

### 3. 使用配置
1. 刷入固件后访问 http://192.168.10.1
2. 使用 admin/thdn12345678 登录管理界面
3. 连接 USB 打印机到路由器
4. 访问 http://192.168.10.1:631 管理打印机

## 📁 项目结构

```
thdn-printserver/
├── build.sh                    # 主构建脚本
├── configs/
│   └── thdn-config            # OpenWrt 配置文件
├── packages/
│   └── cups-config/           # CUPS 自定义软件包
│       ├── Makefile
│       ├── files/
│       │   ├── cupsd.conf     # CUPS 配置文件
│       │   ├── detect-printer.sh  # 打印机检测脚本
│       │   ├── HP_LaserJet_1020.ppd    # HP 1020 驱动
│       │   └── HP_LaserJet_1020plus.ppd # HP 1020plus 驱动
│       └── src/
├── patches/
│   ├── auto-reboot.patch      # 定时重启补丁
│   └── cups-chinese.patch     # CUPS 中文支持补丁
├── scripts/
│   ├── setup-network.sh       # 网络配置脚本
│   └── build-info.sh          # 构建信息生成脚本
└── .github/
    └── workflows/
        └── build.yml          # GitHub Actions 工作流
```

## 🔧 功能详解

### CUPS 打印服务
- **自动启动**：系统启动时自动启动 CUPS 服务
- **中文界面**：完整的简体中文 Web 管理界面
- **驱动集成**：预装 HP LaserJet 1020/1020plus PPD 驱动文件
- **自动检测**：USB 打印机插入时自动检测和配置

### 网络配置
- **固定IP**：LAN口固定为 192.168.10.1
- **Wi-Fi热点**：自动创建 THDN-dayin 热点
- **主机名**：系统主机名为 THDN-PrintServer

### 系统优化
- **定时重启**：每日凌晨 4:00 自动重启，保持系统稳定
- **中文支持**：系统界面和日志中文显示
- **安全设置**：默认关闭 TTY 登录，提高安全性

## 🛠️ 自定义构建

### 修改配置
编辑 `configs/thdn-config` 文件来自定义构建配置：
```bash
# 修改默认IP地址
sed -i 's/192.168.10.1/你的IP地址/g' configs/thdn-config

# 修改Wi-Fi密码
sed -i 's/thdn12345678/你的密码/g' configs/thdn-config
```

### 添加软件包
在 `build.sh` 中修改 `PACKAGES` 变量：
```bash
PACKAGES="base-files libc libgcc libpthread librt busybox ..."
```

### 应用补丁
将自定义补丁文件放入 `patches/` 目录，构建时会自动应用。

## 📊 GitHub Actions 自动构建

项目配置了完整的 GitHub Actions 工作流，支持：
- **自动构建**：推送代码时自动触发构建
- **缓存优化**：缓存下载文件和编译结果，加速构建
- **固件发布**：自动发布固件到 GitHub Releases
- **多平台支持**：基于 Ubuntu 22.04 LTS 构建环境

## 🔍 故障排除

### 构建失败
1. 检查网络连接，确保能访问 OpenWrt 源码
2. 清理缓存：`rm -rf openwrt/`
3. 查看构建日志：`tail -f build.log`

### 打印机无法识别
1. 检查 USB 连接是否正常
2. 查看系统日志：`logread | grep usb`
3. 手动检测：`/usr/bin/detect-printer.sh`

### Web界面无法访问
1. 检查网络连接：ping 192.168.10.1
2. 检查 CUPS 服务：/etc/init.d/cups status
3. 重启服务：/etc/init.d/cups restart

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来改进项目：

1. Fork 项目
2. 创建特性分支：`git checkout -b feature/新功能`
3. 提交更改：`git commit -m '添加新功能'`
4. 推送分支：`git push origin feature/新功能`
5. 提交 Pull Request

## 📄 许可证

本项目基于 OpenWrt 开源项目，遵循 GPL v2 许可证。

## 🙏 致谢

- [OpenWrt](https://openwrt.org/) - 开源路由器固件项目
- [CUPS](https://www.cups.org/) - Common Unix Printing System
- [HPLIP](https://developers.hp.com/hp-linux-imaging-and-printing) - HP Linux Imaging and Printing

## 📞 技术支持

如有问题，请通过以下方式获取帮助：
- 提交 GitHub Issue
- 查看项目 Wiki
- 参考 OpenWrt 官方文档

---

**注意**：刷机有风险，请谨慎操作。建议在刷机前备份原厂固件。
