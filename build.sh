#!/bin/bash
# THDN-PrintServer OpenWrt17 一键构建脚本
# 适用于 Ubuntu 22.04 LTS

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目配置
PROJECT_NAME="THDN-PrintServer"
OPENWRT_VERSION="17.01.7"
TARGET="ar71xx/generic"
PROFILE="Default"
LAN_IP="192.168.10.1"
WIFI_SSID="THDN-dayin"
WIFI_KEY="thdn12345678"
ADMIN_PASS="thdn12345678"
HOSTNAME="THDN-PrintServer"

# 打印信息
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统
check_system() {
    log_info "检查系统环境..."
    
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        log_warn "建议在 Ubuntu 22.04 LTS 上构建"
    fi
    
    # 检查必要工具
    local required_tools=("git" "wget" "curl" "gawk" "gettext" "xsltproc" "rsync" "unzip" "python3")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "缺少必要工具: $tool"
            log_info "请运行: sudo apt update && sudo apt install -y build-essential libncurses5-dev zlib1g-dev libssl-dev ${required_tools[*]}"
            exit 1
        fi
    done
    
    log_info "系统检查通过"
}

# 安装依赖
install_dependencies() {
    log_info "安装构建依赖..."
    
    sudo apt update
    sudo apt install -y \
        build-essential ccache ecj fastjar file g++ gawk \
        gettext git java-propose-classpath libelf-dev libncurses5-dev \
        libncursesw5-dev libssl-dev python2.7-dev python3 \
        unzip wget python3-distutils python3-setuptools python3-dev \
        rsync subversion swig time xsltproc zlib1g-dev \
        libxml-parser-perl gcc-multilib flex git-core \
        libusb-dev libusb-1.0-0-dev uuid-dev libacl1-dev \
        liblzo2-dev liblzma-dev zlib1g-dev e2fsprogs \
        m4 pkg-config autoconf autoconf-archive autotools-dev \
        libtool python3-pip python-is-python3
    
    log_info "依赖安装完成"
}

# 克隆 OpenWrt 源码
clone_openwrt() {
    log_info "克隆 OpenWrt 源码..."
    
    if [ ! -d "openwrt" ]; then
        # 使用官方源码仓库
        git clone https://github.com/openwrt/openwrt.git
        cd openwrt
        git checkout v17.01.7
    else
        cd openwrt
        log_info "源码已存在，更新到最新版本"
        git fetch origin
        git checkout v17.01.7
    fi
    
    # 更新和安装 feeds
    log_info "更新 feeds..."
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    cd ..
    log_info "OpenWrt 源码准备完成"
}

# 配置构建
configure_build() {
    log_info "配置构建选项..."
    
    cd openwrt
    
    # 复制配置文件
    cp ../configs/thdn-config .config
    
    # 应用配置
    make defconfig
    
    # 下载必要的软件包
    make download -j$(nproc)
    
    cd ..
    log_info "构建配置完成"
}

# 自定义软件包
custom_packages() {
    log_info "准备自定义软件包..."
    
    # 创建自定义软件包目录
    mkdir -p openwrt/package/custom
    
    # 复制自定义软件包
    cp -r packages/* openwrt/package/custom/
    
    log_info "自定义软件包准备完成"
}

# 应用补丁
apply_patches() {
    log_info "应用补丁..."
    
    cd openwrt
    
    # 应用定时重启补丁
    if [ -f "../patches/auto-reboot.patch" ]; then
        patch -p1 < ../patches/auto-reboot.patch
    fi
    
    cd ..
    log_info "补丁应用完成"
}

# 开始编译
start_build() {
    log_info "开始编译固件..."
    
    cd openwrt
    
    # 清理之前的构建
    make clean
    
    # 开始编译
    make -j$(nproc) V=s
    
    cd ..
    log_info "编译完成"
}

# 生成固件信息
generate_info() {
    log_info "生成固件信息..."
    
    local build_date=$(date +"%Y%m%d")
    local firmware_dir="bin/targets/${TARGET}"
    
    if [ -d "openwrt/${firmware_dir}" ]; then
        mkdir -p output
        cp openwrt/${firmware_dir}/*.bin output/
        
        # 生成固件信息文件
        cat > output/firmware-info.txt << EOF
THDN-PrintServer OpenWrt17 固件信息
=====================================
构建时间: $(date)
OpenWrt版本: ${OPENWRT_VERSION}
目标平台: ${TARGET}
配置文件: configs/thdn-config

默认配置:
- LAN IP: ${LAN_IP}
- Web登录: root / ${ADMIN_PASS}
- Wi-Fi SSID: ${WIFI_SSID}
- Wi-Fi密码: ${WIFI_KEY}
- 主机名: ${HOSTNAME}

包含功能:
- CUPS 中文打印服务
- HP LaserJet 1020/1020plus 驱动
- USB 打印机支持
- 定时重启功能
- 中文 Web 界面

固件文件:
$(ls -la output/*.bin)
EOF
        
        log_info "固件已生成到 output/ 目录"
        log_info "固件信息已保存到 output/firmware-info.txt"
    else
        log_error "未找到生成的固件文件"
        exit 1
    fi
}

# 主函数
main() {
    log_info "开始构建 ${PROJECT_NAME} OpenWrt17 固件..."
    
    check_system
    install_dependencies
    clone_openwrt
    custom_packages
    apply_patches
    configure_build
    start_build
    generate_info
    
    log_info "构建完成！"
    log_info "固件文件位于: output/"
}

# 运行主函数
main "$@"
