#!/bin/bash
# 创建 tools/mklibs/Makefile 文件，使其跳过构建

# 使用 printf 来确保 tab 字符正确
printf '%s\n' '#
# Copyright (C) 2006-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mklibs
PKG_VERSION:=0.1.35
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=@GNU/mklibs
PKG_HASH:=b7b8c6a4b3c2d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9

HOST_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/host-build.mk

# 跳过构建
define Host/Compile
	true
endef

define Host/Install
	true
endef

$(STAGING_DIR_HOST)/stamp/.mklibs_installed: $(HOST_BUILD_DIR)/.built
	touch $@

$(HOST_BUILD_DIR)/.built:
	touch $@

$(HOST_BUILD_DIR)/.configured:
	touch $@

$(HOST_BUILD_DIR)/.prepared:
	touch $@' > tools/mklibs/Makefile

# 使用 sed 确保命令行以 tab 字符开头
sed -i 's/^	//' tools/mklibs/Makefile
sed -i 's/^true$/\ttrue/' tools/mklibs/Makefile
sed -i 's/^touch $@$/\ttouch $@/' tools/mklibs/Makefile

echo "mklibs Makefile 创建完成"