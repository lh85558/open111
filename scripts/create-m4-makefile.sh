#!/bin/bash
# 创建 tools/m4/Makefile 文件，使其直接使用系统 m4

# 使用 printf 来确保 tab 字符正确
printf '%s\n' '#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=m4
PKG_VERSION:=1.4.18
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@GNU/m4
PKG_HASH:=ab2633921a5cd38e48797bf5521ad259bdc4b9790b38a06139d63993579c69c7

HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk

# 直接使用系统 m4，跳过构建
define Host/Compile
	true
endef

define Host/Install
	true
endef

$(STAGING_DIR_HOST)/stamp/.m4_installed: $(HOST_BUILD_DIR)/.built
	touch $@

$(HOST_BUILD_DIR)/.built:
	touch $@

$(HOST_BUILD_DIR)/.configured:
	touch $@

$(HOST_BUILD_DIR)/.prepared:
	touch $@' > tools/m4/Makefile

# 使用 sed 确保命令行以 tab 字符开头
sed -i 's/^	//' tools/m4/Makefile
sed -i 's/^true$/\ttrue/' tools/m4/Makefile
sed -i 's/^touch $@$/\ttouch $@/' tools/m4/Makefile
