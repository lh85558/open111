#
# Copyright (C) 2023 THDN-PrintServer Project
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=cups-config
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/cups-config
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=CUPS Configuration for THDN-PrintServer
  DEPENDS:=+cups +cups-filters +hplip
endef

define Package/cups-config/description
  CUPS configuration files and startup scripts for THDN-PrintServer
  including HP LaserJet 1020/1020plus driver setup and Chinese localization.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/cups-config/install
	$(INSTALL_DIR) $(1)/etc/cups
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/share/cups/model
	$(INSTALL_DIR) $(1)/root
	
	# CUPS 主配置文件
	$(INSTALL_CONF) ./files/cupsd.conf $(1)/etc/cups/cupsd.conf
	$(INSTALL_CONF) ./files/printers.conf $(1)/etc/cups/printers.conf
	$(INSTALL_CONF) ./files/cups-files.conf $(1)/etc/cups/cups-files.conf
	
	# 启动脚本
	$(INSTALL_BIN) ./files/cups-setup $(1)/etc/init.d/cups-setup
	
	# HP LaserJet 驱动配置
	$(INSTALL_DATA) ./files/HP_LaserJet_1020.ppd $(1)/usr/share/cups/model/
	$(INSTALL_DATA) ./files/HP_LaserJet_1020plus.ppd $(1)/usr/share/cups/model/
	
	# 中文本地化文件
	$(INSTALL_DATA) ./files/zh_CN.po $(1)/usr/share/locale/zh_CN/LC_MESSAGES/cups_zh_CN.po
	
	# 打印机自动检测脚本
	$(INSTALL_BIN) ./files/detect-printer.sh $(1)/root/detect-printer.sh
endef

define Package/cups-config/postinst
#!/bin/sh
# 启动 CUPS 服务
/etc/init.d/cups enable
/etc/init.d/cups start

# 运行打印机检测脚本
sh /root/detect-printer.sh

exit 0
endef

$(eval $(call BuildPackage,cups-config))
