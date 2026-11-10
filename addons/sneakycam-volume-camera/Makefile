ARCHS = arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = roothide
FINALPACKAGE = 1

TWEAK_NAME = zSneakyCamVolumeCamera
zSneakyCamVolumeCamera_FILES = Tweak.xm
zSneakyCamVolumeCamera_FRAMEWORKS = UIKit Foundation CoreFoundation
zSneakyCamVolumeCamera_CFLAGS = -Wall -Wextra

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
