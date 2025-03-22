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

GO_PKG:=github.com/OpenTollGate/tollgate-module-relay-go

include $(INCLUDE_DIR)/package.mk
# include $(INCLUDE_DIR)/golang-package.mk
$(eval $(call GoPackage))

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=TollGate Relay Module
	DEPENDS:=$(GO_ARCH_DEPENDS) +uboot-envtools
	PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
	TollGate Relay Module for OpenWrt
endef

define Build/Prepare
	# First call the default prepare to handle git source fetching
	$(call Build/Prepare/Default)

	# Debug: check what's in the build directory after default prepare
	@echo "Contents of PKG_BUILD_DIR after default prepare:"
	@ls -la $(PKG_BUILD_DIR) || echo "Directory empty or doesn't exist"

	# Clean up Go module cache if needed
	cd $(PKG_BUILD_DIR) && \
	rm -f go.mod go.sum && \
	go mod init tollgate-module-relay-go && \
	go mod edit -replace github.com/OpenTollgate/relay=./ && \
	go mod edit -replace github.com/bytedance/sonic=github.com/bytedance/sonic@v1.12.10 && \
	go mod edit -require github.com/bytedance/sonic@v1.12.10 && \
	go mod tidy && \
	go get github.com/fiatjaf/khatru && \
	go get github.com/nbd-wtf/go-nostr && \
	go list -m github.com/bytedance/sonic
endef

define Build/Configure
endef

define Build/Compile
	# Detect target architecture
	ifeq ($(ARCH),arm64)
		GOARCH=arm64
	else ifeq ($(ARCH),aarch64)
		GOARCH=arm64
	else ifeq ($(ARCH),mipsel)
		GOARCH=mipsle
	else ifeq ($(ARCH),mips)
		GOARCH=mips
	else
		$(error Unsupported architecture: $(ARCH))
	endif

	mkdir -p "$(PKG_BUILD_DIR)/.go_work/build/src/github.com/OpenTollGate"
	ln -sf "$(PKG_BUILD_DIR)" "$(PKG_BUILD_DIR)/.go_work/build/src/github.com/OpenTollGate/tollgate-module-relay-go"

	cd $(PKG_BUILD_DIR) && \
	GO111MODULE=on \
	CGO_ENABLED=0 \
	GOOS=linux \
	GOARCH=$(GOARCH) \
	GOFLAGS="-mod=readonly -modcacherw" \
	GOWORK=off \
	go mod tidy && \
	go mod vendor && \
	echo "Vendored dependencies:" && \
	find vendor -type d -maxdepth 2 | grep bytedance || echo "No bytedance in vendor" && \
	echo "Checking vendored sonic version:" && \
	grep "github.com/bytedance/sonic v1.12.10" vendor/modules.txt || (echo "Wrong sonic version!"; exit 1) && \
	GODEBUG=netdns=go+1 \
	go build -v -x -mod=vendor -trimpath \
		-ldflags "-s -w -extldflags '-static' \
		-X main.Version=$(PKG_VERSION) \
		-X main.CommitHash=$(PKG_RELEASE) \
		-X main.BuildTime=$(shell date -u '+%Y-%m-%d_%I:%M:%S%p')" \
	    $(if $(filter mips mipsle,$(GOARCH)),-tags musl) \
	    -tags netgo,osusergo \
		-o $(PKG_BUILD_DIR)/tollgate-relay main.go

	@if [ ! -f "$(PKG_BUILD_DIR)/tollgate-relay" ]; then \
		echo "\n!!! NO BINARY CREATED - BUILD FAILED !!!"; \
		echo "Build artifacts:" ; \
		ls -la $(PKG_BUILD_DIR) ; \
		exit 1; \
	fi

	# Create symlink to binary in expected location for install phase
	mkdir -p $(PKG_BUILD_DIR)/.go_work/build/bin
	ln -sf $(PKG_BUILD_DIR)/tollgate-relay $(PKG_BUILD_DIR)/.go_work/build/bin/tollgate-relay

	@echo "Verifying binary compatibility..."
	@file $(PKG_BUILD_DIR)/tollgate-relay | grep -q "ELF.*$(GOARCH)" || \
		(echo "Binary architecture mismatch!"; file $(PKG_BUILD_DIR)/tollgate-relay; exit 1)

	# # Build the IPK package manually
	# $(MAKE) -C $(PKG_BUILD_DIR) IPKG_BUILD=1 \
	# 	IPKG_ARCH="$(ARCH)" \
	# 	IPKG_RELEASE="$(PKG_RELEASE)" \
	# 	IPKG_VERSION="$(PKG_VERSION)" \
	# 	IPKG_DESCRIPTION="TollGate Relay Module" \
	# 	IPKG_MAINTAINER="Your Name <your@email.com>" \
	# 	IPKG_SECTION="net" \
	# 	IPKG_CATEGORY="Network" \
	# 	package/ipkg
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tollgate-relay $(1)/usr/bin/tollgate-relay
	
	# Add U-Boot env config
	$(INSTALL_DIR) $(1)/etc
	echo "/dev/mtd1 0x0 0x1000 0x10000" > $(1)/etc/fw_env.config
	
	# Create empty directories to prevent warnings
	$(INSTALL_DIR) $(1)/usr/lib/opkg
	$(INSTALL_DIR) $(1)/CONTROL
	touch $(1)/CONTROL/control
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

# # Print IPK path after successful compilation - FIXED VERSION
# ifneq ($(CONFIG_PACKAGE_$(PKG_NAME)),)
#   # Only try to print if package is selected for build
#   PKG_FINISH:=$(shell echo "Successfully built package: $(PKG_NAME)" >&2)
# endif
