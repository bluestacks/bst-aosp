#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/provider/Settings.java core/java/android/os/Environment.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-5 Settings Environment"
git log -1 --oneline
