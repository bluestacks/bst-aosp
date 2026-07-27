#!/usr/bin/env python3
# P2-FW-CORE-APP-8: PaymentRedirectProxyActivity + ActivityThread IAP redirect (a13->a16).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
ERRS = []

PAYMENT_REDIRECT = """\
package com.android.internal.app;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;

import com.bluestacks.os.BstHostCallManager;

import android.content.SharedPreferences;

// A16DBG:P2:FW-CORE-APP-8 Google Play IAP redirect proxy (a13)
public class PaymentRedirectProxyActivity extends Activity {
    private static final int REQ_CODE = 100;
    private static final String SHARED_CONFIG_FILE_NAME = "bst_sp_iap_settings";
    private static final String SP_KEY_DONT_SHOW_AGAIN = "sp_dont_show_again";
    private static final String SP_KEY_IAP_CLICK_ACTION_TYPE = "sp_click_action_type";
    private static final String BST_IAP_SETTING_KEY = "bst_iap_setting";

    private Bundle origBundle;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        origBundle = getIntent().getExtras();

        SharedPreferences sp = getSharedPreferences(SHARED_CONFIG_FILE_NAME, Context.MODE_PRIVATE);

        Intent chooseIntent = new Intent();
        chooseIntent.setClassName(
                "gg.now.billing.interceptor",
                "gg.now.billing.interceptor.PaymentChooserActivity");
        chooseIntent.putExtra("bst_from_pkg", getPackageName());
        chooseIntent.putExtra("bst_from_app_version", getAppVersionName());
        chooseIntent.putExtra(
                "bst_dont_show_agin", sp.getBoolean(SP_KEY_DONT_SHOW_AGAIN, false));
        chooseIntent.putExtra(
                "bst_click_action_type", sp.getString(SP_KEY_IAP_CLICK_ACTION_TYPE, "PlayStoreIAP"));
        if (origBundle != null) {
            chooseIntent.putExtra(BST_IAP_SETTING_KEY, origBundle.getString(BST_IAP_SETTING_KEY));
        }
        startActivityForResult(chooseIntent, REQ_CODE);
    }

    private String getAppVersionName() {
        String versionName = "";
        try {
            PackageInfo pInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            versionName = pInfo.versionName;
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
        return versionName;
    }

    private static void cancelPurchase(final Context context) {
        Intent intent = new Intent("com.android.vending.billing.PURCHASES_UPDATED");
        intent.setPackage(context.getApplicationContext().getPackageName());
        intent.putExtra("RESPONSE_CODE", 1);
        intent.putExtra("DEBUG_MESSAGE", "Billing dialog closed.");
        context.sendBroadcast(intent);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQ_CODE && resultCode == RESULT_OK) {
            boolean dontShowAgain = data.getBooleanExtra("bst_dont_show_agin", false);
            String actionType = data.getStringExtra("action_type");
            String actionData = data.getStringExtra("action_data");
            if (dontShowAgain) {
                SharedPreferences.Editor editor =
                        getSharedPreferences(SHARED_CONFIG_FILE_NAME, Context.MODE_PRIVATE).edit();
                editor.putBoolean(SP_KEY_DONT_SHOW_AGAIN, true);
                editor.putString(SP_KEY_IAP_CLICK_ACTION_TYPE, actionType);
                editor.apply();
            }
            if (TextUtils.equals(actionType, "PlayStoreIAP")) {
                Intent launchIntent = new Intent();
                launchIntent.setClassName(this, "com.android.billingclient.api.ProxyBillingActivity");
                launchIntent.putExtras(origBundle);
                launchIntent.removeExtra(BST_IAP_SETTING_KEY);
                launchIntent.putExtra("bst_hooked", true);
                startActivity(launchIntent);
                finish();
                return;
            } else if (TextUtils.equals(actionType, "OpenGuestUrl")) {
                Intent viewIntent = new Intent(Intent.ACTION_VIEW);
                viewIntent.setData(Uri.parse(actionData));
                startActivity(viewIntent);
                cancelPurchase(this);
                finish();
                return;
            } else if (TextUtils.equals(actionType, "ApplicationBrowser")
                    || TextUtils.equals(actionType, "UserBrowser")) {
                BstHostCallManager bstHostCallManagerService =
                        (BstHostCallManager) getSystemService(Context.BST_HOST_CALL);
                if (bstHostCallManagerService != null) {
                    bstHostCallManagerService.handleCustomIap(actionType, actionData);
                }
                cancelPurchase(this);
                finish();
                return;
            }
        }
        cancelPurchase(this);
        finish();
    }
}
"""


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:70]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:70]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


def write_new(rel, content, label):
    full = os.path.join(A16, rel)
    if os.path.exists(full):
        with open(full) as f:
            if "A16DBG:P2:FW-CORE-APP-8" in f.read():
                print(f"SKIP {label} (already present)")
                return
        ERRS.append(f"{label}: file exists without marker")
        return
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)
    print(f"OK   {label}")


write_new(
    "core/java/com/android/internal/app/PaymentRedirectProxyActivity.java",
    PAYMENT_REDIRECT,
    "PaymentRedirectProxyActivity new file",
)

BST_HELPERS = """
    // A16DBG:P2:FW-CORE-APP-8 ActivityThread BST helpers (a13 IAP redirect)
    private static Object bstGetDeclaredField(Object instance, String fieldName) {
        try {
            Field field = instance.getClass().getDeclaredField(fieldName);
            field.setAccessible(true);
            return field.get(instance);
        } catch (ReflectiveOperationException e) {
            // fall through
        }
        return null;
    }

    private void bstRedirectProxyBillingIfNeeded(ClientTransaction transaction) {
        List<ClientTransactionItem> clientCallbacks = transaction.getCallbacks();
        if (clientCallbacks == null) {
            return;
        }
        BstFilterAppsManager bfam = (BstFilterAppsManager)
                getSystemContext().getSystemService(Context.BST_FILTER_APPS);
        if (bfam == null) {
            return;
        }
        for (ClientTransactionItem item : clientCallbacks) {
            Intent launchIntent = (Intent) bstGetDeclaredField(item, "mIntent");
            ComponentName origComponent =
                    launchIntent != null ? launchIntent.getComponent() : null;
            if (launchIntent == null || origComponent == null) {
                continue;
            }
            if (!"com.android.billingclient.api.ProxyBillingActivity".equals(
                    origComponent.getClassName())) {
                continue;
            }
            Slog.d(TAG, "A16DBG:P2:FW-CORE-APP-8 proxy billing " + origComponent);
            if (launchIntent.hasExtra("bst_hooked")) {
                continue;
            }
            String iapSetting = bfam.getIapSetting(origComponent.getPackageName());
            if (iapSetting == null || iapSetting.isEmpty()) {
                continue;
            }
            launchIntent.setComponent(new ComponentName(
                    origComponent.getPackageName(),
                    "com.android.internal.app.PaymentRedirectProxyActivity"));
            launchIntent.putExtra("bst_iap_setting", iapSetting);
        }
    }

"""

patch(
    "core/java/android/app/ActivityThread.java",
    [
        (
            "import android.app.servertransaction.ClientTransaction;\n",
            "import android.app.servertransaction.ClientTransaction;\n"
            "import android.app.servertransaction.ClientTransactionItem;\n",
        ),
        (
            "import com.android.server.am.MemInfoDumpProto;\n",
            "import com.android.server.am.MemInfoDumpProto;\n\n"
            "import com.bluestacks.os.BstFilterAppsManager;\n",
        ),
        (
            "import java.lang.reflect.Method;\n",
            "import java.lang.reflect.Field;\nimport java.lang.reflect.Method;\n",
        ),
        (
            "        throw new ForegroundServiceDidNotStartInTimeException(message, inner);\n    }\n",
            "        throw new ForegroundServiceDidNotStartInTimeException(message, inner);\n    }\n"
            + BST_HELPERS,
        ),
        (
            """                case EXECUTE_TRANSACTION:
                    final ClientTransaction transaction = (ClientTransaction) msg.obj;
                    final ClientTransactionListenerController controller =
                            ClientTransactionListenerController.getInstance();
                    controller.onClientTransactionStarted();
                    try {
                        mTransactionExecutor.execute(transaction);
                    } finally {
                        controller.onClientTransactionFinished();
                    }
                    break;
""",
            """                case EXECUTE_TRANSACTION:
                    final ClientTransaction transaction = (ClientTransaction) msg.obj;
                    final ClientTransactionListenerController controller =
                            ClientTransactionListenerController.getInstance();
                    controller.onClientTransactionStarted();
                    try {
                        bstRedirectProxyBillingIfNeeded(transaction);
                        mTransactionExecutor.execute(transaction);
                    } finally {
                        controller.onClientTransactionFinished();
                    }
                    break;
""",
        ),
    ],
    "ActivityThread IAP redirect",
)

if ERRS:
    print("\n=== ERRORS ===")
    for e in ERRS:
        print("  " + e)
    sys.exit(1)
print("\nALL OK — run `m droid` next")
