#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add services/core/java/com/android/server/location/LocationManagerService.java
git commit -m "BlueStacks android-16 port: FW-SERVICES-1b Location GMS network popup"
git log -1 --oneline
