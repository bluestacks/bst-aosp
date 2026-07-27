#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add services/core/java/com/android/server/accounts/AccountManagerService.java
git commit -m "BlueStacks android-16 port: FW-SERVICES-3 AccountManager host account hooks"
git log -1 --oneline
