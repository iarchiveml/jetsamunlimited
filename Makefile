ARCHS=arm64e
TARGET = iphone:clang:latest:15.0

include theos/makefiles/common.mk

TOOL_NAME = jetsamctl
jetsamctl_CFLAGS = -Wno-unused
jetsamctl_FILES = main.m
jetsamctl_CODESIGN_FLAGS = -Sentitlements.xml
include $(THEOS_MAKE_PATH)/tool.mk
