#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/app/Activity.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-13 Activity GIAP"
git log -1 --oneline
