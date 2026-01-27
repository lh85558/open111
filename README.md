# THDN-PrintServer OpenWrt17 固件定制项目

## 项目简介
基于 Atheros AR9531/9533 SoC 的 OpenWrt 17.01.x 稳定版固件定制项目，集成 CUPS 中文打印服务，支持 HP LaserJet 1020/1020plus 打印机。

## 主要功能
- ✅ OpenWrt 17.01.7 稳定版 (ar71xx/generic)
- ✅ CUPS 2.4.x 中文打印服务
- ✅ HP LaserJet 1020/1020plus 驱动预装
- ✅ USB 打印机支持
- ✅ 定时重启功能 (每日凌晨 4:00)
- ✅ 中文 Web 界面
- ✅ 16MB Flash 优化

## 默认配置
- LAN IP: 192.168.10.1
- Web 登录: admin / thdn12345678
- Wi-Fi SSID: THDN-dayin
- Wi-Fi 密码: thdn12345678
- 主机名: THDN-PrintServer

## 构建环境
- Ubuntu 22.04 LTS
- 全部依赖升级至最新稳定版
- 国内源码镜像加速

## 快速开始
```bash
# 克隆项目
git clone <repository-url>
cd THDN-PrintServer-OpenWrt17

# 一键编译
./build.sh

# 生成的固件位于
ls -la bin/targets/ar71xx/generic/
```

## 项目结构
```
.
├── build.sh              # 主构建脚本
├── configs/              # 配置文件模板
├── packages/              # 自定义软件包
├── scripts/               # 辅助脚本
├── patches/               # 补丁文件
└── docs/                  # 文档说明
```

## 支持的设备
- 基于 AR9531/9533 SoC 的路由器
- 16MB Flash 存储
- USB 接口支持

## 许可证
MIT License
