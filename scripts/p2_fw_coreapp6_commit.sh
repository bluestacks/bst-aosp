#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add core/java/android/widget/Editor.java core/java/android/widget/TextView.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-6 Editor TextView"
git log -1 --oneline
