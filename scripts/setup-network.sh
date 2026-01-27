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
        option nonegcache '0'
        option cachesize '1000'
        option authoritative '1'
        option readethers '1'
        option leasefile '/tmp/dhcp.leases'
        option resolvfile '/tmp/resolv.conf.auto'
        option nonwildcard '1'
        list server '/mycompany.local/10.0.0.1'

config dhcp 'lan'
        option interface 'lan'
        option ignore '0'
        option start '100'
        option limit '150'
        option leasetime '12h'
        option dhcpv6 'server'
        option ra 'server'
        list dhcp_option '3,${LAN_IP}'
        list dhcp_option '6,${LAN_IP}'

config dhcp 'wan'
        option interface 'wan'
        option ignore '1'

config odhcpd 'odhcpd'
        option maindhcp '0'
        option leasefile '/tmp/hosts/odhcpd'
        option leasetrigger '/usr/sbin/odhcpd-update'
EOF

    # 创建防火墙配置
    cat > /etc/config/firewall << EOF
config defaults
        option syn_flood '1'
        option input 'ACCEPT'
        option output 'ACCEPT'
        option forward 'REJECT'

config zone
        option name 'lan'
        option input 'ACCEPT'
        option output 'ACCEPT'
        option forward 'ACCEPT'
        option network 'lan'

config zone
        option name 'wan'
        option input 'REJECT'
        option output 'ACCEPT'
        option forward 'REJECT'
        option masq '1'
        option mtu_fix '1'
        option network 'wan wan6'

config forwarding
        option src 'lan'
        option dest 'wan'

config rule
        option name 'Allow-DHCP-Renew'
        option src 'wan'
        option proto 'udp'
        option dest_port '68'
        option target 'ACCEPT'
        option family 'ipv4'

config rule
        option name 'Allow-Ping'
        option src 'wan'
        option proto 'icmp'
        option icmp_type 'echo-request'
        option family 'ipv4'
        option target 'ACCEPT'

config rule
        option name 'Allow-IGMP'
        option src 'wan'
        option proto 'igmp'
        option family 'ipv4'
        option target 'ACCEPT'

config rule
        option name 'Allow-DHCPv6'
        option src 'wan'
        option proto 'udp'
        option src_ip 'fc00::/6'
        option dest_ip 'fc00::/6'
        option dest_port '546'
        option family 'ipv6'
        option target 'ACCEPT'

config rule
        option name 'Allow-MLD'
        option src 'wan'
        option proto 'icmp'
        option src_ip 'fe80::/10'
        list icmp_type '130/0'
        list icmp_type '131/0'
        list icmp_type '132/0'
        list icmp_type '143/0'
        option family 'ipv6'
        option target 'ACCEPT'

config rule
        option name 'Allow-ICMPv6-Input'
        option src 'wan'
        option proto 'icmp'
        list icmp_type 'echo-request'
        list icmp_type 'echo-reply'
        list icmp_type 'destination-unreachable'
        list icmp_type 'packet-too-big'
        list icmp_type 'time-exceeded'
        list icmp_type 'bad-header'
        list icmp_type 'unknown-header-type'
        option limit '1000/sec'
        option family 'ipv6'
        option target 'ACCEPT'

config rule
        option name 'Allow-ICMPv6-Forward'
        option src 'wan'
        option dest '*'
        option proto 'icmp'
        list icmp_type 'echo-request'
        list icmp_type 'echo-reply'
        list icmp_type 'destination-unreachable'
        list icmp_type 'packet-too-big'
        list icmp_type 'time-exceeded'
        list icmp_type 'bad-header'
        list icmp_type 'unknown-header-type'
        option limit '1000/sec'
        option family 'ipv6'
        option target 'ACCEPT'

config rule
        option name 'Allow-IPSec-ESP'
        option src 'wan'
        option dest 'lan'
        option proto 'esp'
        option target 'ACCEPT'

config rule
        option name 'Allow-ISAKMP'
        option src 'wan'
        option dest 'lan'
        option dest_port '500'
        option proto 'udp'
        option target 'ACCEPT'

config include
        option path '/etc/firewall.user'
EOF

    echo "网络配置完成"
}

# 设置管理员密码
setup_admin_password() {
    echo "设置管理员密码..."
    echo -e "${ADMIN_PASS}\n${ADMIN_PASS}" | passwd root
    echo "管理员密码设置完成"
}

# 重启网络服务
restart_network() {
    echo "重启网络服务..."
    /etc/init.d/network restart
    /etc/init.d/dnsmasq restart
    /etc/init.d/firewall restart
    echo "网络服务重启完成"
}

# 主函数
main() {
    echo "开始配置 THDN-PrintServer 网络参数..."
    echo ""
    
    setup_network
    setup_admin_password
    restart_network
    
    echo ""
    echo "============================================"
    echo "THDN-PrintServer 网络配置完成！"
    echo "============================================"
    echo "LAN IP地址: ${LAN_IP}"
    echo "Wi-Fi SSID: ${WIFI_SSID}"
    echo "Wi-Fi密码: ${WIFI_KEY}"
    echo "管理员密码: ${ADMIN_PASS}"
    echo "主机名: ${HOSTNAME}"
    echo "============================================"
    echo ""
    echo "请使用以下地址访问管理界面:"
    echo "  http://${LAN_IP}"
    echo ""
    echo "请使用以下地址访问 CUPS 管理界面:"
    echo "  http://${LAN_IP}:631"
    echo "============================================"
}

# 运行主函数
main "$@"
