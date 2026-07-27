#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add \
  core/java/com/android/internal/app/PaymentRedirectProxyActivity.java \
  core/java/android/app/ActivityThread.java
git commit -m "BlueStacks android-16 port: FW-CORE-APP-8 PaymentRedirect IAP"
git log -1 --oneline
