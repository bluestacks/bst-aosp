# Project Review Findings

> Generated findings are evidence-backed candidates. Historical failures remain first-class records and are not automatically rewritten.

## P0

Findings: **0**.

## P1

Findings: **0**.

## P2

Findings: **1**.

### `scripts/p2_mech2_apply.py`: Syntax or parse failure

- Status: `accepted-historical`
- Evidence: unexpected indent at line 20
- Action: Preserve the failed source; use `patches/android-16/patches/p2-framework-rest/P2-MECH-2-launcher3-manifest.diff` as the successful replacement.

## P3

Findings: **239**.

### `a13-fwbase-patches/0001-A13-Adding-libhostcall_jni.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4e36c373144293c257a733f3d7a58e3dd7286642139c4d817d4d59e076b7c0c1; 38153 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0001-A13-Adding-libhostcall_jni.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0002-A13-Adding-BlueStacks-basic-services.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e93bdf40ac493446cdf5f5ee22f0eef0924ef2f3cee0a79c2744e684810eb623; 419532 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0002-A13-Adding-BlueStacks-basic-services.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0003-A13-Sending-top-display-focus-change-to-host.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 293889eec266578ddc587f0b7499b96229c467e96405094940a0e53912fcfce1; 16685 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0003-A13-Sending-top-display-focus-change-to-host.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0004-A13-Disable-Bluetooth-service.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c9a577b3b81eab5d39245c3ad23dec1cf572c1782ada14d43b03893cbc8efec2; 1138 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0004-A13-Disable-Bluetooth-service.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0005-A13-Temporarily-disable-KeyStore-function-to-avoid-s.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 37faa1b5fb20ce97aab4630f12dd6004f4456b05b978ea60c56a1cbe3d17888a; 4273 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0005-A13-Temporarily-disable-KeyStore-function-to-avoid-s.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0006-A13-Hiding-navigation-bar.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 128729614b7a85d2df1fb1267c1a90893dbb6cab3b8edf97cb43ed38d55be518; 1633 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0006-A13-Hiding-navigation-bar.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0007-A13-Changes-for-native-mouse-pointer.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ce26b467d8130077fb50c156124b4ede2478fe90e059f84d96ee1641297cca30; 3939 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0007-A13-Changes-for-native-mouse-pointer.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0008-A13-Added-chnages-to-support-StopApp-gcall.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a75ef32695b6eac06eff795ea33e365fe3246bc03da0c62e79bf847b16312681; 12048 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0008-A13-Added-chnages-to-support-StopApp-gcall.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0009-A13-Support-orientation-change.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 5fbe753c3a24abee7b7cf13c92f5470a0d00b88bbf62b6ed274107799f904175; 25531 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0009-A13-Support-orientation-change.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0010-A13-Disable-bootanimation-in-the-code.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3d61d23a01bccbf4c764d36b960e355723bc4cda6d92c3ba3a0cbfcd7076bd85; 982 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0010-A13-Disable-bootanimation-in-the-code.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0011-A13-Add-hcall-support-onImeChange-onTextEditModeChan.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 63542fb00c1c85f6d44597de7d17fd8bb6cc098e5bfad40b6ea3d55fd44d1b4b; 7248 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0011-A13-Add-hcall-support-onImeChange-onTextEditModeChan.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0012-A13-Inherit-parent-capabilities-into-the-children.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3097d0212425387c89e6154b0392e805924abdb5a3ffffe04369eac15471b4ca; 1275 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0012-A13-Inherit-parent-capabilities-into-the-children.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0013-A13-Updating-BlueStacks-wallpaper.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ae030d732428662807495e5aff326f7801655c125d859bd06d7bb9d70f366697; 11950114 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0013-A13-Updating-BlueStacks-wallpaper.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0014-A13-Making-sure-that-apps-located-in-data-downloads-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 efc102bda4dc340259e04c6569606094155033681d586a7b8e85eaa1ecc3124a; 3359 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0014-A13-Making-sure-that-apps-located-in-data-downloads-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0015-A13-Using-0x90-0xe0-0x10-scancode-for-HOME-and-0x99-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 7dd182a8199e27c30691fd33759f6d7eee1db021c1c4ddc67dce2b95c59629f3; 944 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0015-A13-Using-0x90-0xe0-0x10-scancode-for-HOME-and-0x99-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0016-A13-Disable-Keyguard.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4c9d97136d517678f02598eee6ef4eeee52cad566d5d1b71761b1cecb5fbe237; 1703 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0016-A13-Disable-Keyguard.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0017-A13-Disable-Lockscreen.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c392396cc60081015301753ebdf0d84edd5d36558b7240cc8a053888a97133e7; 1567 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0017-A13-Disable-Lockscreen.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0018-A13-Make-system-stay-awake.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 91149a6eb2c68ad8b8e7a51564543dc98468e0bce4f4f925d4380c2f0a7f85e9; 1195 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0018-A13-Make-system-stay-awake.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0019-A13-Disable-the-systemui-clipboard-overlay.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 679ac977a10226ab84b04eae398d1a348d06d886a439aa928bd84b7fddc4f57e; 1813 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0019-A13-Disable-the-systemui-clipboard-overlay.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0020-A13-Setting-screen-timeout-value-as-never.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 bbed82b7f5c4189d1afb61ec66aebd706aeb21d431b93edc51d4a51d12cf8aa6; 1258 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0020-A13-Setting-screen-timeout-value-as-never.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0021-A13-Fix-crash-issue-when-opening-com.location.provid.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 077d2142ec10d311ca3ef9ebe31ff1ccf8d59adf16e7e0b74dca47fea84b8914; 2101 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0021-A13-Fix-crash-issue-when-opening-com.location.provid.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0022-A13-Disable-quota-limit-irregard-of-fuse-and-sdcardf.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 dc641ba19aab6f4176897ca02dca027770ba24da771a6cd79c083362a4c22cae; 2351 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0022-A13-Disable-quota-limit-irregard-of-fuse-and-sdcardf.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0023-A13-Setting-boot_completed-and-screen_enabled-props.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ddfaf79bb1f38343ddacc8ba70e77ff617ac6639f5932af6374873a6dd5318e9; 1966 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0023-A13-Setting-boot_completed-and-screen_enabled-props.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0024-Changes-to-add-chrome-webviewprovider-as-default.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 43842e47aa18289a56f46598e3e106ffbdf19ae975d530280e79bde7128630ed; 1069 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0024-Changes-to-add-chrome-webviewprovider-as-default.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0025-Forcing-supported-abi-values-to-play-store-based-on-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 48a76bffdb40885b1afec3944c645694717d41c45c22c96612f3e982a9814361; 4710 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0025-Forcing-supported-abi-values-to-play-store-based-on-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0026-A13-Faking-Esc-key-to-work-as-back-button-in-app-pla.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 dacdc0b9589cb87d2242c7de3ba4b0c6911a2ea4fa7155aab059be93062b24d1; 1285 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0026-A13-Faking-Esc-key-to-work-as-back-button-in-app-pla.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0027-A13-Set-bst-props-to-default-value-as-starting-zygot.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 03eb6c27791450301bdd4bbe2e924bcba2a79efeb129a92c0c8ce006ac314570; 1046 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0027-A13-Set-bst-props-to-default-value-as-starting-zygot.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0028-A13-Adding-path-to-be-read-for-default-permission-an.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3ee15b5220aaa4d059da0e0ab05c795a5c8ac76cf1fe7456bc33a087b82071f8; 1073 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0028-A13-Adding-path-to-be-read-for-default-permission-an.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0029-A13-Faking-glesversion-and-features-for-playstore.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3def24c2e59316ae225e653fce2af9ce6770ed6be941b02faa3f96ed586da6a7; 10715 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0029-A13-Faking-glesversion-and-features-for-playstore.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0030-A13-Ported-IAP-related-changes.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 54a432c62c858d54e9f12616a766d296869480bf7229b386e562c71bb8f4a6ca; 21336 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0030-A13-Ported-IAP-related-changes.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0031-A13-Reading-locale-from-bst.locale-if-lang-and-count.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c1a270deedf94f17397925e64e225144e1a013d86e94093b5786d44e7e71f3a5; 2097 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0031-A13-Reading-locale-from-bst.locale-if-lang-and-count.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0032-A13-Attaching-GrallocUploadThread-to-JVM-env.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f876ec961b6cc9ec5bc6895cfa6d53ddd30982833d14616400562b12491c06ae; 7028 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0032-A13-Attaching-GrallocUploadThread-to-JVM-env.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0033-A13-Changes-for-audio-volume.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fbc312a0654e86f7a04ba09b4396414cb07db17fdb8d4496560f758c3af50bf8; 3982 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0033-A13-Changes-for-audio-volume.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0034-A13-Parsing-apps.xml-on-every-boot-so-permissions-ar.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 dea7fb39583fe8202fb8730157639820c13b1ca589f230b623396575acf77f4a; 2139 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0034-A13-Parsing-apps.xml-on-every-boot-so-permissions-ar.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0035-A13-Disabling-default-StrictMode-policy-for-Bluestac.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b6861344f7554203ee36dd4e9bdf509153bd23e6e6de5393254d1389c692de7c; 1275 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0035-A13-Disabling-default-StrictMode-policy-for-Bluestac.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0036-A13-Added-telephony-related-changes.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f741f5f51af40b6d0ace33631482235562a43a7ca1e4f0c3baa4b06f47fc59dc; 17125 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0036-A13-Added-telephony-related-changes.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0037-A13-Adding-NTP-time-sync-code-which-will-do-it-perio.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 af65253280d1bd0a6e5ce845bdcc09620342c5d00bd0942c2acae43ab736f8bb; 2981 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0037-A13-Adding-NTP-time-sync-code-which-will-do-it-perio.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0038-A13-code-sync-with-Rvc.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9b0fb9eb87a88dc5c0e2ee3b3612110419dde2ff01ed4e2158d9d3cf86b40c40; 3694 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0038-A13-code-sync-with-Rvc.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0039-A13-Disabling-location-accuracy-popup.-Return-false.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b41dfda940c73c699c4d0f5533e223711607f53eab090973b155bf8aaf51b6da; 4357 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0039-A13-Disabling-location-accuracy-popup.-Return-false.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0040-A13-code-sync-with-Android-11.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 762e1380ff6277edcbaee6c4b3eb19aa809e0ab5272c85186cc6b42d8cee33a9; 48296 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0040-A13-code-sync-with-Android-11.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0041-A13-There-was-a-case-in-which-fb-schedule-was-corrup.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 abaa9d18c3956236cb88dedc67393fb1f3223ae55e973a329ca15f775f035bfa; 1570 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0041-A13-There-was-a-case-in-which-fb-schedule-was-corrup.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0042-A13-Adding-unit-test-script.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4ee94288f0cf668b0d65e9944c1e0e2825b6b04c3fbbc8dd19780ef95e8eb441; 3696 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0042-A13-Adding-unit-test-script.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0043-A13-sync-rvc-xml-file.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a64828ae6f3b36c2713606bf826422dd8b4b8db2cb96df15595996e5a155bd13; 2015 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0043-A13-sync-rvc-xml-file.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0044-A13-BS4-3201-Ported-debuggable-property-changes.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f20c73afc376a7cbf5d6706ffef4fd86cf0effc82996cf6e5334f745b82cb390; 2333 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0044-A13-BS4-3201-Ported-debuggable-property-changes.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0045-A13-Fix-for-Low-battery-warning-pop-up.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d3024fac42cc57411674948c1f563a64e66bd82e13375c7cdef36f904da08ffb; 1717 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0045-A13-Fix-for-Low-battery-warning-pop-up.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0046-A13-Changes-to-Hide-the-Bluestacks-packages.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 08c8cf6ca6234b70948fbe001465bab681a619e61ae2625576fe5798a9c0f7b9; 11141 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0046-A13-Changes-to-Hide-the-Bluestacks-packages.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0047-A13-Changes-to-return-correct-primary-storage-size.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2013f485ea30b1c96e2cdf06c68f6ae9c09b3ff2e501fa9d197d2a3951c996c8; 4378 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0047-A13-Changes-to-return-correct-primary-storage-size.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0048-A13-Adding-support-to-change-device-profile.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a023e2dc7bc3df7850d87c2cb7c2ef53e1d233a89005e8ea4d4145a2b53dc973; 2873 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0048-A13-Adding-support-to-change-device-profile.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0049-A13-Not-allowing-apps-to-change-screen_brightness-an.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c07ad0a4135f0a374c1289be096174c22d8a10f231b2ce0cbcd417c696bd04a6; 7409 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0049-A13-Not-allowing-apps-to-change-screen_brightness-an.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0050-A13-Porting-changes-for-dxflag-config.db-entry.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 19850f95e0bf1fc7b2a72e194d6ada109840612e89c271a6768b899f22ced22a; 3375 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0050-A13-Porting-changes-for-dxflag-config.db-entry.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0051-A13-Faking-as-System-has-vibrator-available.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 54ac150c188abef097d46dc5167ae1b6b122cb6d3f47524797fba01ac2ffe2b9; 2424 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0051-A13-Faking-as-System-has-vibrator-available.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0052-A13-ROB-6795-Fixing-Chat-is-not-working-properly-on-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 aeb444f5ce2894455e504102a79b5b768eec19691c9307f45410162b6d04a424; 1899 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0052-A13-ROB-6795-Fixing-Chat-is-not-working-properly-on-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0053-A13-A11-78-On-clone-instance-updating-android-id-for.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fec7cf783cad5c1bcadfa4ee8080580dbbc24b7d974565d465e8baacf695c139; 5005 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0053-A13-A11-78-On-clone-instance-updating-android-id-for.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0054-A13-ROB-4550-Code-change-sync-from-Pie.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2f72314a2e4152dc5f7f9e82d57ae6e0937d29ecfd2a9464018f3897fd13fe5d; 1352 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0054-A13-ROB-4550-Code-change-sync-from-Pie.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0055-A13-When-Status-bar-is-hidden-then-if-someone-querie.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 94779012beda11ec0261a790cd6102d6337e809f78f8648ee9907552bb444735; 3966 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0055-A13-When-Status-bar-is-hidden-then-if-someone-querie.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0056-A13-making-sure-intent-is-not-null-before-accessing-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f6f4a3d64807d1b7cef864e686a3a667b7bdb5718f0c2a9457c37affe79034bd; 1251 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0056-A13-making-sure-intent-is-not-null-before-accessing-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0057-A13-Sending-fake-sensor-vendor-information-to-the-ap.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e06eaeedfaf04e7c7690da98377b60ba1ef380383d55f1fd7722cd32cebbc0d8; 1496 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0057-A13-Sending-fake-sensor-vendor-information-to-the-ap.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0058-A13-Fix-a-NPE-when-putting-a-null-Bundle-in-an-Inten.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0bcef029d463dc27b6ccee3e0253453be31a1fd2a881768cadb49955de75ed06; 976 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0058-A13-Fix-a-NPE-when-putting-a-null-Bundle-in-an-Inten.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0059-Revert-A13-ROB-6795-Fixing-Chat-is-not-working-prope.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3fdf0cc37628679bd590195f898bbd1d170122f987bec399a686e3dba38986a0; 1969 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0059-Revert-A13-ROB-6795-Fixing-Chat-is-not-working-prope.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0060-A13-Port-bst-wallpaper-codes-and-resource.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 01e721af2ba3a6fe637e8c04539b563dd8ed79e5414b3ef3efffe4e98852b651; 27791 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0060-A13-Port-bst-wallpaper-codes-and-resource.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0061-A13-Porting-modifyDispRotationVal-related-changes.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fd2da6b21ed069fe6a41ca188b02daac1abb35daae8779aff5366b1008b68b3f; 3910 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0061-A13-Porting-modifyDispRotationVal-related-changes.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0062-A13-Add-config.db-entry-xarch.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b34ca530d1f41493152b8d644a80a9436b2cda092a38215a1b94971c230db88f; 7258 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0062-A13-Add-config.db-entry-xarch.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0063-A13-Add-config.db-entry-xcpu.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 897d5195242ef430758e212cee589841d68202b39a3944e051515f15c936db73; 5551 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0063-A13-Add-config.db-entry-xcpu.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0064-A13-Added-changes-related-to-bstOnDisplayedPackageCh.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 38d03ee47df5a260b0f5a431c384cabcf0226c796f941c274d5903468051ac8e; 12859 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0064-A13-Added-changes-related-to-bstOnDisplayedPackageCh.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0065-A13-ROB-9926-add-the-default-profile-file-for-the-sp.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 1127c0d82d6d342d3f99cefd06d743a91e23e55d8ab403fc1936a961de3b6276; 2969 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0065-A13-ROB-9926-add-the-default-profile-file-for-the-sp.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0066-A13-Porting-mdsd-config-setting-imp.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3eda65830939d020cdb2d3822212cc9b7d584e936e7cb2d2faa9c941558a957b; 8856 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0066-A13-Porting-mdsd-config-setting-imp.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0067-A13-Changes-for-host-clipboard.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9e11408d174a9fd3d43a34db485f0faeaa545943d2de3ca225d9a8ed8b20b0a1; 3527 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0067-A13-Changes-for-host-clipboard.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0068-A13-Add-config.db-entry-blacklist-blacklistAction.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 14512c37b7fd789c4ccf9fb468bf3189de585d402d86f7fe5a2d2079ff7ec52c; 10913 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0068-A13-Add-config.db-entry-blacklist-blacklistAction.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0069-A13-Customize-the-footer-of-SystemUi-s-qs.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 74fab4f7093dbe17a5c2fd763424e99a5ab796c221ccb030ab127729cb2e8f94; 3500 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0069-A13-Customize-the-footer-of-SystemUi-s-qs.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0070-A13-Faking-the-uninitialised-properties.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 09af2ed4e345d9df6e17a3d27340ea37a0f929945d1597e5a4d027f78b9be7c9; 1406 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0070-A13-Faking-the-uninitialised-properties.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0071-A13-Restricting-GMS-Vending-and-chrome-apk-update-wh.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a8584a7e37f4776dc69be8a55fad42395121bada38fcae6a87ae930f98f57369; 3883 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0071-A13-Restricting-GMS-Vending-and-chrome-apk-update-wh.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0072-A13-Porting-changes-for-blacklist-config.db-entry.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e06a3c27fd7ab567520cc96a0ed1ef1237f2323483f8f1ac1a44ac7b01420df5; 1451 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0072-A13-Porting-changes-for-blacklist-config.db-entry.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0073-A13-Changes-to-support-arch-config-db-entry.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4c2994f409d628aeb8f2f23ec6ab4e704408ef7d3b4304de346b9636ad117d4b; 39605 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0073-A13-Changes-to-support-arch-config-db-entry.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0074-A13-Fix-crash-issue-when-abi-do-not-match.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a18d980d9160b585ef78d7783a0c6055c90320baed610d1aa20ab2df4681e59f; 1519 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0074-A13-Fix-crash-issue-when-abi-do-not-match.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0075-A13-Adding-AID_READPROC-group-to-bluestacks-specific.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9cc953087d26870e48565143571973ea2ee703c21872ccabc96be3135c4fc7ab; 3781 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0075-A13-Adding-AID_READPROC-group-to-bluestacks-specific.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0076-A13-Porting-vms-config.db-setting-impl.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 39834a868917e0f23f067ca797f83f35df4fe055f7d225c133436c5f4fd0c16b; 6674 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0076-A13-Porting-vms-config.db-setting-impl.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0077-A13-ROB-8784-Disable-package-verifier.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4a81dff992d8afcb716e1f3eb28c330c7f3672d338fe23232005998a7f3c649f; 1073 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0077-A13-ROB-8784-Disable-package-verifier.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0078-A13-ROB-8737-Added-hook-sharedpreference-setting-of-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e0cf9f2eb7692fcd7d8dd58516ee0e3002cbfabf26b3dd9eebd0e5aedd6b560d; 9976 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0078-A13-ROB-8737-Added-hook-sharedpreference-setting-of-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0079-A13-BS4-4874-Skipping-data-downloads-.tmp-dir.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 8ea7f65cb747c5833b84e57db142fcc05d0d3fcf53a4648379f69b52fb2b9128; 1370 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0079-A13-BS4-4874-Skipping-data-downloads-.tmp-dir.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0080-A13-case-3963-Not-showing-progress-bar-during-shutdo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c8abe56b6ade7b918a36f211c81cf8ee450078de3d30867928bde16b30120eac; 1097 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0080-A13-case-3963-Not-showing-progress-bar-during-shutdo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0081-A13-Syncing-timeout-values-from-Rvc.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 73a37fc0743a1b949187273c46a7fc6a1755d9fdffeb403215fc78753d8ff73d; 2055 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0081-A13-Syncing-timeout-values-from-Rvc.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0082-A13-Porting-ilh-ignore-large-heap-config.db-setting-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e8980dddde07413052cd4440cde9e90e2c0fb91f39af93dd8aa0399b3300de13; 2811 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0082-A13-Porting-ilh-ignore-large-heap-config.db-setting-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0083-A13-Porting-googleSignInReqd-config-setting-imp.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 8f2a2ccd7a666fc975d1cad067776bed50b214b0ed5f909c9e466470138602e3; 2104 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0083-A13-Porting-googleSignInReqd-config-setting-imp.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0084-A13-Porting-clear-setting-impl.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e98f50aa05a29ce4446946771c25b7f29a4c451d3de024ec5dcb923ea3480703; 4117 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0084-A13-Porting-clear-setting-impl.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0085-A13-Case-ROB-8853-updating-installation-true-for-non.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 8b8a4b3f92cec0a585f46bf909cdc5a141192b0eaf14f7339550a3a401c4b5b1; 990 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0085-A13-Case-ROB-8853-updating-installation-true-for-non.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0086-A13-By-default-in-bluestacks-do-not-go-into-the-safe.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2a074f7bed8d88bd59a7f4642e6b9265b8327922a107caa83cece94c0a8b9ebe; 1766 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0086-A13-By-default-in-bluestacks-do-not-go-into-the-safe.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0087-A13-SystemUI-customizations-changes-includes.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 11dacccddde371919a37cf18fb7ddb181b74fce078ed818e10a1d27d349227db; 8374 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0087-A13-SystemUI-customizations-changes-includes.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0088-A13-Stop-updating-ext-battery-stats-in-BatteryStatsS.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b64d26428d1c34b7f9c08bf08fd855fc5baa0637ba3a06b5bb840112f46ef04f; 1334 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0088-A13-Stop-updating-ext-battery-stats-in-BatteryStatsS.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0089-A13-Disabling-lockNow-function-chinese-app-365-locks.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 42facd7d97803ee7c2fbf7865e7f0f5a1606a22a2bd7f6abd5bbf10222203edb; 1435 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0089-A13-Disabling-lockNow-function-chinese-app-365-locks.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0090-A13-Case-ROB-8853-allow-chrome-to-install-apk-83.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 84119afce847bc1d624fd7ec3f78dcf08774624c23dd30bcd8ddf37c7a5f7c29; 2815 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0090-A13-Case-ROB-8853-allow-chrome-to-install-apk-83.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0091-A13-Affiliate-changes.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 eca1b14fabc65c4a0c4631e702b1cf229f82c8c08edb38b018e145ad3e8633c5; 31968 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0091-A13-Affiliate-changes.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0092-A13-Fixing-an-error-condition-in-which-runtime-permi.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 96b0db5283c93b3ca920a9d5b6c8896c02a122fce4609af04a453bdc1dd494f4; 2259 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0092-A13-Fixing-an-error-condition-in-which-runtime-permi.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0093-A13-Changes-to-restrict-user-from-revoking-the-permi.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ab97e49eba5ff5d8765e4d356291ff80880270a9aae7256b8d9e6c2384055e15; 2228 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0093-A13-Changes-to-restrict-user-from-revoking-the-permi.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0094-A13-Setting-wallpaperEnabled-to-false-not-waiting-fo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0068c712e935b2579493936ab789ee5aa98298586f1468a9bec50891bb851fa1; 1362 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0094-A13-Setting-wallpaperEnabled-to-false-not-waiting-fo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0095-A13-Allowing-all-apps-to-query-com.android.vending-g.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0f8f3ca5a94627f8803a1fb89c328df1f49bcbfd593b841840f957274a664b1f; 879 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0095-A13-Allowing-all-apps-to-query-com.android.vending-g.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0096-A13-6203-Not-populating-bluestacks-package-specific-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 eca6057192698756faa54238196fe4adc3d3131703767b9f2b9c219737cbcd63; 6360 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0096-A13-6203-Not-populating-bluestacks-package-specific-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0097-A13-ROB-8174-Instagram-Video-reels-flips-upside-down.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d2b5185cc8fe926c2b9f6078b737dea58d695541df68b505c020cd28f0ddc7b1; 2178 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0097-A13-ROB-8174-Instagram-Video-reels-flips-upside-down.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0098-A13-Changes-for-screenshot.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 30cd179362bdd395ef708cbc4d3593e743a8ba431b75d6ea979574f6da4a8182; 6729 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0098-A13-Changes-for-screenshot.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0099-A13-add-preinstalled-for-SYSTEM_ALERT_WINDOW.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 11ff4f87055bb18fb30cd5105fb094a80f8242901e95052eb0012fb15e66371c; 1188 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0099-A13-add-preinstalled-for-SYSTEM_ALERT_WINDOW.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0100-A13-Fix-compile-failures.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2e5e3d212ffd665df0663508ce42a3ddb0a43747be902b723dc7ce1d0a220d3b; 3015 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0100-A13-Fix-compile-failures.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0101-A13-Add-support-for-setBstIME.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3f59f238d64290b485f55b7d65ab4fe6ddd73edc385a4665ad357ab99aa5a927; 4570 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0101-A13-Add-support-for-setBstIME.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0102-A13-Add-pagefusion-module.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 13e8b434ce598d8e8c5004fbe6a3b4bfb5508ff8ce7ee621712b21ab23a5a482; 94876 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0102-A13-Add-pagefusion-module.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0103-A13-Making-sure-that-bluestacks-packages-cannot-be-d.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 27521fbe1e3c1200639f1c2f8f8d5b7da8b89e4d07f8f125a18a967eacb4cada; 2438 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0103-A13-Making-sure-that-bluestacks-packages-cannot-be-d.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0104-A13-ROB-8174-Adding-prefix-to-the-prop-key-71.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 dbba55f6aef25e346d5337549762c2f773acb1c394174de787023a8489f6f2cb; 1464 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0104-A13-ROB-8174-Adding-prefix-to-the-prop-key-71.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0105-A13-SystemUi-hide-qs_container-on-portrait-mode-113.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b913b2cf7f66c8e64091efbffac09f05397260e7b7b5d594465085f1de24b196; 940 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0105-A13-SystemUi-hide-qs_container-on-portrait-mode-113.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0106-A13-Hcall-related-code-porting.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 dd33bf11c432002c5e229ac5b3e444b8490260201f5ab4a25b4cb36f89066c4c; 56118 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0106-A13-Hcall-related-code-porting.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0107-A13-A11-54-Android-10-apps-must-have-the-READ_PRIVIL.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e724bb18d5200fe5c59e7dead9ffe1b1a14b8c46dd8193eaf8f1577e8f44adea; 2955 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0107-A13-A11-54-Android-10-apps-must-have-the-READ_PRIVIL.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0108-ROB-11748-New-config-entry-to-disable-angle-translat.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f0da196798c16a60d70e2f97f22e8440c6a16a73728f742e665c138e9c351fc9; 5800 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0108-ROB-11748-New-config-entry-to-disable-angle-translat.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0109-A13-fix-recents-rotation-issue-122.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4df576b8528920f57b492dbbcf68091ea33d92d024e9f08778f46edba8a60d03; 3061 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0109-A13-fix-recents-rotation-issue-122.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0110-A13-fix-com.sgra.dragon-crash-issue-123.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 efabd8173bb1e66ee09040ad445b96921fb78a2a3958eda5798370fc45bb9572; 1269 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0110-A13-fix-com.sgra.dragon-crash-issue-123.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0111-A13-ROB-12002-Add-config-entry-fbscreenlock.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b9ec4d587ad76c089a9c0ddfc64675eddf98961f0305719e7d4ac435db7f8dc5; 11127 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0111-A13-ROB-12002-Add-config-entry-fbscreenlock.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0112-A13-ROB-11963-ROB-12006-ROB-8775-compat-com.YoStarKR.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2b76dcc9ea149935f9147b1272198d2a436dd688c9692740a7fc7f4a07756d9c; 7884 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0112-A13-ROB-11963-ROB-12006-ROB-8775-compat-com.YoStarKR.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0113-A13-ROB-10507-new-entry-for-glProgramBinary.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3d6c013ef46adc475fb1e42115af7e92d0b19fd5d865e641143a0fa5bbcbf31a; 6145 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0113-A13-ROB-10507-new-entry-for-glProgramBinary.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0114-A13-ROB-10787-new-entry-for-glUnmapBuffer-performanc.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ab993c21abe16824da36a630c142159e0442cb23ad4670a0ede8846d2231b83a; 6206 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0114-A13-ROB-10787-new-entry-for-glUnmapBuffer-performanc.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0115-A13-ROB-10789-new-entry-for-gl-shader-workaround.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 05380922ae70a3ec1664641b397786a1e7b3ffbfbdb3909b44e2567fca11874a; 6084 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0115-A13-ROB-10789-new-entry-for-gl-shader-workaround.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0116-A13-ROB-11186-Enable-hpp-mode-in-config.db-by-defaul.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9a28e79537d9a884e4a7cb517ef984c53868af5b08d034bbe97e0de99ec56b7b; 5721 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0116-A13-ROB-11186-Enable-hpp-mode-in-config.db-by-defaul.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0117-A13-Pie-Android11-code-sync-change-includes-130.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 1f38b1663a4daf19131490a6a785be9c015aabf2ec503b4c6cfc9ac851ee0cb3; 14106 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0117-A13-Pie-Android11-code-sync-change-includes-130.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0118-A13-ROB-11904-Support-DRM-widevine.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 5b8f6c0832ea060286579f4c4ac65f3f64fac26538ea35dc7a9a6a6baa89c8b1; 6011 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0118-A13-ROB-11904-Support-DRM-widevine.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0119-A13-ROB-12525-fix-GL_TEXTURE_EXTERNAL_OES-bind-error.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 7f57002bd0a4a580ff029a37db894288fed902872be97b3929f48749c707ec8b; 5934 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0119-A13-ROB-12525-fix-GL_TEXTURE_EXTERNAL_OES-bind-error.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0120-A13-case-ROB-12546-Adding-a-new-entry-name-fixedSurf.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d886a32d8363a060625cf2df00d45e27b16e7c1d32cccc6758fe79945143b766; 8328 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0120-A13-case-ROB-12546-Adding-a-new-entry-name-fixedSurf.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0121-A13-add-iap-interceptor.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 795ee3459a5c2bfa0a26cd1dfb9d85ec024ee9f29899c1112cfa178160b89a94; 20924 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0121-A13-add-iap-interceptor.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0122-A13-fix-ClipboardService-crash-issue-132.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4e2fe50a42a89a12d14e847ec30b66fb647dc40323472eb68792d274bf35f3ab; 1734 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0122-A13-fix-ClipboardService-crash-issue-132.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0123-A13-ROB-11421-support-Native-Mouse-for-Roblox.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e8a82e5a1c51472356722e6c2dae2b6979c20ee8155ffd754d6335e26d9a993d; 5123 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0123-A13-ROB-11421-support-Native-Mouse-for-Roblox.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0124-A13-ROB-11560-set-Extreme-and-high-fps-by-default-fo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b7f104b84a3d0696b78d01ea75f068f51b280baac4440959f2ea14f49a2d514e; 1585 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0124-A13-ROB-11560-set-Extreme-and-high-fps-by-default-fo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0125-Revert-A13-ROB-11560-set-Extreme-and-high-fps-by-def.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c91fb405122788afcb4043536dffc391176c61d455c9bd738621d73d4d1d6e65; 1603 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0125-Revert-A13-ROB-11560-set-Extreme-and-high-fps-by-def.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0126-A13-ROB-11560-set-Extreme-and-high-fps-by-default-fo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 142b5fa2107fd7d516a75226a57223710c9684be0d4d25cf6e3cdf231b7e12fb; 2529 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0126-A13-ROB-11560-set-Extreme-and-high-fps-by-default-fo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0127-A13-ROB-11613-set-60-fps-by-default-for-Dungeon-Hunt.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0cc375a8982708e6fd6252ed8f6c10132d97eb474770ffece115acc0b580924c; 1627 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0127-A13-ROB-11613-set-60-fps-by-default-for-Dungeon-Hunt.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0128-A13-ROB-11067-ROB-11494-ROB-12069-block-EditText-set.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 18b4301f41d694b9f6db19d230586f335db3bbf1c6b8dfe1cb69dce2ee4814bc; 1826 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0128-A13-ROB-11067-ROB-11494-ROB-12069-block-EditText-set.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0129-A13-ROB-10676-ROB-11769-By-replacing-OMX.google.h264.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 da00e0b895d450242a6fa707431f1ce7dc230713110ecbdab9033ceb64b4548d; 1396 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0129-A13-ROB-10676-ROB-11769-By-replacing-OMX.google.h264.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0130-A13-Add-protected-broadcast-BST.FILTER.SERVICE.LISTS.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 85825ba2bb6879c1c5e9d38ba6b1f2ac092d6db8556c3b4451935a3f12d7f311; 969 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0130-A13-Add-protected-broadcast-BST.FILTER.SERVICE.LISTS.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0131-A13-Removing-useless-log-of-bstSendTopDisplayedOnFoc.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e8a015553e888ced209f81134d62374a868f26a926fa56c36591c46271b99c71; 2660 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0131-A13-Removing-useless-log-of-bstSendTopDisplayedOnFoc.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0132-A13-Making-sure-the-runtime-permissions-are-granted-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 8f44f130bd348ae781dd33436a82dc6b49aaddbb4ed9701ff979aa09ed4307b5; 3648 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0132-A13-Making-sure-the-runtime-permissions-are-granted-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0133-A13-ROB-12790-Adding-protection-restrictions-for-hom.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ee71b50e2e1607523b80f779911712384b4e175bc88f6909fc0c34b515654580; 2979 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0133-A13-ROB-12790-Adding-protection-restrictions-for-hom.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0134-Revert-A13-Disable-Bluetooth-service.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4326594146ddc4514d026c3eb73b84f88f6c335914e4d9e69528823bebc96129; 1222 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0134-Revert-A13-Disable-Bluetooth-service.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0135-A13-ROB-12596-New-config-entry-GLMBRH.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0cf01ddf94b8c774a0a8b063a3e14f320ab814d2ec630c9a8adbaf67a564fee6; 5970 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0135-A13-ROB-12596-New-config-entry-GLMBRH.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0136-A13-ROB-12223-add-new-entry-IgnoreSyncTimeout.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 61eab4beddc35c9432e0c4069abab36c302283f91fe680fefadab62156ae373f; 5784 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0136-A13-ROB-12223-add-new-entry-IgnoreSyncTimeout.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0137-Case-ROB-13172-allow-reading-of-nowgg-account-for-ev.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9ddcfb9bf0ec5249654aefdff1ea4e90a003c13ea83b312f58797b4e1d43871e; 1334 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0137-Case-ROB-13172-allow-reading-of-nowgg-account-for-ev.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0138-A13-ROB-12555-Adding-onAdsInfoClick-hCall.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 72307fb9d9ceb079dd332e6bbf95c59028362860363b99907146e2dcc22d0c82; 4392 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0138-A13-ROB-12555-Adding-onAdsInfoClick-hCall.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0139-Build-error-fix.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4dbaa8c8a85e67d78ac720f23af7d062960f3af43b283f97d644d0098b356d3f; 1321 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0139-Build-error-fix.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0140-A13-Adding-more-stats-for-affiliate-debugging.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3032ac177b3c0c2568dabc33c54927cbc4d458d140b031308cf43ecdeadb170e; 40476 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0140-A13-Adding-more-stats-for-affiliate-debugging.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0141-Case-ROB-13181-making-source-as-play_store.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 6255915ce2ea29e90b4d85b19013c4c52902cdd4ab2d3e09375374c4a60a93a5; 1387 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0141-Case-ROB-13181-making-source-as-play_store.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0142-A13-ROB-13196-Adding-an-excpetion-for-bstcommandproc.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0155f8a5225f9d366642cfc6a2cb5ccbba43014f0fbd60949c15017f0c70df38; 2964 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0142-A13-ROB-13196-Adding-an-excpetion-for-bstcommandproc.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0143-A13-ROB-13015-adding-hcall-implementation.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 32a5bc69384b371cf2cf011b7c0ec74a6d04bf020ec0042167e2f8b463487192; 6205 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0143-A13-ROB-13015-adding-hcall-implementation.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0144-A13-Not-populating-any-information-about-running-blu.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 001ab790932b67fe0816ced576f78de0a3e40d8e8bc2b70a6abaf4662d59478e; 6203 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0144-A13-Not-populating-any-information-about-running-blu.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0145-A13-ROB-13471-remove-the-hardcore-fix-add-GLVBOCache.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d3f2e7e3c9a243d09e7ef0fe01494d1e07c89c5a29fb76fd926e56d47eb50f91; 5977 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0145-A13-ROB-13471-remove-the-hardcore-fix-add-GLVBOCache.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0146-A13-ROB-13319-add-new-config-entry-called-BEWC.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 52f6091bc00b8efbb7ae20f3827b4f66cccbb712f7db3a40c64f67b6b6eab7f2; 7100 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0146-A13-ROB-13319-add-new-config-entry-called-BEWC.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0147-A13-ROB-13428-Whitelisting-com.bluestacks.home-for-h.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 05280a87771b6bd2c393baefba4b9a51a5314117178531cffcbe79dcbea668cc; 1092 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0147-A13-ROB-13428-Whitelisting-com.bluestacks.home-for-h.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0148-fix-the-recent-rotation-issue-of-switching-between-t.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e0eed334f550af2fabf8f32d1338a700c62ba99c5bbdd9b35b86e5cd47e05538; 3106 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0148-fix-the-recent-rotation-issue-of-switching-between-t.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0149-A13-Adding-hcall-unzip-file.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e311ee6d7cb3535738b1d6ab29e4088cb5edf29461497b7e35bd7f86bf548388; 5247 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0149-A13-Adding-hcall-unzip-file.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0150-A13-Adding-nowbux-updated-hcall.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 5da9d2e971bd905e40b4358616ba14325337bd025ee5f7bfa563705833359453; 4831 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0150-A13-Adding-nowbux-updated-hcall.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0151-A13-Adding-hcall-for-iap-completed.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 8215aee63a35cb49f4000ee4878bdc92da3951112a05d0d1590dd91050e061bf; 6506 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0151-A13-Adding-hcall-for-iap-completed.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0152-A13-ROB-13707-add-new-config-entry-GLHostInfo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b92a301f726c368750f78bfdcd955f4eb7e9655416a3493482d425a8deb3aa53; 5771 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0152-A13-ROB-13707-add-new-config-entry-GLHostInfo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0153-A13-add-a-new-config-entry-gl_extensions_ignore.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 df8d6c7370f3c539f8491ee1009672c5429a69e06b288b463fe52177733e538f; 5771 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0153-A13-add-a-new-config-entry-gl_extensions_ignore.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0154-A13-ROB-14086-add-a-new-config-entry-EGLSurfaceIgnor.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fe4a800edb01b64ec7c2838e81fce2cac1e9ca521531395bbfc70f793655b2d1; 5848 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0154-A13-ROB-14086-add-a-new-config-entry-EGLSurfaceIgnor.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0155-A13-BK-4379-fix-controls-not-working-on-Roblox.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 db01a17b5b21f8be80ef0919e48ed320b8b7052437879ad4bb0ab59db67de7e0; 5713 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0155-A13-BK-4379-fix-controls-not-working-on-Roblox.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0156-A13-ROB-14815-Fixing-uncube-launcher-crashing-issue.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d40e3cbd188383ac880ededaa7b504f35147e6813488024f53e83ec21ae5210d; 8509 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0156-A13-ROB-14815-Fixing-uncube-launcher-crashing-issue.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0157-A13-Prioritize-package-scanning-over-cached-data-in-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c16a1b6e7e12bc636b4c5160b8cdb41fddb48da7142f105ca1af20189f998992; 1657 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0157-A13-Prioritize-package-scanning-over-cached-data-in-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0158-ROB-14931-add-config-entry-iagf.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 7790e0bbc0993847ad71ceda1c069b5ff99e9d65e35a2cb27ac56cfd9da38465; 5925 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0158-ROB-14931-add-config-entry-iagf.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0159-A13-ROB-14596-com.qcwx.fyden-Game-stuck-while-loggin.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c42785b07c13cd7f0eec402431b825819e431cfbe96479d1c805b95ce711d634; 15925 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0159-A13-ROB-14596-com.qcwx.fyden-Game-stuck-while-loggin.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0160-A13-Case-ROB-14975-adding-hcallAllowInstallApkGameCe.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 932a641ce43e6a40aebbb87aa76624e79bde8ca4ee5623de62d709c597039580; 5106 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0160-A13-Case-ROB-14975-adding-hcallAllowInstallApkGameCe.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0161-A13-Pie-Android11-code-sync-change-includes-106.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 18 paths share SHA-256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855; 0 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0161-A13-Pie-Android11-code-sync-change-includes-106.patch`, `patches/android-16/patches/aosp16__art.status`, `patches/android-16/patches/aosp16__build_make.status`, `patches/android-16/patches/aosp16__build_soong.status`, `patches/android-16/patches/aosp16__device_generic_common.status`, `patches/android-16/patches/aosp16__device_generic_goldfish.status`, `patches/android-16/patches/aosp16__device_generic_x86_64.status`, `patches/android-16/patches/aosp16__external_boringssl.status`, `patches/android-16/patches/aosp16__frameworks_base.status`, `patches/android-16/patches/aosp16__frameworks_native.status`, `patches/android-16/patches/aosp16__hardware_google_aemu.status`, `patches/android-16/patches/aosp16__hardware_interfaces.status`, `patches/android-16/patches/aosp16__hardware_libhardware.status`, `patches/android-16/patches/aosp16__packages_apps_Launcher3.status`, `patches/android-16/patches/aosp16__system_core.status`, `patches/android-16/patches/aosp16__system_hwservicemanager.status`, `patches/android-16/patches/aosp16__system_security.status`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0162-A13-Adding-hcall-to-be-called-from-bstcommandprocess.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 029ec307137dd7ca08c2ede2b5661a4bbfa055279c01676b974be6d942cebe4e; 5633 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0162-A13-Adding-hcall-to-be-called-from-bstcommandprocess.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0163-ROB-14354-Enable-GL-Program-Binary-by-default-for-UE.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 86b41b7e9aad9c22419a5fdbda0b57c99e72677cfd266bd341eb550e07ce9258; 9180 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0163-ROB-14354-Enable-GL-Program-Binary-by-default-for-UE.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0164-Case-ROB-15194-bc3-bc7-support-on-GL-mode.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 03582e580ab07ec28d4c8f1a7e963fa68ddf7de3d4fe0bddf1ecde29fd4c03e8; 5609 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0164-Case-ROB-15194-bc3-bc7-support-on-GL-mode.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0165-Case-ROB-15810-sending-JSONObject-instead-of-many-pa.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fc78c81a3a795c8b3a9fab12807744beca019991b33c9b7a8f9410de9a907135; 4484 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0165-Case-ROB-15810-sending-JSONObject-instead-of-many-pa.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0166-Case-ROB-15810-sending-JSONObject-instead-of-many-pa.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c3511d56e962f301381ebbf469d8edfce465389f8f656bf5d45ff039594427d4; 4736 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0166-Case-ROB-15810-sending-JSONObject-instead-of-many-pa.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0167-ROB-15882-Fix-Pokemon-emulator-detection-on-A11-and-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a30d8dc871b5679d955ad3b62c664e1e18a17a0501a302295e5e7cd47aa97cc8; 2406 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0167-ROB-15882-Fix-Pokemon-emulator-detection-on-A11-and-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0168-Case-ROB-16065-not-sending-stat-for-gg.now.accounts-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 49c8d72316ee0c226fd9dccf0ee28ce141befcf740ac68ff640bcdb078a7952d; 1441 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0168-Case-ROB-16065-not-sending-stat-for-gg.now.accounts-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0169-uid-checks.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 042ac253229e3633254170aac2676db8cedefbd7e0a27ccc8b24257e1905e155; 2410 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0169-uid-checks.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0170-ROB-16058-Fix-USB-debugging-detection.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3c02292331550dfd77b112a4f56642052e800cae28a28a85e5526486306bd19f; 1481 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0170-ROB-16058-Fix-USB-debugging-detection.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0171-Review-comments.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3673fc89d34e68823f5332175dffbc73ddba8c62f9a6869fcb7e3b9f0b6937fe; 1292 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0171-Review-comments.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0172-Case-ROB-15589-adding-GP-app-download-stats-178.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 8eb2110d40ac4827c12e8679fdd2482557a59fb71a8658d1ad449e9e165e44aa; 4302 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0172-Case-ROB-15589-adding-GP-app-download-stats-178.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0173-fix-compile-error.-179.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2eb0e77177f45138c9c36e97153b03c1cf0128f89cc98d1fa7ad361827660545; 1263 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0173-fix-compile-error.-179.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0174-case-ROB-15565-enable-vulkan-globally.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 34b9cdeba6389adf5b120390bf6e73d99a4e74322d36b76bc86a0182685e8cba; 6412 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0174-case-ROB-15565-enable-vulkan-globally.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0175-ROB-15990-Support-extractNativeLibs-entry-to-decide-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c8321e13c6318444dde41c25b28c39b02fba4bb19a50abfa568ba18d29e9a674; 11434 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0175-ROB-15990-Support-extractNativeLibs-entry-to-decide-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0176-ROB-15990-Support-extractNativeLibs-entry-to-decide-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 5b92d9a7fffb0222756e8b46af1fe8dd192471ffe0bcb1ce720422fbc4fcbdc9; 11503 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0176-ROB-15990-Support-extractNativeLibs-entry-to-decide-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0177-ROB-15980-Fix-RuneScape-text-is-zoomed-out.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 1a537e6bb4d4514a3a7e304ce0c5c26fa8fe003ed5d0a08cdacd5faa232ab1a3; 1258 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0177-ROB-15980-Fix-RuneScape-text-is-zoomed-out.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0178-ROB-14842-Fix-App-Center-not-getting-launched-throug.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 261d6909c4174dfeb63be7aa46acb96129a7f4a2800448baa1c757f0e3e42289; 3423 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0178-ROB-14842-Fix-App-Center-not-getting-launched-throug.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0179-ROB-16276-add-hcall-onNowggSigninClicked.-184.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 90b6104d61af65dc0640c35690c72e0c90c8e7307cb96adb00e5dfcb86896a99; 5751 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0179-ROB-16276-add-hcall-onNowggSigninClicked.-184.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0180-ROB-16374-update-hcall-onNowggSigninClicked.-185.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 338a8658943cfb47ccafa42b0f4582c2a186144bc37286f5a3b45db8972f90e5; 5292 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0180-ROB-16374-update-hcall-onNowggSigninClicked.-185.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0181-Merge-pull-request-170-from-jason-bst-bst-v5.22.0-RO.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 526e0e62d024a3b4a73f9a56f03ccdd31eebe6ad54b7b1be76c96e5e57c202a1; 3907 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0181-Merge-pull-request-170-from-jason-bst-bst-v5.22.0-RO.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0182-ROB-16443-Fix-nexon-app-emulator-detection-issue-for.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 98bdee908d9a0cdcc8ab146b6dcf0ed512a17dcb7d5e577f10d0c4e7fab1bef5; 1114 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0182-ROB-16443-Fix-nexon-app-emulator-detection-issue-for.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0183-Merge-pull-request-187-from-emin-bst-bst-v5.22.75.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d363088f78da6d551768a4480779306d051ba26f4daa47d9b24226b9c2e67dd8; 24806 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0183-Merge-pull-request-187-from-emin-bst-bst-v5.22.75.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0184-ROB-16456-add-etherNetType-entry-for-freely-switchin.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c17d8dd38d58d4b7ac29e0356a65afdfc6edc6dcd672ae91d21c649d7b782b8b; 7140 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0184-ROB-16456-add-etherNetType-entry-for-freely-switchin.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0185-ROB-16216-Fix-the-UI-is-very-small-issue.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 3af7022670134a2a43fcbceb69bf9682094c8e0f714c9f6f802d405c76f4db59; 10918 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0185-ROB-16216-Fix-the-UI-is-very-small-issue.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0186-ROB-16419-Fix-gamepad-L2-and-R2-do-not-respond.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 180925300eeb897b2b107e820e547152b3cc490b4e7ff41a273d8b47914de7eb; 769 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0186-ROB-16419-Fix-gamepad-L2-and-R2-do-not-respond.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0187-ROB-16694-add-new-config-entries-VkHostInfo-and-vk_d.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 7e9ff238a3e8649f7f84db4bf088e5bade13a935b60de7df719c5fadae601477; 8530 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0187-ROB-16694-add-new-config-entries-VkHostInfo-and-vk_d.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0188-ROB-16756-ROB-16757-modify-input-device-name-to-pass.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 1e130dc1283be63f80b8d4042aa1036ce507cd4ec7b7a79a558ab8ea86aef857; 4887 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0188-ROB-16756-ROB-16757-modify-input-device-name-to-pass.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0189-ROB-16756-ROB-16757-fix-compilation-error.-194.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 2afa1ce5197b9dcd4b88aafd262876e1e117954b36e231ec8c5ce38a028ff9e0; 1523 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0189-ROB-16756-ROB-16757-fix-compilation-error.-194.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0190-ROB-16938-manually-release-the-key-to-fix-shooting-i.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 814afb29f2f3a78ddba60070047b7e79ad96858b924b4b8c4d8d021337c8af57; 2610 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0190-ROB-16938-manually-release-the-key-to-fix-shooting-i.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0191-ROB-16634-porting-IME-fix-to-A13-198.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f6f1ac90f7bba6d45fee0e32221951e8776638f31c122420161372d7a257054a; 5432 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0191-ROB-16634-porting-IME-fix-to-A13-198.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0192-ROB-16938-release-the-key-earlier-199.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a068907f1c8790c1aa32435269e978da7e3742f94d9b0740016d578e514044ad; 2376 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0192-ROB-16938-release-the-key-earlier-199.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0193-ROB-16547-change-isXperfMode-to-getXperfMode-to-supp.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9e03f32de8019d81916ceac8535b997326d15af73ff82d4b55e17c5864d3613d; 7636 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0193-ROB-16547-change-isXperfMode-to-getXperfMode-to-supp.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0194-ROB-16547-Improved-support-for-UE-game-settings-for-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9084adf064bc5f5f643c0fca2cd440c032790872f23f6821697c4dad9d647efa; 4451 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0194-ROB-16547-Improved-support-for-UE-game-settings-for-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0195-ROB-16547-Improved-support-for-UE-game-settings-for-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c0dc5347ffdd6ef6f642edce5f8753d8468d6b6c83239af934a7efa242cb3a00; 3834 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0195-ROB-16547-Improved-support-for-UE-game-settings-for-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0196-ROB-15243-game-settings-based-on-bst.pscore.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c55cd37e59e8c34673a62da814f9ee2ee636c8a3c9d2283ae7db2f120c924a64; 4369 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0196-ROB-15243-game-settings-based-on-bst.pscore.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0197-ROB-16799-fix-A13-unable-take-ScreenShot-issue-204.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4658cfa59e6698f076cbeeee37cb4a33e4a47368f1e7f0f86ed61df4e5842007; 1930 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0197-ROB-16799-fix-A13-unable-take-ScreenShot-issue-204.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0198-Revert-Merge-pull-request-203-from-jason-bst-bst-v5..patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 ec4839cbca60cca87181cd9aefadda7b3cc9fb5e81604f6a84f2a480ea45271d; 4527 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0198-Revert-Merge-pull-request-203-from-jason-bst-bst-v5..patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0199-ROB-15243-add-PScoreAbove-in-config.db.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 21fb5a631ec3d0ac82305d777796fba867359b83daa084de5824e32e5caa319e; 8025 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0199-ROB-15243-add-PScoreAbove-in-config.db.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0200-Fixing-build-error.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 93f6c0c474c03c94c83bc2d0217aaf14aedc4ab711b5eca1610ef4af406ad263; 1346 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0200-Fixing-build-error.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0201-Case-ROB-16097-Explore-if-any-config-entries-can-be-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 7dac766375a10ad3c4f3d11650d42bc22b5364f0d7f04648f7fffd6729b448d6; 26314 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0201-Case-ROB-16097-Explore-if-any-config-entries-can-be-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0202-ROB-16097-Set-vms-entry-as-global-by-default-for-A11.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 eba3b87e4b6a974c43550186d83dc86491cd751b286ae08e84a1a15e875472ee; 5661 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0202-ROB-16097-Set-vms-entry-as-global-by-default-for-A11.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0203-ROB-17750-fix-ncsoft-emulator-detection-issue.-211.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b9628283e9e450e049f1664982566a954bf712967dcaf5a6ab9446f966195c85; 1977 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0203-ROB-17750-fix-ncsoft-emulator-detection-issue.-211.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0204-Merge-pull-request-213-from-dailongzhong-bst-bst-v5..patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fd2bcf9897bc556cfacc0872e3f78ebcd87e2a1c9b12aa39c2a797f9dda31ce4; 5261 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0204-Merge-pull-request-213-from-dailongzhong-bst-bst-v5..patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0205-ROB-16741-Auto-detect-gms-get-token-exception-to-pos.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 7b10a4165253dafe74f5cb04ec2b8c6845606d42c7057e491076db6bdbebaed8; 2639 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0205-ROB-16741-Auto-detect-gms-get-token-exception-to-pos.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0206-ROB-16741-Add-ForceClearGms-entry-to-determine-wheth.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 02604342e39e6e4d06bd1d98012ea6aae758de483d8bfa2fb81e27a85dff96ed; 6116 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0206-ROB-16741-Add-ForceClearGms-entry-to-determine-wheth.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0207-Revert-ROB-16741-Add-ForceClearGms-entry-to-determin.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fe895e7dea84e6e40ab6e20e0594307d3ffa69ec2e4111a8fb1cf15b667f8ec3; 6168 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0207-Revert-ROB-16741-Add-ForceClearGms-entry-to-determin.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0208-Revert-ROB-16741-Auto-detect-gms-get-token-exception.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 27d53208050b7d34d9595dc0335137e199325d81b68901902c63fda7a2377029; 2572 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0208-Revert-ROB-16741-Auto-detect-gms-get-token-exception.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0209-Add-accessible-installation-services-and-support-Goo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 4098e70d07e8aba6cbbf4d34f08ed794a7ec701ea07f0235fb51317dbe89ef22; 2564 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0209-Add-accessible-installation-services-and-support-Goo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0210-Case-ROB-18242-adding-changes-for-hcall-398.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 cb0ad603b7cd6bb8bcd7ca564bb7daa66396f1161e2d0c09f8f5ec8a5f59ca1a; 5261 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0210-Case-ROB-18242-adding-changes-for-hcall-398.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0211-ROB-18340-Add-a-item-called-GLMBRRO-in-config.db-217.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 cccebde1d2000669c13c7b8999157170cbdf1d72169eddc99a5bb6c299250906; 6101 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0211-ROB-18340-Add-a-item-called-GLMBRRO-in-config.db-217.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0212-ROB-18338-filter-out-nativeMouse-device-for-com.nete.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 35345abc662c35148a1f6b69a015e63364ff6f6c0caf1d8db92b8a73e9391068; 3192 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0212-ROB-18338-filter-out-nativeMouse-device-for-com.nete.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0213-BSAI-2-Hide-the-accessibility-interface-to-prevent-i.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 382368d4bdf41b1512b48ac024a6dbb3a5d544694c12d34383cbf0e04c4a975b; 30023 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0213-BSAI-2-Hide-the-accessibility-interface-to-prevent-i.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0214-udpate.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 a3e2fbe077d0032f86c9494a7e2c17b082e8ce8ad334d417b37f61c74a575ba0; 36576 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0214-udpate.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0215-Remove-the-accessibility-service-automatically-insta.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c125a05b29d912840f7657cb5468708f5f68ab524fdc07d8499c63140c3fa497; 2568 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0215-Remove-the-accessibility-service-automatically-insta.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0216-ROB-18546-add-new-entry-FBCCDisabled.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 caf2da38563c4f67200fb4ecab5dbbb01137cb7f35d55b27765cf8940d36d5dd; 6413 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0216-ROB-18546-add-new-entry-FBCCDisabled.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0217-ROB-18546-Correct-the-erroneous-function-224.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 fce7adc7062d32f01af58fe01db8cac2da6ea2009b50e81c20710b3374d0cd2b; 1878 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0217-ROB-18546-Correct-the-erroneous-function-224.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0218-ROB-18620-Surport-NDK-translation-212-226.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 54104430998f08b85dfe9c4ec37c3ec6a591f5ee98fdeee98b0941b2e6a350cc; 6910 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0218-ROB-18620-Surport-NDK-translation-212-226.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0219-ROB-18148-No-audio-when-playing-Instagram-DM-videos-.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9e13bc876c8bb5d8d13301b0928a967a0d8e316433f3603659073c991ac8af55; 5022 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0219-ROB-18148-No-audio-when-playing-Instagram-DM-videos-.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0220-ROB-18546-add-new-entry-FBCCDisabled.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 0f15ba04c608ad8d5d190f1c473298d19b99f78e1f67c061cec92db7e1f91be7; 6482 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0220-ROB-18546-add-new-entry-FBCCDisabled.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0221-ROB-18546-Correct-the-erroneous-function-224.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f47b07c4f2a0d09408bd4fe991dcb8178512d999704ef2b0aef99ddd162e33ce; 1947 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0221-ROB-18546-Correct-the-erroneous-function-224.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0222-ROB-18620-Surport-NDK-translation-212-226.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 c606e02e6e2ba279affc95d5887460e57f42acb6fa4a01ab7e8cc986c4fbe51e; 6836 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0222-ROB-18620-Surport-NDK-translation-212-226.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0223-ROB-14680-fix-cannot-paste-issue-caused-by-device-lo.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 62307363abdedffed0305ec3d11a4d0aac64bc01aa59115bc0eb218680357aa3; 1777 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0223-ROB-14680-fix-cannot-paste-issue-caused-by-device-lo.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `a13-fwbase-patches/0224-ROB-18868-Change-Build.VERSION.SDK_INT-to-30-to-forc.patch`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 b399cea2a2009f343661b92781b7cdbda3e3f142f14937af199d2c470f6e2fb6; 4736 duplicate bytes. Related: `patches/android-16/a13-authority/frameworks-base/0224-ROB-18868-Change-Build.VERSION.SDK_INT-to-30-to-forc.patch`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/bootimage/hd/guest/BootImage/bstsetconf.sh`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 76a2af292cd32b066f533f929b6c80cd7b38428d511b1d6653f17bb8a287d6b1; 7080 duplicate bytes. Related: `references/henry-hd-guest/BootImage/bstsetconf.sh`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/bootimage/hd/guest/Makefile`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 6dc3f5e29a8d60cd880f96927a6734ba05496481bfa23d68600b1d82b5c582b9; 288 duplicate bytes. Related: `references/henry-hd-guest/Makefile`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/patches/aosp16__frameworks_base.base`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 4 paths share SHA-256 1c7c79cf838f05e651cfc1bade886cc89cac8086553ab94c3478266049873537; 123 duplicate bytes. Related: `patches/android-16/patches/aosp16__frameworks_base__d8-subscription.base`, `patches/android-16/patches/aosp16__frameworks_base__pagefusion.base`, `patches/android-16/patches/aosp16__frameworks_base__r262-temp-disable-shell-transitions.base`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/patches/aosp16__frameworks_native.base`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 d016563484fc61f973db5f39e266bafe45540197e985b363d5779755ebb9dd28; 41 duplicate bytes. Related: `patches/android-16/patches/aosp16__frameworks_native_libs_binder.base`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/idc/AlpsPS_2_ALPS_DualPoint_TouchPad.idc`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 4 paths share SHA-256 dc389a47bcba391441586bb7753a8fa22471cacdd4de8cd56092ebd63f71477a; 240 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/idc/AlpsPS_2_ALPS_GlidePoint.idc`, `patches/android-16/untracked-src/aosp16__device_generic_common/idc/ETPS_2_Elantech_Touchpad.idc`, `patches/android-16/untracked-src/aosp16__device_generic_common/idc/Microsoft_Surface_Type_Cover_UNKNOWN.idc`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/idc/QEMU_QEMU_USB_Tablet.idc`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f67464e53a848bc592dc6594df843dd88fbd459fc5c1ee8c9a4d510354144473; 28 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/idc/VirtualBox_USB_Tablet.idc`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/Android.mk`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 67bd463e443d2bb1b3d34a695f7a9b625a2db231a97c96df7d8b88611d9889cb; 663 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/Android.mk`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/OEMBlackList`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 9332c71c704c5e0536078d5de88a87d2c6f28eaaa7f614756b0cc2afff4cf85e; 25 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/OEMBlackList`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/OEMWhiteList`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 39df4ac04bae7937aa64dc7ab6782d2f10e7a8a5c9ef4076fc6a89801bddbca9; 21 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/OEMWhiteList`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/ThirdPartySO`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 f739d8c0018baee216c575707b793249121b4a4db4ef9208ed48e9b28994dea2; 3386 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/ThirdPartySO`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/libnb.cpp`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 af812312fc8abf0e27264730dcb52338df7ec3c75a8af352223cd542af35c087; 25812 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/libnb.cpp`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge.mk`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 faca38f67b3745a206c7fcbf811b3d78dfec5f3dea56462111dc8f00e990a727; 1167 duplicate bytes. Related: `patches/android-16/untracked-src/aosp16__device_generic_common/nativebridge/nativebridge/nativebridge.mk`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `patches/android-16/untracked-src/aosp16__frameworks_base/core/java/android/util/BstUtils.java`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 22d0f9cbc2c3f876eff7cb9b1ac6b658fc876e6cf060f054327822e91a30c577; 3006 duplicate bytes. Related: `scripts/_ref_BstUtils_a16.java`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `references/henry-hd-guest/BootImage/init.sh`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 df335419be7d116fc93ee00b11b2c37f9399d5189e7f324a90d937b0f4630344; 9085 duplicate bytes. Related: `references/henry-hd-guest/init.sh`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.

### `references/henry-hd-guest/BootImage/stage2.sh`: Exact duplicate content

- Status: `preserve-pending-semantic-review`
- Evidence: 2 paths share SHA-256 e57e6eb264e27959a387f2a51eb355fcca197215714830fd496d726dc7be9618; 2861 duplicate bytes. Related: `references/henry-hd-guest/stage2.sh`
- Action: Preserve layout-significant aliases; otherwise identify a canonical source before consolidation.
