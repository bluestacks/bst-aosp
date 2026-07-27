#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/hardware/input/InputManagerGlobal.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-9 InputManagerGlobal ROB-18338"
git log -1 --oneline
