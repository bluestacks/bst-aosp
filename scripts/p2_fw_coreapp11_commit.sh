#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/content/res/ResourcesImpl.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-11 ResourcesImpl"
git log -1 --oneline
