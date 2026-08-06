# Android-16 App Runtime Oracle

This temporary, uninstallable APK closes behavior gaps that shell service
checks cannot prove. It is test scaffolding only: it is not an Android product
module, app-player payload, or publication component.

The app runs as an ordinary app UID and emits one `A16ORACLE:PASS` or
`A16ORACLE:FAIL` line for each contract:

- BlueStacks `WifiInfo`/`DhcpInfo`, Wi-Fi transport presentation, and the
  `eth0` to `wlan0` Java facade;
- software Canvas pixel output through the Android graphics API;
- an initialized and playing `AudioTrack`;
- one non-empty Camera2 YUV frame;
- an unprivileged DownloadProvider retry broadcast. The host runner requires
  DownloadProvider's independent rejection log for the app UID.

Build only from the Android-16 target tree's public SDK prebuilts:

```bash
bash tests/android16-runtime-oracle/build.sh \
  --android-root "$HOME/android-16" \
  --output /tmp/a16-runtime-oracle.apk
```

The build script rejects any path containing `aosp16`, does not read `out*`,
and writes only the requested APK, identity sidecar, and a temporary directory.
The Windows runner installs the APK, grants only its declared runtime
permissions, collects bounded logcat evidence, verifies the DownloadProvider
denial UID, and uninstalls the app in `finally`.

This oracle still does not prove audible host output, microphone capture,
Widevine playback, translated ARM64 native execution, host taskbar/recents
policy, or external internet reachability. Those remain separate gates.
