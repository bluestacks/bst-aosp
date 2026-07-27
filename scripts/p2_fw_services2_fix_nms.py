#!/usr/bin/env python3
# Repair FW-SERVICES-2 NMS: move sendNotificationToHost out of broken javadoc block.
import re
import sys

path = __import__("os").path.expanduser(
    "~/aosp16/frameworks/base/services/core/java/com/android/server/"
    "notification/NotificationManagerService.java"
)
src = open(path).read()
if "private void sendNotificationToHost" not in src:
    print("SKIP: method missing")
    sys.exit(0)
if "     * Asynchronously notify" in src.split("private void sendNotificationToHost")[0][-200:]:
    print("SKIP: already fixed")
    sys.exit(0)

# Extract method block (comment through closing brace before javadoc tail)
m = re.search(
    r"(    // A16DBG:P2:FW-SERVICES-2 send non-system.*?\n    \}\n\n)"
    r"     \* <p>Also takes care of removing",
    src,
    re.DOTALL,
)
if not m:
    print("ERROR: broken block not found")
    sys.exit(1)

method_block = m.group(1)

# Remove method from inside javadoc
src = src.replace(method_block, "", 1)

# Restore javadoc opening that lost its continuation
src = src.replace(
    "     * when every {@link NotificationListenerService} has received the news.\n"
    "     *\n\n"
    "     * <p>Also takes care",
    "     * when every {@link NotificationListenerService} has received the news.\n"
    "     *\n"
    "     * <p>Also takes care",
    1,
)

# Insert method before notify javadoc
anchor = (
    "    /**\n"
    "     * Asynchronously notify all listeners about a posted (new or updated) notification. This\n"
)
if anchor not in src:
    print("ERROR: insert anchor missing")
    sys.exit(1)
src = src.replace(anchor, method_block + anchor, 1)

open(path, "w").write(src)
print("OK   NMS javadoc repair")
