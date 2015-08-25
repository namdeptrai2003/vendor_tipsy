#!/bin/sh

# Copyright (C) 2014 The OmniROM Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This works, but there has to be a better way of reliably getting the root build directory...
if [ $# -eq 1 ]; then
    TOP=$1
    DEVICE=$TARGET_DEVICE
elif [[ (-n "$(gettop)") && ($(get_build_var TARGET_DEVICE) != generic)]]; then
    TOP=$(gettop)
    DEVICE=$(get_build_var TARGET_DEVICE)
else
    echo "Please run envsetup.sh and breakfast/lunch before running this script,"
    echo "or provide the build root directory as the first parameter."
    return 1
fi

if [[ $ANDROID_PROMPT_PREFIX == *arm* ]]; then
    ARCH=arm
fi

if [[ $ANDROID_PROMPT_PREFIX == *arm64* ]]; then
    ARCH=arm64
fi

if [[ $ANDROID_PROMPT_PREFIX == *x86* ]]; then
    ARCH=x86
fi

TARGET_DIR=$OUT
LIBS_64=$TARGET_DIR/system/lib64
PREBUILT_DIR=$TOP/prebuilts/chromium/$DEVICE

if [ -d $PREBUILT_DIR ]; then
    rm -rf $PREBUILT_DIR
fi

mkdir -p $PREBUILT_DIR
mkdir -p $PREBUILT_DIR/app
mkdir -p $PREBUILT_DIR/lib

if [ -d $TARGET_DIR ]; then
    echo "Copying files..."
    cp -r $TARGET_DIR/system/app/webview $PREBUILT_DIR/app
    cp $TARGET_DIR/system/lib/libwebviewchromium.so $PREBUILT_DIR/lib/libwebviewchromium.so
    cp $TARGET_DIR/system/lib/libwebviewchromium_plat_support.so $PREBUILT_DIR/lib/libwebviewchromium_plat_support.so
    cp $TARGET_DIR/system/lib/libwebviewchromium_loader.so $PREBUILT_DIR/lib/libwebviewchromium_loader.so
    if [ -d $LIBS_64 ]; then
    mkdir -p $PREBUILT_DIR/lib64
    cp $LIBS_64/libwebviewchromium.so $PREBUILT_DIR/lib64/libwebviewchromium.so
    cp $LIBS_64/libwebviewchromium_plat_support.so $PREBUILT_DIR/lib64/libwebviewchromium_plat_support.so
    cp $LIBS_64/libwebviewchromium_loader.so $PREBUILT_DIR/lib64/libwebviewchromium_loader.so
    fi
else
    echo "Please ensure that you have ran a full build prior to running this script!"
    return 1;
fi

echo "Generating Makefiles..."

HASH=$(git --git-dir=$TOP/external/chromium_org/.git --work-tree=$TOP/external/chromium_org rev-parse --verify HEAD)
echo $HASH > $PREBUILT_DIR/hash.txt

sed -e s/__DEVICE__/$DEVICE/g -e s/__ARCH__/$ARCH/g > $PREBUILT_DIR/chromium_prebuilt.mk << EOF
# Copyright (C) 2014 The OmniROM Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := prebuilts/chromium/__DEVICE__/
ARCH := __ARCH__

PRODUCT_COPY_FILES += \\
    \$(LOCAL_PATH)/app/webview/webview.apk:system/app/webview/webview.apk \\
    \$(LOCAL_PATH)/lib/libwebviewchromium.so:system/lib/libwebviewchromium.so \\
    \$(LOCAL_PATH)/lib/libwebviewchromium_plat_support.so:system/lib/libwebviewchromium_plat_support.so \\
    \$(LOCAL_PATH)/lib/libwebviewchromium_loader.so:system/lib/libwebviewchromium_loader.so

ifeq (\$(ARCH),arm64)
PRODUCT_COPY_FILES += \\
    \$(LOCAL_PATH)/lib64/libwebviewchromium.so:system/lib64/libwebviewchromium.so \\
    \$(LOCAL_PATH)/lib64/libwebviewchromium_plat_support.so:system/lib64/libwebviewchromium_plat_support.so \\
    \$(LOCAL_PATH)/lib64/libwebviewchromium_loader.so:system/lib64/libwebviewchromium_loader.so
endif

ifeq (\$(ARCH),arm)
\$(shell mkdir -p out/target/product/__DEVICE__/system/app/webview/lib/arm/)
\$(shell cp -r \$(LOCAL_PATH)/app/webview/lib/arm/libwebviewchromium.so out/target/product/__DEVICE__/system/app/webview/lib/arm/libwebviewchromium.so)
endif

ifeq (\$(ARCH),arm64)
\$(shell mkdir -p out/target/product/__DEVICE__/system/app/webview/lib/arm64/)
\$(shell cp -r \$(LOCAL_PATH)/app/webview/lib/arm64/libwebviewchromium.so out/target/product/__DEVICE__/system/app/webview/lib/arm64/libwebviewchromium.so)
endif

ifeq (\$(ARCH),x86)
\$(shell mkdir -p out/target/product/__DEVICE__/system/app/webview/lib/x86/)
\$(shell cp -r \$(LOCAL_PATH)/app/webview/lib/x86/libwebviewchromium.so out/target/product/__DEVICE__/system/app/webview/lib/x86/libwebviewchromium.so)
endif

EOF

echo "Done!"
