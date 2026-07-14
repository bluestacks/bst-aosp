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

# This is a generic product that isn't specialized for a specific device.
# It includes the base Android-x86 platform.

# Additional settings used in all AOSP builds

PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true

$(call inherit-product,$(LOCAL_PATH)/device.mk)

# Get a list of languages.
$(call inherit-product,$(SRC_TARGET_DIR)/product/languages_full.mk)

# Get everything else from the parent package
$(call inherit-product,$(SRC_TARGET_DIR)/product/generic.mk)

#$(call inherit-product, $(SRC_TARGET_DIR)/product/module_common.mk)
# Get some sounds
$(call inherit-product-if-exists,frameworks/base/data/sounds/AudioPackage6.mk)

PRODUCT_NAME := android_x86_64
PRODUCT_BRAND := Android-x86
PRODUCT_DEVICE := x86_64
PRODUCT_MODEL := Generic Android-x86_64
