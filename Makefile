include $(TOPDIR)/rules.mk

PKG_NAME:=tollgate-module-relay-go

# Get git information from the source repository
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/OpenTollGate/tollgate-module-relay-go.git
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_VERSION:=verify_changes_in_binary
# You'll need to generate a new hash after first clone
PKG_MIRROR_HASH:=skip

# Dynamic version generation after source fetch
define Package/$(PKG_NAME)/GetGitInfo
    cd $(PKG_BUILD_DIR) && \
    PKG_BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main") && \
    PKG_COMMITS=$$(git rev-list --count HEAD 2>/dev/null || echo "1") && \
    PKG_SHORT_COMMIT=$$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") && \
    if [ "$$PKG_BRANCH" = "main" ] || [ "$$PKG_BRANCH" = "master" ]; then \
        echo "0.$$PKG_COMMITS" ; \
    else \
        echo "0.$$PKG_COMMITS-$$PKG_BRANCH" ; \
    fi
endef

PKG_VERSION:=$(shell $(call Package/$(PKG_NAME)/GetGitInfo))
PKG_RELEASE:=$(shell cd $(PKG_BUILD_DIR) 2>/dev/null && git rev-parse --short HEAD 2>/dev/null || echo "1")

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
IPK_FILE:=$(BIN_DIR)/packages/$(ARCH_PACKAGES)/custom/$(PKG_NAME)_$(PKG_VERSION)-$(PKG_RELEASE)_$(ARCH_PACKAGES).ipk

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/golang.mk

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=TollGate Relay Module
	URL:=https://github.com/OpenTollGate/tollgate-module-relay-go
	DEPENDS:=+golang
endef

define Package/$(PKG_NAME)/description
	TollGate Relay Module implementation in Go
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	mkdir -p $(PKG_BUILD_DIR)/src
	$(CP) $(PKG_BUILD_DIR)/src/* $(PKG_BUILD_DIR)/
	cd $(PKG_BUILD_DIR) && \
	rm -f go.mod go.sum && \
	go mod init tollgate-module-relay-go && \
	go mod edit -replace github.com/OpenTollgate/relay=./ && \
	go mod tidy && \
	go get github.com/fiatjaf/khatru && \
	go get github.com/nbd-wtf/go-nostr
endef

define Build/Configure
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && \
	GOOS=$(GO_TARGET_OS) \
	GOARCH=$(GO_TARGET_ARCH) \
	GOARM=$(GO_ARM) \
	GOMIPS=$(GO_MIPS) \
	GO386=$(GO_386) \
	CGO_ENABLED=1 \
	CC=$(TARGET_CC) \
	CXX=$(TARGET_CXX) \
	GOPATH=$(GOPATH) \
	go build -trimpath \
		-ldflags "-s -w \
		-X main.Version=$(PKG_VERSION) \
		-X main.CommitHash=$(PKG_RELEASE) \
		-X main.BuildTime=$(shell date -u '+%Y-%m-%d_%I:%M:%S%p')" \
	-o $(PKG_BUILD_DIR)/tollgate-relay src/main.go
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/tollgate-relay $(1)/usr/bin/
endef

# Add custom target to print IPK path
#define Package/tollgate-module-relay-go/postinst
#	echo "Package compiled successfully!"
#	echo "IPK file location: $(IPK_FILE)"
#endef

$(eval $(call BuildPackage,$(PKG_NAME)))

# Print IPK path after successful compilation
PKG_FINISH:=$(shell echo "Successfully built: $(IPK_FILE)" >&2)