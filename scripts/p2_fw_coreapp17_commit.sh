#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/view/Display.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-17 Display rotation kill-switch"
git log -1 --oneline
