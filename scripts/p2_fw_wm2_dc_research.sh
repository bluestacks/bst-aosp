#!/bin/bash
set +u
A16=~/aosp16/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java
A13=~/app-player/android-13/frameworks/base/services/core/java/com/android/server/wm/DisplayContent.java
echo '=== a16 ctor / fields near end of fields ==='
rg -n 'mInEnsureActivitiesVisible|class DisplayContent|sendOrientationToHost|BstFilter|updateOrientation|getOrientation' "$A16" | head -40
echo '=== a16 updateOrientation / rotation notify ==='
rg -n -n 'void updateOrientation|sendOrientationToHost|onRotationChanged|mDisplayRotation' "$A16" | head -30
echo '=== a13 sendOrientation call site context ==='
rg -n -B8 -A5 'sendOrientationToHostAsync' "$A13" | head -40
echo '=== a16 equivalent area (computeIme|updateDisplayOverride|setMaxBounds) ==='
# find method containing line numbers from a13 around 2157
sed -n '2140,2170p' "$A13"
echo '--- a16 file size lines ---'
wc -l "$A16" "$A13"
