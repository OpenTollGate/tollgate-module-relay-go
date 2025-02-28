include $(TOPDIR)/rules.mk

PKG_NAME:=tollgate-module-relay-go
PKG_VERSION:=$(shell git rev-list --count HEAD 2>/dev/null || echo "0.0.1").$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
PKG_RELEASE:=1

# Place conditional checks EARLY - before variables that depend on them
ifneq ($(TOPDIR),)
	# Feed-specific settings (auto-clone from git)
	PKG_SOURCE_PROTO:=git
	PKG_SOURCE_URL:=https://github.com/OpenTollGate/tollgate-module-relay-go.git
	PKG_SOURCE_VERSION:=main
	PKG_MIRROR_HASH:=skip
else
	# SDK build context (local files)
	PKG_BUILD_DIR:=$(CURDIR)
endif

PKG_MAINTAINER:=Your Name <your@email.com>
PKG_LICENSE:=CC0-1.0
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=https://github.com/OpenTollGate/tollgate-module-relay-go.git
GO_PKG_BUILD_PKG:=$(GO_PKG)

include $(INCLUDE_DIR)/package.mk
include ../../feeds/packages/lang/golang/golang-package.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=TollGate Relay Module
	DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/$(PKG_NAME)/description
	TollGate Relay Module for OpenWrt
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
	cd $(PKG_BUILD_DIR) && go mod tidy
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/tollgate-relay $(1)/usr/bin/tollgate-relay
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

# Print IPK path after successful compilation
PKG_FINISH:=$(shell echo "Successfully built: $(IPK_FILE)" >&2)
