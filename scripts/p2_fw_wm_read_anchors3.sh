#!/bin/bash
set +u
A16=~/aosp16/frameworks/base
A13=~/app-player/android-13/frameworks/base
echo '=== a16 executeRequest start 1028-1150 ==='
sed -n '1028,1150p' "$A16/services/core/java/com/android/server/wm/ActivityStarter.java"
echo '=== a13 around 880-960 ==='
sed -n '880,960p' "$A13/services/core/java/com/android/server/wm/ActivityStarter.java"
echo '=== a16 imports ActivityStarter head ==='
sed -n '1,180p' "$A16/services/core/java/com/android/server/wm/ActivityStarter.java" | rg -n 'import |class ActivityStarter|private String mLast'
echo '=== a16 ATM imports for Bst ==='
rg -n 'import android.util.BstUtils|import com.bluestacks|import android.os.Binder|GL_ES_VERSION' \
  "$A16/services/core/java/com/android/server/wm/ActivityTaskManagerService.java" | head -20
