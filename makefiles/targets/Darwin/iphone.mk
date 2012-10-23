ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

# A version specified as a target argument overrides all previous definitions.
_SDKVERSION := $(or $(firstword $(_THEOS_TARGET_ARGS)),$(SDKVERSION))
_THEOS_TARGET_SDK_VERSION := $(or $(_SDKVERSION),latest)

_SDK_DIR := $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneOS.platform/Developer/SDKs
_IOS_SDKS := $(sort $(patsubst $(_SDK_DIR)/iPhoneOS%.sdk,%,$(wildcard $(_SDK_DIR)/iPhoneOS*.sdk)))
_LATEST_SDK := $(word $(words $(_IOS_SDKS)),$(_IOS_SDKS))

ifeq ($(_THEOS_TARGET_SDK_VERSION),latest)
override _THEOS_TARGET_SDK_VERSION := $(_LATEST_SDK)
endif

# We have to figure out the target version here, as we need it in the calculation of the deployment version.
_TARGET_VERSION_GE_6_0 = $(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 6.0)
_TARGET_VERSION_GE_3_0 = $(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 3.0)
_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(or $(word 2,$(_THEOS_TARGET_ARGS)),$(TARGET_IPHONEOS_DEPLOYMENT_VERSION),$(_SDKVERSION),$(if $(_TARGET_VERSION_GE_6_0),4.3,3.0))

ifeq ($(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION),latest)
override _THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(_LATEST_SDK)
endif

_DEPLOY_VERSION_LT_4_3 = $(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION) lt 4.3)

ifeq ($(_TARGET_VERSION_GE_6_0)$(_DEPLOY_VERSION_LT_4_3),11)
$(error You can not deploy to iOS versions less than 4.3 while building for 6.0)
endif

SYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(_THEOS_TARGET_SDK_VERSION).sdk

TARGET_CC ?= xcrun -sdk iphoneos gcc
TARGET_CXX ?= xcrun -sdk iphoneos g++
TARGET_LD ?= xcrun -sdk iphoneos g++
TARGET_STRIP ?= xcrun -sdk iphoneos strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk iphoneos -find codesign_allocate)"
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/install_deb_remote.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

ifeq ($(_TARGET_VERSION_GE_6_0),1)
	ARCHS ?= armv7 armv7s
else
ifeq ($(_TARGET_VERSION_GE_3_0),1)
	ARCHS ?= armv6 armv7
else
	ARCHS ?= armv6
endif
endif

SDKFLAGS := -isysroot "$(SYSROOT)" $(foreach ARCH,$(ARCHS),-arch $(ARCH)) -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION)) -miphoneos-version-min=$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION)
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
