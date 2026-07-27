#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/view/Display.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-7 Display custom DPI rotation"
git log -1 --oneline
