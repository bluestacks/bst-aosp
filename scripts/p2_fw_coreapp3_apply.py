#!/usr/bin/env python3
# P2-FW-CORE-APP-3 (foundation): Instrumentation bst methods + ContextImpl bst intent hook (a13->a16).
# Instrumentation: +bstHandleProprietryIntents (market/mailto/gm/maps/youtube Toast) + bstReferrerHack
# (play-store referrer capture -> BstCommandProcessor). ContextImpl: cred-storage bluestacks whitelist +
# startActivityAsUser bst hook. startActivityAsUser is a warm path (every activity start) but hooks are
# cheap early-returns + try-catch wrapped. Robust exact-string replace.
import os, sys
A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []

def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f: src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}"); return
        if src.count(old) > 1:
            ERRS.append(f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"); return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change"); return
    with open(full, "w") as f: f.write(src)
    print(f"OK   {label}")

INSTR_METHODS = '''
    // A16DBG:P2:FW-CORE-APP-3 BST instrumentation foundation (a13)
    private static final String BST_TAG = "Bst-Instrumentation";
    private static final String BST_TAG_REFERRAL = "Bst-Instrumentation-Affiliate";
    private static final boolean BST_DBG = SystemProperties.getInt("bst.debug.instrumentation", 0) > 0;
    private static final boolean BST_DBG_REFERRAL = BST_DBG || SystemProperties.getInt("bst.debug.referral", 0) > 0;

    /** @hide
     * a13: handle market:// mailto: gm/maps/youtube/vending unresolved intents with a Toast (no crash). */
    public int bstHandleProprietryIntents(@Nullable Context who, int result, @Nullable Intent intent) {
        try {
            if (who == null || intent == null) return result;
            String data = "";
            if (intent.getData() != null) data = intent.getData().toString().toLowerCase();
            ComponentName mComponent = intent.getComponent();
            Log.w(BST_TAG, "Unresolved intent: cmp: " + mComponent + " data: " + data);
            if (data.startsWith("market:")) {
                result = ActivityManager.START_SUCCESS;
                Toast t = Toast.makeText(who, "Sorry, this feature is not supported currently", Toast.LENGTH_LONG);
                t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
            } else if (data.startsWith("mailto:")) {
                result = ActivityManager.START_SUCCESS;
                Toast t = Toast.makeText(who, "This app requires an Email app to send e-mail. Please install one and retry this.", Toast.LENGTH_LONG);
                t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
            } else if (mComponent != null) {
                String cn = mComponent.flattenToShortString();
                if (cn.startsWith("com.google.android.gm") && !cn.endsWith(".Main")) {
                    result = ActivityManager.START_SUCCESS;
                    Toast t = Toast.makeText(who, "This app requires GMail. Please install the GMail app and retry this.", Toast.LENGTH_LONG);
                    t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
                } else if (cn.startsWith("com.google.android.apps.maps") && !cn.endsWith(".Main")) {
                    result = ActivityManager.START_SUCCESS;
                    Toast t = Toast.makeText(who, "This app requires Google Maps. Please install the Google Maps app and retry this.", Toast.LENGTH_LONG);
                    t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
                } else if (cn.startsWith("com.google.android.youtube") && !cn.endsWith(".Main")) {
                    result = ActivityManager.START_SUCCESS;
                    Toast t = Toast.makeText(who, "This app requires YouTube. Please install the YouTube app and retry this.", Toast.LENGTH_LONG);
                    t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
                } else if (cn.startsWith("com.google.android.voicesearch") && !cn.endsWith(".Main")) {
                    result = ActivityManager.START_SUCCESS;
                    Toast t = Toast.makeText(who, "This app requires Voice Search. Please install the Voice Search app and retry this.", Toast.LENGTH_LONG);
                    t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
                } else if (cn.startsWith("com.android.vending") && !cn.endsWith(".Main")) {
                    result = ActivityManager.START_SUCCESS;
                    Toast t = Toast.makeText(who, "Sorry, this feature is not supported currently", Toast.LENGTH_LONG);
                    t.setGravity(Gravity.BOTTOM, 0, 0); t.show();
                }
            }
        } catch (Exception ex) {
            Log.w(BST_TAG, "Exception occured while handling intent");
        }
        return result;
    }

    /** @hide
     * a13: capture play-store/market referrer, notify BstCommandProcessor. */
    public void bstReferrerHack(@Nullable Context context, @Nullable Intent mIntent) {
        if (context == null || mIntent == null) return;
        String intentData = mIntent.getDataString();
        if (intentData == null) return;
        if (BST_DBG_REFERRAL) Log.d(BST_TAG_REFERRAL, "intentData = " + intentData);
        if (intentData.startsWith("https://play.google.com/store/apps/details")
                || intentData.startsWith("http://play.google.com/store/apps/details")
                || intentData.startsWith("https://market.android.com/details")
                || intentData.startsWith("http://market.android.com/details")
                || intentData.startsWith("market://details")) {
            String packageName = null, referrer = null, value = "", key = "";
            int q = intentData.indexOf("?");
            String values = q >= 0 ? intentData.substring(q + 1) : "";
            for (String str : values.split("&")) {
                try {
                    String[] keyValue = str.split("=");
                    key = keyValue[0];
                    if (keyValue.length > 1) value = keyValue[1];
                    if (key.equals("id")) packageName = value;
                    else if (key.equals("referrer")) referrer = value;
                } catch (Exception e) {
                    Log.e(BST_TAG_REFERRAL, "Exception parsing: " + str);
                }
            }
            try {
                Intent intent = new Intent();
                if (referrer != null) {
                    BstUtilsManager bstutils = (BstUtilsManager) context.getSystemService(Context.BST_UTILS);
                    if (bstutils != null) bstutils.setProperty("bst.config.referrerpackage", packageName);
                    intent.setAction("BST_UPDATE_REFERRERLIST_ADD");
                } else {
                    intent.setAction("BST_UPDATE_REFERRERLIST_REMOVE");
                }
                intent.setComponent(new ComponentName("com.bluestacks.BstCommandProcessor",
                        "com.bluestacks.BstCommandProcessor.BstCommandProcessorService"));
                intent.putExtra("packageName", packageName);
                context.startService(intent);
            } catch (Exception ex) {
                Log.w(BST_TAG_REFERRAL, "Exception updating referrer list: " + ex.getMessage());
            }
        }
    }
'''

patch("core/java/android/app/Instrumentation.java", [
    ("import java.util.concurrent.TimeoutException;\n",
     "import java.util.concurrent.TimeoutException;\n"
     "import android.view.Gravity;\nimport android.widget.Toast;\n"
     "import com.bluestacks.os.BstFilterAppsManager;\n"
     "import com.bluestacks.os.BstHostCallManager;\n"
     "import com.bluestacks.os.BstUtilsManager;\nimport org.json.JSONObject;\n"),
    ("    public static final String TAG = \"Instrumentation\";\n",
     "    public static final String TAG = \"Instrumentation\";\n" + INSTR_METHODS + "\n"),
], "Instrumentation.bst methods (foundation)")

patch("core/java/android/app/ContextImpl.java", [
    ("                        if (!um.isUserUnlockingOrUnlocked(UserHandle.myUserId())) {\n",
     "                        // A16DBG:P2:FW-CORE-APP-3 a13: allow bluestacks/gms/location pre-unlock cred storage\n"
     "                        if (!um.isUserUnlockingOrUnlocked(UserHandle.myUserId())\n"
     "                                && !getPackageName().startsWith(\"com.bluestacks.\")\n"
     "                                && !getPackageName().equals(\"com.location.provider\")\n"
     "                                && !getPackageName().equals(\"com.google.android.gms\")) {\n"),
    ("""            intent.collectExtraIntentKeys();
            ActivityTaskManager.getService().startActivityAsUser(
                    mMainThread.getApplicationThread(), getOpPackageName(), getAttributionTag(),
                    intent, intent.resolveTypeIfNeeded(getContentResolver()),
                    null, null, 0, Intent.FLAG_ACTIVITY_NEW_TASK, null,
                    applyLaunchDisplayIfNeeded(options), user.getIdentifier());
""",
     """            intent.collectExtraIntentKeys();
            mMainThread.getInstrumentation().bstReferrerHack(getOuterContext(), intent);
            int res = ActivityTaskManager.getService().startActivityAsUser(
                    mMainThread.getApplicationThread(), getOpPackageName(), getAttributionTag(),
                    intent, intent.resolveTypeIfNeeded(getContentResolver()),
                    null, null, 0, Intent.FLAG_ACTIVITY_NEW_TASK, null,
                    applyLaunchDisplayIfNeeded(options), user.getIdentifier());
            if (res == ActivityManager.START_INTENT_NOT_RESOLVED
                    || res == ActivityManager.START_CLASS_NOT_FOUND) {
                res = mMainThread.getInstrumentation().bstHandleProprietryIntents(getOuterContext(), res, intent);
            }
            mMainThread.getInstrumentation().checkStartActivityResult(res, intent);
"""),
], "ContextImpl.cred + startActivityAsUser bst hook")

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS: print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
