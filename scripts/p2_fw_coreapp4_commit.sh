#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/view/ViewRootImpl.java core/java/android/view/InputDevice.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-4 ViewRootImpl InputDevice"
git log -1 --oneline
