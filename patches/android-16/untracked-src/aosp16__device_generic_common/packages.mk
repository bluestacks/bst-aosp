#
# Copyright (C) 2014 The Android-x86 Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Common packages for Android-x86 platform.

PRODUCT_PACKAGES := \
    GlobalTime \
    HoloSpiralWallpaper \
    LiveWallpapers \
    LiveWallpapersPicker \
    PinyinIME \
    Provision \
    WallpaperPicker \
    camera.bst \
    lights.bst \
    memtrack.bst \
    power.bst \
    chat \
    com.android.future.usb.accessory \
    drmserver \
    eject \
    gps.default \
    gps.huawei \
    hwcomposer.x86 \
    icu.dat \
    io_switch \
    libGLES_android \
    libhuaweigeneric-ril \
    make_ext4fs \
    parted \
    scp \
    sftp \
    ssh \
    sshd \
    su \
    v86d \
    pagefusion

PRODUCT_PACKAGES += \
    libwpa_client \
    hostapd \
    wificond \
    wpa_supplicant \
    wpa_supplicant.conf \

PRODUCT_PACKAGES += \
    e2fsck \
    fsck.exfat \
    fsck.f2fs \
    mke2fs \
    make_f2fs \
    mkfs.exfat \
    mkntfs \
    mount.exfat \
    ntfs-3g \
    ntfsfix \
    resize2fs \
    tune2fs \

PRODUCT_PACKAGES += \
    btattach \
    hciconfig \
    hcitool \

# Stagefright FFMPEG plugins (A16 需 libva/链接适配，打 ISO 时先关闭)
# PRODUCT_PACKAGES += \
#     i965_drv_video \
#     libffmpeg_extractor \
#     libffmpeg_omx \
#     media_codecs_ffmpeg.xml

# BS-A16: Use com.uncube.launcher3 as default home app.
# Remove AOSP Launcher3 to avoid HOME activity conflict on first boot.
# PRODUCT_PACKAGES += \
#     Launcher3QuickStep

# Third party apps
PRODUCT_PACKAGES += \
    bstshutdown \
    bstshutdown_core \
    bstime \
    bstsvcmgrtest \
    report_daemon


# Debug tools
PRODUCT_PACKAGES_DEBUG := \
    avdtptest \
    avinfo \
    avtest \
    bneptest \
    btmgmt \
    btmon \
    btproxy \
    haltest \
    l2ping \
    l2test \
    mcaptest \
    rctest \

PRODUCT_HOST_PACKAGES := \
    xmllint \
    badblocks

# Bluestacks Specific Packages
PRODUCT_PACKAGES_DEBUG := \
    com.bluestacks.BstCommandProcessor \
    com.bluestacks.settings \

