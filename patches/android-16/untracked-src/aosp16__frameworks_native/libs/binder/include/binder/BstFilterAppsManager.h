#ifndef BST_FILTER_APPS_MANAGER_H_
#define BST_FILTER_APPS_MANAGER_H_
#include <utils/String16.h>
#include <utils/String8.h>
namespace android {
class BstFilterAppsManager {
public:
    BstFilterAppsManager() {}
    bool isAGAGL3Disabled(const String16&) { return false; }
    bool isAppBlockedInFGForGL3(const String16&) { return false; }
    bool isASTCApp(const String16&) { return false; }
    bool isAstcApp(const String16&) { return false; }
    bool isS3tcApp(const String16&) { return false; }
    bool isBptcApp(const String16&) { return false; }
    bool isPvrtcApp(const String16&) { return false; }
    bool isHppEnabled(const String16&) { return false; }
    bool isImageDetectionEnabled(const String16&) { return false; }
    bool isAngleDisabled(const String16&) { return false; }
    bool isIntelAutoGLFlushApp(const String16&) { return false; }
    String8 isVulkanRequired(const String16&) { return String8("false"); }
    bool isGLVBOCacheDisableApp(const String16&) { return false; }
    bool isFbCompleteCheckDisabled(const String16&) { return false; }
    bool isUE4GLFlushApp(const String16&) { return false; }
    bool isGLInvalidateFramebufferFilterApp(const String16&) { return false; }
    bool isIntelGLDispatchComputeFlushApp(const String16&) { return false; }
    bool isIgnoreSyncTimeout(const String16&) { return false; }
    bool isGlNativeSyncDisabled(const String16&) { return false; }
    bool isGLProgramBinaryApp(const String16&) { return false; }
    bool isUnreal5App(const String16&) { return false; }
    bool isUE5PBDisabled(const String16&) { return false; }
    bool isGLUnmapBufferPerfApp(const String16&) { return false; }
    bool isTexTargetCheckDisabled(const String16&) { return false; }
    bool isGlMapBufferRangeHost(const String16&) { return false; }
    bool isMapBufRangeReadOnceEnabled(const String16&) { return false; }
    bool isEncodeDCEnabled(const String16&) { return false; }
    String8 getGLShaderWorkaround(const String16&) { return String8(); }
    String8 getGLHostInfo(const String16&) { return String8(); }
    String8 getGlVendor(const String16&) { return String8(); }
    String8 getGlRenderer(const String16&) { return String8(); }
    String8 getAgaGlVersion(const String16&) { return String8(); }
    String8 getAdditionalGlExtensions(const String16&) { return String8(); }
    String8 getGLExtensionsIgnore(const String16&) { return String8(); }
    String8 getVkHostInfo(const String16&) { return String8(); }
    String8 getVKDeviceExtIgnore(const String16&) { return String8(); }
    int getUnityFlickerPatchRequired(const String16&) { return 0; }
    int getNvidiaThreadedOptVal(const String16&, const char*) { return 0; }
};
} // namespace android
#endif
