#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add \
  services/core/java/com/android/server/audio/AudioService.java \
  services/core/java/com/android/server/appop/AppOpsService.java
git commit -m "BlueStacks android-16 port: FW-SERVICES-4a Audio volume host sync + AppOps devicedetails"
git log -1 --oneline
