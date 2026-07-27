#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/com/android/internal/content/NativeLibraryHelper.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-14 NativeLibraryHelper ABI"
git log -1 --oneline
