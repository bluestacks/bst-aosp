#!/bin/bash
set -e
cd ~/aosp16/frameworks/base
git add services/core/java/com/android/server/clipboard/ClipboardService.java
git commit -m "BlueStacks android-16 port: FW-SERVICES-1a Clipboard host sync"
git log -1 --oneline
