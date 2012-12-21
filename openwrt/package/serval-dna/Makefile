include $(TOPDIR)/rules.mk

PKG_NAME:=serval-dna
PKG_VERSION:=2012-12-21
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/servalproject/serval-dna.git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_VERSION:=148d499ada4c162fe61ffe0076f7c5fbc838c8be
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_FIXUP:=autoreconf

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_BUILD_DEPENDS:=

include $(INCLUDE_DIR)/package.mk

define Package/serval-dna
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=serval-dna
	DEPENDS:=+libpthread +librt
endef

define Package/serval-dna/description
  Serval Daemon
endef

define Package/serval-dna/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/servald $(1)/usr/bin
endef

define Build/Configure
  $(call Build/Configure/Default,--enable-instance-path=/etc/serval)
endef

$(eval $(call BuildPackage,serval-dna))


