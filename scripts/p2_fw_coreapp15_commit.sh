#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/os/BaseBundle.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-15 BaseBundle affiliate"
git log -1 --oneline
