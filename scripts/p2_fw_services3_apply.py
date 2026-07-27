#!/usr/bin/env python3
# P2-FW-SERVICES-3: AccountManagerService Google/now.gg host account hooks (a13).
import os
import sys

A16 = os.path.expanduser("~/aosp16/frameworks/base")
MARKER = "A16DBG:P2:FW-SERVICES-3"
ERRS = []
AMS = "services/core/java/com/android/server/accounts/AccountManagerService.java"


def patch(rel, replacements, label):
    full = os.path.join(A16, rel)
    with open(full) as f:
        src = f.read()
    if MARKER in src:
        print(f"SKIP {label} (already patched)")
        return
    orig = src
    for old, new in replacements:
        if old not in src:
            ERRS.append(f"{label}: ANCHOR NOT FOUND: {old.strip()[:80]!r}")
            return
        if src.count(old) > 1:
            ERRS.append(
                f"{label}: ANCHOR NOT UNIQUE ({src.count(old)}): {old.strip()[:80]!r}"
            )
            return
        src = src.replace(old, new, 1)
    if src == orig:
        ERRS.append(f"{label}: no change")
        return
    with open(full, "w") as f:
        f.write(src)
    print(f"OK   {label}")


GET_BST = """
    // A16DBG:P2:FW-SERVICES-3 lazy BstHostCallManager (a13 account host callbacks)
    private BstHostCallManager getBstHostCallManager() {
        if (mBstHostCallManagerService == null) {
            mBstHostCallManagerService = (BstHostCallManager) mContext.getSystemService(
                    Context.BST_HOST_CALL);
        }
        return mBstHostCallManagerService;
    }

    void setGoogleAdId() {
        Intent intent = new Intent();
        ComponentName cn = new ComponentName("com.bluestacks.BstCommandProcessor",
                "com.bluestacks.BstCommandProcessor.BstCommandProcessorService");
        intent.setAction("setGoogleAdId");
        intent.setComponent(cn);
        mContext.startServiceAsUser(intent, new UserHandle(UserHandle.USER_CURRENT));
    }

"""

patch(
    AMS,
    [
        (
            "import android.os.UserHandle;\n",
            "import android.os.SystemProperties;\n"
            "import android.os.UserHandle;\n",
        ),
        (
            "import com.android.server.LocalServices;\n",
            "import com.android.server.LocalServices;\n\n"
            "import com.bluestacks.os.BstHostCallManager;\n",
        ),
        (
            "    private static final int MESSAGE_COPY_SHARED_ACCOUNT = 4;\n",
            "    private static final int MESSAGE_COPY_SHARED_ACCOUNT = 4;\n\n"
            "    private static final int BST_ACCOUNT_ADDED = 0;\n"
            "    private static final int BST_ACCOUNT_REMOVED = 1;\n",
        ),
        (
            "    private UserManager mUserManager;\n"
            "    private final Injector mInjector;\n",
            "    private UserManager mUserManager;\n"
            "    private BstHostCallManager mBstHostCallManagerService;\n"
            "    private final Injector mInjector;\n",
        ),
        (
            "                            } finally {\n"
            "                                accountsDb.endTransaction();\n"
            "                            }\n"
            "                            accountDeleted = true;\n",
            "                            } finally {\n"
            "                                accountsDb.endTransaction();\n"
            "                            }\n\n"
            "                            // A16DBG:P2:FW-SERVICES-3 obsolete-auth account remove host notify\n"
            "                            BstHostCallManager bstHost = getBstHostCallManager();\n"
            "                            if (bstHost != null) {\n"
            "                                if (\"com.google\".equals(account.type)) {\n"
            "                                    bstHost.googleAccountListUpdated(\n"
            "                                            account.name, BST_ACCOUNT_REMOVED);\n"
            "                                } else if (\"now.gg\".equals(account.type)) {\n"
            "                                    bstHost.onNowggAccountRemoved(account.name);\n"
            "                                }\n"
            "                            }\n\n"
            "                            accountDeleted = true;\n",
        ),
        (
            "        if (getUserManager().getUserInfo(accounts.userId).canHaveProfile()) {\n"
            "            addAccountToLinkedRestrictedUsers(account, accounts.userId);\n"
            "        }\n\n"
            "        sendNotificationAccountUpdated(account, accounts);\n",
            "        if (getUserManager().getUserInfo(accounts.userId).canHaveProfile()) {\n"
            "            addAccountToLinkedRestrictedUsers(account, accounts.userId);\n"
            "        }\n\n"
            "        // A16DBG:P2:FW-SERVICES-3 Google account add host notify (a13)\n"
            "        String type = account.type;\n"
            "        BstHostCallManager bstHostAdd = getBstHostCallManager();\n"
            "        if (bstHostAdd != null && \"com.google\".equals(type)\n"
            "                && SystemProperties.get(\"persist.sys.user.email\", \"\").isEmpty()) {\n"
            "            SystemProperties.set(\"persist.sys.user.email\", account.name);\n"
            "            if (SystemProperties.get(\"bst.bluestacks_account_id\", \"\").isEmpty()) {\n"
            "                SystemProperties.set(\"bst.bluestacks_account_id\", account.name);\n"
            "                bstHostAdd.onGoogleLoginCompleted(account.name);\n"
            "            }\n"
            "        }\n"
            "        if (bstHostAdd != null && \"com.google\".equals(account.type)) {\n"
            "            bstHostAdd.googleAccountListUpdated(account.name, BST_ACCOUNT_ADDED);\n"
            "        }\n\n"
            "        sendNotificationAccountUpdated(account, accounts);\n",
        ),
        (
            "                if (isChanged) {\n"
            "                    removeAccountFromCacheLocked(accounts, account);\n",
            "                if (isChanged) {\n"
            "                    // A16DBG:P2:FW-SERVICES-3 explicit account remove host notify\n"
            "                    BstHostCallManager bstHostRm = getBstHostCallManager();\n"
            "                    if (bstHostRm != null) {\n"
            "                        if (\"com.google\".equals(account.type)) {\n"
            "                            bstHostRm.googleAccountListUpdated(\n"
            "                                    account.name, BST_ACCOUNT_REMOVED);\n"
            "                        } else if (\"now.gg\".equals(account.type)) {\n"
            "                            bstHostRm.onNowggAccountRemoved(account.name);\n"
            "                        }\n"
            "                    }\n"
            "                    removeAccountFromCacheLocked(accounts, account);\n",
        ),
        (
            "    private boolean isSpecialPackageKey(String packageName) {\n"
            "        return (AccountManager.PACKAGE_NAME_KEY_LEGACY_VISIBLE.equals(packageName)\n"
            "                || AccountManager.PACKAGE_NAME_KEY_LEGACY_NOT_VISIBLE.equals(packageName));\n"
            "    }\n\n"
            "    private void sendAccountsChangedBroadcast(\n",
            GET_BST
            + "    private boolean isSpecialPackageKey(String packageName) {\n"
            "        return (AccountManager.PACKAGE_NAME_KEY_LEGACY_VISIBLE.equals(packageName)\n"
            "                || AccountManager.PACKAGE_NAME_KEY_LEGACY_NOT_VISIBLE.equals(packageName));\n"
            "    }\n\n"
            "    private void sendAccountsChangedBroadcast(\n",
        ),
        (
            "    private void sendAccountsChangedBroadcast(\n"
            "            int userId, String accountType, @NonNull String useCase) {\n"
            "        Objects.requireNonNull(useCase, \"useCase can't be null\");\n",
            "    private void sendAccountsChangedBroadcast(\n"
            "            int userId, String accountType, @NonNull String useCase) {\n"
            "        Objects.requireNonNull(useCase, \"useCase can't be null\");\n"
            "        setGoogleAdId();\n",
        ),
    ],
    "AccountManagerService",
)

if ERRS:
    for e in ERRS:
        print(f"ERROR {e}", file=sys.stderr)
    sys.exit(1)

print(f"VERIFY {MARKER}:", MARKER in open(os.path.join(A16, AMS)).read())
