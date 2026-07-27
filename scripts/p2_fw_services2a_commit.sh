#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add \
  services/core/java/com/android/server/IntentResolver.java \
  services/core/java/com/android/server/pm/resolution/ComponentResolver.java
git commit -m "BlueStacks android-16 port: FW-SERVICES-2a hide BST resolve filter"
git log -1 --oneline
