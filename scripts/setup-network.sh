#!/bin/bash
# THDN-PrintServer 网络配置脚本
# 设置默认网络参数

set -e

# 默认配置值
LAN_IP="192.168.10.1"
WIFI_SSID="THDN-dayin"
WIFI_KEY="thdn12345678"
ADMIN_PASS="thdn12345678"
HOSTNAME="THDN-PrintServer"

# 检查是否以root权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误: 请以root权限运行此脚本"
    exit 1
fi

# 创建网络配置文件
setup_network() {
    echo "配置网络参数..."
    
    # 创建网络配置
    cat > /etc/config/network << EOF
config interface 'loopback'
        option ifname 'lo'
        option proto 'static'
        option ipaddr '127.0.0.1'
        option netmask '255.0.0.0'

config globals 'globals'
        option ula_prefix 'fd00::/48'

config interface 'lan'
        option type 'bridge'
        option ifname 'eth0'
        option proto 'static'
        option ipaddr '${LAN_IP}'
        option netmask '255.255.255.0'
        option ip6assign '60'

config interface 'wan'
        option ifname 'eth1'
        option proto 'dhcp'

config interface 'wan6'
        option ifname 'eth1'
        option proto 'dhcpv6'
EOF

    # 创建无线配置
    cat > /etc/config/wireless << EOF
config wifi-device 'radio0'
        option type 'mac80211'
        option channel '11'
        option hwmode '11g'
        option path 'platform/qca953x_wmac'
        option htmode 'HT20'
        option disabled '0'

config wifi-iface 'default_radio0'
        option device 'radio0'
        option network 'lan'
        option mode 'ap'
        option ssid '${WIFI_SSID}'
        option encryption 'psk2'
        option key '${WIFI_KEY}'
EOF

    # 创建系统配置
    cat > /etc/config/system << EOF
config system
        option hostname '${HOSTNAME}'
        option timezone 'CST-8'
        option ttylogin '0'
        option log_size '64'
        option urandom_seed '0'

config timeserver 'ntp'
        option enabled '1'
        option enable_server '0'
        list server '0.openwrt.pool.ntp.org'
        list server '1.openwrt.pool.ntp.org'
        list server '2.openwrt.pool.ntp.org'
        list server '3.openwrt.pool.ntp.org'
EOF

    # 创建 DHCP 配置
    cat > /etc/config/dhcp << EOF
config dnsmasq
        option domainneeded '1'
        option boguspriv '1'
        option filterwin2k '0'
        option localise_queries '1'
        option rebind_protection '1'
        option rebind_localhost '1'
        option local '/lan/'
        option domain 'lan'
        option expandhosts '1'
        option nonegcache