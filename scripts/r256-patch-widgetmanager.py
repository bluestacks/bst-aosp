#!/usr/bin/env python3
"""R256: Henry BS-A16 — null-guard AppWidgetManager in WidgetManagerHelper.allWidgetsSteam.

Henry comment:
  BS-A16: AppWidget service may not be available on BlueStacks (no
  appwidget HAL). Guard against null to prevent crash-loop.
"""
from pathlib import Path
import sys

SRC = Path.home() / "aosp16/packages/apps/Launcher3/src/com/android/launcher3/widget/WidgetManagerHelper.java"
if len(sys.argv) > 1:
    SRC = Path(sys.argv[1])

MARKER = "R256 / Henry BS-A16 AppWidget null-guard"
text = SRC.read_text()
if MARKER in text or "AppWidget service may not be available on BlueStacks" in text:
    print(f"already patched: {SRC}")
    sys.exit(0)

needle = """    private static Stream<AppWidgetProviderInfo> allWidgetsSteam(Context context) {
        AppWidgetManager awm = context.getSystemService(AppWidgetManager.class);
        return Stream.concat(
"""
insert = """    private static Stream<AppWidgetProviderInfo> allWidgetsSteam(Context context) {
        // R256 / Henry BS-A16 AppWidget null-guard
        // BS-A16: AppWidget service may not be available on BlueStacks (no
        // appwidget HAL). Guard against null to prevent crash-loop.
        AppWidgetManager awm = context.getSystemService(AppWidgetManager.class);
        if (awm == null) {
            return Stream.empty();
        }
        return Stream.concat(
"""
if needle not in text:
    print("needle not found", file=sys.stderr)
    sys.exit(1)

SRC.write_text(text.replace(needle, insert, 1))
print(f"patched {SRC}")
