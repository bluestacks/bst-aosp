#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/app/SharedPreferencesImpl.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-12 SharedPreferencesImpl"
git log -1 --oneline
