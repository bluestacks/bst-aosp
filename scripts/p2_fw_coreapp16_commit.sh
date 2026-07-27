#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/app/ActivityThread.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-16 ActivityThread profile/UE"
git log -1 --oneline
