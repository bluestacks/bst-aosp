#!/usr/bin/env python3
"""R249 / Henry 7Y: /proc/config.gz missing → CHECK abort → ALOGW fallback."""
from pathlib import Path

PATH = Path.home() / "aosp16/frameworks/base/core/jni/android_os_Debug.cpp"
MARK = "R249 / Henry 7Y"

OLD = """    if (cfg_state == CONFIG_UNKNOWN) {
        std::map<std::string, std::string> configs;
        const status_t result = android::kernelconfigs::LoadKernelConfigs(&configs);
        CHECK(result == OK) << "Kernel configs could not be fetched. b/151092221";
        std::map<std::string, std::string>::const_iterator it = configs.find("CONFIG_VMAP_STACK");
        cfg_state = (it != configs.end() && it->second == "y") ? CONFIG_SET : CONFIG_UNSET;
    }"""

NEW = """    if (cfg_state == CONFIG_UNKNOWN) {
        std::map<std::string, std::string> configs;
        const status_t result = android::kernelconfigs::LoadKernelConfigs(&configs);
        // R249 / Henry 7Y: BS kernel may lack CONFIG_IKCONFIG (/proc/config.gz).
        if (result != OK) {
            ALOGW("Kernel configs could not be fetched (no /proc/config.gz). "
                  "Assuming CONFIG_VMAP_STACK=n.");
            cfg_state = CONFIG_UNSET;
        } else {
            std::map<std::string, std::string>::const_iterator it =
                    configs.find("CONFIG_VMAP_STACK");
            cfg_state = (it != configs.end() && it->second == "y") ? CONFIG_SET : CONFIG_UNSET;
        }
    }"""


def main() -> None:
    text = PATH.read_text()
    if MARK in text:
        print("already patched")
        return
    if OLD not in text:
        raise SystemExit("anchor not found in android_os_Debug.cpp")
    PATH.write_text(text.replace(OLD, NEW, 1))
    print(f"patched {PATH}")


if __name__ == "__main__":
    main()
