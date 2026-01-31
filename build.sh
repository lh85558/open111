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
    
    # 检查并修改 tools/Makefile 文件，移除 m4 相关的构建规则
    if [ -f "tools/Makefile" ]; then
        log_info "修改 tools/Makefile 文件，移除 m4 相关的构建规则..."
        # 备份原始 Makefile
        cp tools/Makefile tools/Makefile.backup
        
        # 使用更安全的方法修改 Makefile，避免破坏语法结构
        # 使用 awk 一次性处理所有修改，保持 Makefile 语法完整
        awk '{
            # 跳过 m4 相关的规则定义
            if ($0 ~ /^tools\/m4\/(compile|install|clean):/) {
                next
            }
            # 跳过 m4 安装标记文件的规则
            if ($0 ~ /\$(STAGING_DIR_HOST)\/stamp\/.m4_installed:/) {
                next
            }
            # 移除编译列表中的 m4 相关目标
            if ($0 ~ /tools\/m4\/(compile|install)/) {
                # 替换包含 m4 目标的行，保持其他目标不变
                gsub(/tools\/m4\/compile\s+/, "")
                gsub(/\s+tools\/m4\/compile/, "")
                gsub(/tools\/m4\/install\s+/, "")
                gsub(/\s+tools\/m4\/install/, "")
                # 如果行变为空，跳过
                if ($0 == "") {
                    next
                }
            }
            # 打印处理后的行
            print
        }' tools/Makefile > tools/Makefile.new
        
        # 替换原始文件
        mv tools/Makefile.new tools/Makefile
        
        log_info "已修改 tools/Makefile 文件，移除 m4 相关的构建规则"
        
        # 验证修改是否成功
        if grep -q "tools/m4" tools/Makefile; then
            log_warn "tools/Makefile 中仍然包含 m4 相关内容，可能需要手动检查"
        else
            log_info "tools/Makefile 修改验证成功，已移除所有 m4 相关内容"
        fi
    else
        log_warn "tools/Makefile 文件不存在，跳过修改"
    fi
    
    # 更新和安装 feeds
    log_info "更新 feeds..."
    
    # 添加重试机制，最多重试 3 次
    local max_retries=3
    local retry=0
    local success=0
    
    while [ $retry -lt $max_retries ]; do
        log_info "尝试更新 feeds (第 $((retry+1)) 次)..."
        # 只更新核心 feeds，跳过 telephony 和 routing feed，避免相关错误
        timeout 300 ./scripts/feeds update packages luci
        if [ $? -eq 0 ]; then
            success=1
            break
        else
            log_warn "feeds 更新失败，$((max_retries - retry - 1)) 次重试机会..."
            retry=$((retry + 1))
            sleep 10
        fi
    done
    
    if [ $success -eq 0 ]; then
        log_error "feeds 更新失败，尝试使用备用方法..."
        # 只更新核心 feeds
        timeout 120 ./scripts/feeds update packages
        if [ $? -ne 0 ]; then
            log_error "核心 feeds 更新也失败，构建无法继续"
            exit 1
        fi
    fi
    
    # 安装 feeds，只安装核心 feeds
    log_info "安装 feeds..."
    ./scripts/feeds install -a -p packages
    ./scripts/feeds install -a -p luci
    
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
    
    # 1. 修改 boot 文件，添加定时重启
    if [ -f "package/base-files/files/etc/init.d/boot" ]; then
        if ! grep -q "THDN-PrintServer: 设置定时重启" package/base-files/files/etc/init.d/boot; then
            sed -i '/touch \/tmp\/resolv.conf.auto/a \
\t# THDN-PrintServer: 设置定时重启\n\techo "0 4 * * * /sbin/reboot" >> /etc/crontabs/root\n\t/etc/init.d/cron enable\n\t/etc/init.d/cron start' package/base-files/files/etc/init.d/boot
        fi
    fi
    
    # 2. 修改 banner 文件
    if [ -f "package/base-files/files/etc/banner" ]; then
        sed -i 's/ CHAOS CALMER (Chaos Calmer, r4937)/ THDN-PrintServer OpenWrt17 (Build %C)\n 基于 OpenWrt 17.01.7 稳定版\n 集成 CUPS 打印服务\n 支持 HP LaserJet 1020\/1020plus/' package/base-files/files/etc/banner
    fi
    
    # 3. 修改 system 配置
    if [ -f "package/base-files/files/etc/config/system" ]; then
        sed -i 's/option hostname\t\tOpenWrt/option hostname\t\tTHDN-PrintServer/' package/base-files/files/etc/config/system
        sed -i 's/option ttylogin\t\t1/option ttylogin\t\t0/' package/base-files/files/etc/config/system
    fi
    
    # 4. 修改 network 配置
    if [ -f "package/base-files/files/etc/config/network" ]; then
        sed -i 's/option ipaddr\t\t192.168.1.1/option ipaddr\t\t192.168.10.1/' package/base-files/files/etc/config/network
    fi
    
    cd ..
    log_info "补丁应用完成"
}

# 开始编译
start_build() {
    log_info "开始编译固件..."
    
    cd openwrt
    
    # 设置构建参数，禁用并行构建以避免资源竞争
    export MAKEFLAGS="-j1"
    export FORCE_UNSAFE_CONFIGURE=1
    export NINJAJOBS=1
    
    # 增加系统资源限制
    ulimit -c unlimited
    ulimit -n 4096
    
    # 尝试跳过 OpenWrt 自带的 m4 工具构建，直接使用系统安装的 m4
    log_info "检查系统 m4 工具..."
    if command -v m4 > /dev/null; then
        log_info "系统已安装 m4，准备跳过构建..."
        
        # 在清理构建之前就创建必要的目录和文件，确保它们在构建系统启动时就存在
        # 创建 build 目录和标记文件
        mkdir -p build_dir/host/m4-1.4.18
        touch build_dir/host/m4-1.4.18/.built
        touch build_dir/host/m4-1.4.18/.configured
        touch build_dir/host/m4-1.4.18/.prepared
        
        # 创建 staging 目录并链接系统 m4
        mkdir -p staging_dir/host/bin
        ln -sf /usr/bin/m4 staging_dir/host/bin/m4
        
        # 创建安装标记文件
        mkdir -p staging_dir/host/stamp
        touch staging_dir/host/stamp/.m4_installed
        
        log_info "已准备好跳过 m4 构建，使用系统 m4"
    else
        log_warn "系统未安装 m4，将尝试构建..."
    fi
    
    # 清理之前的构建（注意：这会删除我们创建的文件，所以需要在清理后重新创建）
    make clean
    
    # 重新创建必要的目录和文件，因为 make clean 会删除它们
    if command -v m4 > /dev/null; then
        log_info "重新创建 m4 相关文件..."
        # 创建 build 目录和标记文件
        mkdir -p build_dir/host/m4-1.4.18
        touch build_dir/host/m4-1.4.18/.built
        touch build_dir/host/m4-1.4.18/.configured
        touch build_dir/host/m4-1.4.18/.prepared
        
        # 创建 staging 目录并链接系统 m4
        mkdir -p staging_dir/host/bin
        ln -sf /usr/bin/m4 staging_dir/host/bin/m4
        
        # 创建安装标记文件
        mkdir -p staging_dir/host/stamp
        touch staging_dir/host/stamp/.m4_installed
        
        log_info "已重新创建 m4 相关文件，使用系统 m4"
    fi
    
    # 尝试逐个构建工具，以提高稳定性
    log_info "构建工具..."
    
    # 强制使用系统 m4，确保在整个构建过程中都不会尝试构建 OpenWrt 自带的 m4
    if command -v m4 > /dev/null; then
        log_info "强制使用系统 m4，跳过 OpenWrt m4 构建..."
        
        # 多次创建必要的目录和文件，确保构建系统不会尝试构建 m4
        for i in {1..3}; do
            # 创建 build 目录和标记文件
            mkdir -p build_dir/host/m4-1.4.18
            touch build_dir/host/m4-1.4.18/.built
            touch build_dir/host/m4-1.4.18/.configured
            touch build_dir/host/m4-1.4.18/.prepared
            
            # 创建 staging 目录并链接系统 m4
            mkdir -p staging_dir/host/bin
            # 先删除可能存在的链接，然后重新创建
            rm -f staging_dir/host/bin/m4 2>/dev/null || true
            ln -sf /usr/bin/m4 staging_dir/host/bin/m4 2>/dev/null || true
            
            # 创建安装标记文件
            mkdir -p staging_dir/host/stamp
            touch staging_dir/host/stamp/.m4_installed
            
            # 确保文件权限正确
            chmod 755 build_dir/host/m4-1.4.18 2>/dev/null || true
            chmod 644 build_dir/host/m4-1.4.18/* 2>/dev/null || true
            chmod 755 staging_dir/host/bin 2>/dev/null || true
            chmod 755 staging_dir/host/bin/m4 2>/dev/null || true
            chmod 755 staging_dir/host/stamp 2>/dev/null || true
            chmod 644 staging_dir/host/stamp/* 2>/dev/null || true
        done
        
        # 直接修改 tools/m4/Makefile，使其直接使用系统 m4 而不是尝试构建
        if [ -f "tools/m4/Makefile" ]; then
            log_info "修改 tools/m4/Makefile 文件，使其直接使用系统 m4..."
            # 备份原始 Makefile
            cp tools/m4/Makefile tools/m4/Makefile.backup
            
            # 使用脚本创建新的 Makefile，确保 tab 字符正确
            bash ../scripts/create-m4-makefile.sh
            
            log_info "已修改 tools/m4/Makefile 文件，使其直接使用系统 m4"
        fi
        
        # 验证系统 m4 是否可用
        if [ -f "staging_dir/host/bin/m4" ]; then
            log_info "系统 m4 已成功链接到 staging 目录"
        else
            log_warn "无法创建 m4 链接，但将继续使用系统 m4"
        fi
        
        log_info "已强制配置使用系统 m4，构建系统将跳过 m4 构建"
    else
        # 为 m4 添加额外的编译参数以解决兼容性问题
        export CFLAGS="-O2 -fno-stack-protector -U_FORTIFY_SOURCE"
        export CXXFLAGS="-O2 -fno-stack-protector -U_FORTIFY_SOURCE"
        make tools/m4/compile V=s
        if [ $? -ne 0 ]; then
            log_error "m4 构建失败"
            exit 1
        fi
        unset CFLAGS CXXFLAGS
    fi
    
    # 构建 pkg-config
    log_info "构建 pkg-config..."
    make tools/pkg-config/compile V=s
    if [ $? -ne 0 ]; then
        log_error "pkg-config 构建失败"
        exit 1
    fi
    
    # 构建 mtools
    log_info "构建 mtools..."
    make tools/mtools/compile V=s
    if [ $? -ne 0 ]; then
        log_error "mtools 构建失败"
        exit 1
    fi
    
    # 直接构建 squashfs4 工具，确保固件打包所需的工具可用
    log_info "构建 squashfs4 工具..."
    make tools/squashfs4/compile V=s
    if [ $? -ne 0 ]; then
        log_error "squashfs4 构建失败"
        exit 1
    fi
    
    # 跳过 tools/compile 目标，直接进入固件构建阶段
    # 因为我们已经构建了所有关键工具（pkg-config、mtools、squashfs4）
    log_info "跳过完整工具链构建，直接构建固件..."
    
    # 再次修改 tools/Makefile，确保在构建固件时不会尝试构建 m4
    if [ -f "tools/Makefile" ]; then
        log_info "再次修改 tools/Makefile 文件，确保在构建固件时不会尝试构建 m4..."
        # 备份原始 Makefile
        cp tools/Makefile tools/Makefile.backup2
        
        # 使用更安全的方法修改 Makefile，避免破坏语法结构
        # 使用 awk 一次性处理所有修改，保持 Makefile 语法完整
        awk '{
            # 跳过 m4 相关的规则定义
            if ($0 ~ /^tools\/m4\/(compile|install|clean):/) {
                next
            }
            # 跳过 m4 安装标记文件的规则
            if ($0 ~ /\$(STAGING_DIR_HOST)\/stamp\/.m4_installed:/) {
                next
            }
            # 移除编译列表中的 m4 相关目标
            if ($0 ~ /tools\/m4\/(compile|install)/) {
                # 替换包含 m4 目标的行，保持其他目标不变
                gsub(/tools\/m4\/compile\s+/, "")
                gsub(/\s+tools\/m4\/compile/, "")
                gsub(/tools\/m4\/install\s+/, "")
                gsub(/\s+tools\/m4\/install/, "")
                # 如果行变为空，跳过
                if ($0 == "") {
                    next
                }
            }
            # 打印处理后的行
            print
        }' tools/Makefile > tools/Makefile.new
        
        # 替换原始文件
        mv tools/Makefile.new tools/Makefile
        
        log_info "已再次修改 tools/Makefile 文件，移除 m4 相关的构建规则"
        
        # 验证修改是否成功
        if grep -q "tools/m4" tools/Makefile; then
            log_warn "tools/Makefile 中仍然包含 m4 相关内容，可能需要手动检查"
        else
            log_info "tools/Makefile 修改验证成功，已移除所有 m4 相关内容"
        fi
    fi
    
    # 再次确保 m4 标记文件存在，防止构建系统在构建固件时尝试构建 m4
    if command -v m4 > /dev/null; then
        log_info "再次确保 m4 标记文件存在，防止构建系统在构建固件时尝试构建 m4..."
        # 再次创建必要的目录和文件
        mkdir -p build_dir/host/m4-1.4.18
        touch build_dir/host/m4-1.4.18/.built
        touch build_dir/host/m4-1.4.18/.configured
        touch build_dir/host/m4-1.4.18/.prepared
        
        mkdir -p staging_dir/host/bin
        rm -f staging_dir/host/bin/m4 2>/dev/null || true
        ln -sf /usr/bin/m4 staging_dir/host/bin/m4 2>/dev/null || true
        
        mkdir -p staging_dir/host/stamp
        touch staging_dir/host/stamp/.m4_installed
        
        log_info "m4 标记文件已再次确保存在，构建系统将在构建固件时跳过 m4 构建"
    fi
    
    # 构建完整固件
    log_info "构建完整固件..."
    make V=s
    
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
