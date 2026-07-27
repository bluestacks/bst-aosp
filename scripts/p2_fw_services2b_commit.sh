#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add services/core/java/com/android/server/notification/NotificationManagerService.java
git commit -m "BlueStacks android-16 port: FW-SERVICES-2b NMS host notification sync"
git log -1 --oneline
