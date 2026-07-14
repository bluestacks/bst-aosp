/*
 * Copyright 2022-2023 BlueStack Systems, Inc.
 * All Rights Reserved
 *
 * THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF BLUESTACK SYSTEMS, INC.
 * The copyright notice above does not evidence any actual or intended
 * publication of such source code.
 *
 */

#define LOG_TAG "libnb"
#define LOG_NDEBUG 1

#include <initializer_list>
#include <cstring>
#include <cerrno>
#include <cassert>
#include <dlfcn.h>
#include <unistd.h>
#include <cpuid.h>
#include <fcntl.h>
#include <pthread.h>
#include <elf.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/system_properties.h>
#include <android/log.h>
#include "native_bridge.h"

static const bool g_enable_logv = false;
#define ALOGV_(...) __android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, __VA_ARGS__)
#define ALOGV(...) ((g_enable_logv) && ALOGV_(__VA_ARGS__))
#define ALOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,   LOG_TAG, __VA_ARGS__)
#define ALOGI(...)  __android_log_print(ANDROID_LOG_INFO,    LOG_TAG, __VA_ARGS__)
#define ALOGW(...)  __android_log_print(ANDROID_LOG_WARN,    LOG_TAG, __VA_ARGS__)
#define ALOGE(...)  __android_log_print(ANDROID_LOG_ERROR,   LOG_TAG, __VA_ARGS__)
#define ALOGF(...)  __android_log_print(ANDROID_LOG_FATAL,   LOG_TAG, __VA_ARGS__)

#if 1

#define ATTR_NOINLINE     __attribute__((noinline))
#define ATTR_FORCE_INLINE __attribute__((always_inline))
#define ATTR_UNUSED       __attribute__((unused))
#define ATTR_HIDDEN       __attribute__((visibility("hidden")))
#define ATTR_NAKED        __attribute__((naked))

#define INS_INTEL_SYNTAX ".intel_syntax noprefix  \n\t"
#define INS_ATT_SYNTAX   ".att_syntax             \n\t"
#define ASM(...)         asm(INS_INTEL_SYNTAX __VA_ARGS__ INS_ATT_SYNTAX)

#ifdef __LP64__
    #define ASM_CALL(func)   asm volatile("call %P0 \n\t" : : "i"(func))
    #define ASM_JMP(func)    asm volatile("jmp  %P0 \n\t" : : "i"(func))
#endif

// The maximum size of contiguous executable memory starting from load address of libhoudini.so
// Notice: Houdini also makes read-only data executable.
enum { esize_1301_z = 0x857E58 };

// Quickly get the esize_xxx value of libhoudini.so, it may not work in future.
static inline unsigned get_houdini_esize(const unsigned char* base)
{
    return reinterpret_cast<const unsigned&>(base[sizeof(void*) == 8 ? 0x68 : 0x48]);
}

static inline bool __unused is_intel_cpu()
{
    unsigned eax = 0, ebx = 0, ecx = 0, edx = 0;
    __get_cpuid(0, &eax, &ebx, &ecx, &edx);
    return ebx == 0x756E6547 && ecx == 0x6C65746E && edx == 0x49656E69;
}

static const unsigned char* g_houdini_base  = nullptr;
static unsigned             g_houdini_esize = 0;
// static bool                 g_need_fix_amd_cpu = !is_intel_cpu();

template<typename Func>
static inline Func get_houdini_func(unsigned offset) {
    return reinterpret_cast<Func>(const_cast<unsigned char*>(&g_houdini_base[offset]));
}

template<typename Func>
static inline Func* get_houdini_func(unsigned offset, Func*) {
    return get_houdini_func<Func*>(offset);
}

#if 1  // Patch framework
static inline bool __unused my_memprotect(void* addr, size_t len, int protect)
{
    return syscall(SYS_mprotect, addr, len, protect) == 0;
}

class ATTR_HIDDEN Patcher {
    unsigned char* m_base;

    static inline constexpr unsigned char get_op_call_or_jmp(bool is_jmp)  { return is_jmp ? 0xE9: 0xE8; }
    static inline constexpr bool is_op_call_or_jmp(unsigned char value)    { return (value & ~1) == 0xE8;}

    template<typename Func>
    bool patch(unsigned offset, unsigned size, Func* func, bool is_jmp = false) const {
        if (size < 5) return false;
        const auto dst   = m_base + offset;
        const long delta = reinterpret_cast<unsigned char*>(func) - offset - 5 - m_base;
        if (!can_cast_to_int32(delta)) return false;

        dst[0]  = get_op_call_or_jmp(is_jmp);
        reinterpret_cast<uint32_t&>(dst[1]) = static_cast<uint32_t>(delta);
        memset(&dst[5], 0x90, size - 5);
        return true;
    }

    template<typename Func>
    bool patch_jmp(unsigned offset, unsigned size, Func* func) const {
        return patch(offset, size, func, true);
    }

    bool patch_bytes(unsigned offset, const unsigned char* new_data, unsigned size) const {
        memcpy(&m_base[offset], new_data, size);
        return true;
    }

    template<bool autodetect, typename Func>
    bool patch_call_impl(unsigned offset, unsigned func_offset, Func* func, bool is_jmp = false) const {
        const auto v = m_base[offset];
        const bool matched = autodetect ? is_op_call_or_jmp(v) : v == get_op_call_or_jmp(is_jmp);
        if (!matched) {
            return false;
        }
        auto& value = reinterpret_cast<uint32_t&>(m_base[offset + 1]);
        if (value != func_offset - offset - 5u) return false;
        const long delta = reinterpret_cast<unsigned char*>(func) - offset - 5 - m_base;
        if (!can_cast_to_int32(delta)) {
            return false;
        }
        value = static_cast<uint32_t>(delta);
        return true;
    }

    template<bool autodetect, unsigned M, unsigned N, typename Func>
    unsigned patch_calls_impl(const unsigned (&offsets)[N], unsigned func_offset, Func* func, bool is_jmp = false) const {
        static_assert(M == N, "array size problem");
        unsigned count = 0;
        for (unsigned offset : offsets) {
            count += patch_call_impl<autodetect, Func>(offset, func_offset, func, is_jmp);
        }
        return count;
    }

public:
    Patcher(const unsigned char* base) : m_base(const_cast<unsigned char*>(base)) {}

    static inline constexpr bool can_cast_to_int32(long value) {
        if (sizeof(void*) < 8) return true;
        return value >= INT32_MIN && value <= INT32_MAX;
    }

    template<unsigned bytes, unsigned size, typename Func>
    bool patch(unsigned offset, const unsigned char(&old_data)[size], Func* func, bool is_jmp = false) const {
        static_assert(bytes == size, "array size problem");
        static_assert(size >= 5, "array is too small");
        if (memcmp(&m_base[offset], old_data, size) != 0) {
            return false;
        }
        return patch(offset, size, func, is_jmp);
    }

    template<unsigned bytes, unsigned size, typename Func>
    bool patch_jmp(unsigned offset, const unsigned char(&old_data)[size], Func* func) const {
        return patch<bytes>(offset, old_data, func, true);
    }

    template<unsigned bytes, unsigned size>
    bool patch_bytes(unsigned offset, const unsigned char (&old_data)[size], const unsigned char (&new_data)[size]) const {
        static_assert(bytes == size, "array size problem");
        if (memcmp(&m_base[offset], old_data, size) != 0) {
            return false;
        }
        return patch_bytes(offset, new_data, size);
    }

    template<typename Func>
    bool patch_call(unsigned offset, unsigned func_offset, Func* func, bool is_jmp = false) const {
        return patch_call_impl<false, Func>(offset, func_offset, func, is_jmp);
    }

    template<typename Func>
    bool patch_call_ex(unsigned offset, unsigned func_offset, Func* func) const {
        return patch_call_impl<true, Func>(offset, func_offset, func);
    }

    template<unsigned M, unsigned N, typename Func>
    unsigned patch_calls(const unsigned (&offsets)[N], unsigned func_offset, Func* func, bool is_jmp) const {
        return patch_calls_impl<false, M, N, Func>(offsets, func_offset, func, is_jmp);
    }

    template<unsigned M, unsigned N, typename Func>
    unsigned patch_calls_ex(const unsigned (&offsets)[N], unsigned func_offset, Func* func) const {
        return patch_calls_impl<true, M, N, Func>(offsets, func_offset, func);
    }

    template<typename T>
    bool patch_value(unsigned offset, const T& old_value, const T& new_value) const {
        auto& value = reinterpret_cast<T&>(m_base[offset]);
        if (value != old_value) {
            return false;
        }
        value = new_value;
        return true;
    }

    template<unsigned N, typename T, unsigned M>
    unsigned patch_values(const unsigned (&offsets)[M], const T& old_value, const T& new_value) const {
        static_assert(N == M, "size not equal.");
        unsigned count = 0;
        for (unsigned i = 0; i < M; ++i) {
            const bool succ = patch_value(offsets[i], old_value, new_value);
            count += succ;
        }
        return count;
    }

    template<unsigned N, typename T, unsigned M>
    unsigned patch_all_values(const unsigned (&offsets)[M], const T& old_value, const T& new_value) const {
        static_assert(N == M, "size not equal.");
        for (auto offset : offsets) {
            if (reinterpret_cast<T&>(m_base[offset]) != old_value) {
                return false;
            }
        }
        for (auto offset : offsets)  reinterpret_cast<T&>(m_base[offset]) = new_value;
        return true;
    }
};

template<bool is_rodata = false>
class ATTR_HIDDEN MemProtectHelper {
    unsigned char*  m_base;
    unsigned        m_size;
    bool            m_is_writable = false;

    static constexpr unsigned default_protect = is_rodata ? PROT_READ: (PROT_READ | PROT_EXEC);

public:
    MemProtectHelper(const unsigned char* base, unsigned esize) :
             m_base(const_cast<unsigned char*>(base)), m_size(esize) {}
    MemProtectHelper(const MemProtectHelper&)            = delete;
    MemProtectHelper& operator=(const MemProtectHelper&) = delete;

    bool make_writable() {
        if (!m_is_writable) m_is_writable = my_memprotect(m_base, m_size, default_protect | PROT_WRITE);
        return m_is_writable;
    }

    bool restore() {
        if (m_is_writable && my_memprotect(m_base, m_size,  default_protect)) m_is_writable = false;
        return !m_is_writable;
    }

    ~MemProtectHelper() { restore();}
};

using MemROData = MemProtectHelper<true>;
using MemCode   = MemProtectHelper<false>;
#endif


#if 1 // Package name: The symbol bst_nbpname should be exported in the library libnativebridge.so.

static inline constexpr size_t my_strncpy(char* dst, size_t size, const char* src)
{
    if (size == 0)    return 0;
    const char* const old = dst;
    while (--size != 0 && (*dst = *src) != 0) { ++dst, ++src; }
    if (size == 0)    *dst = 0;
    return dst - old;
}

static inline size_t get_package_name(char* dst, size_t size)
{
    if (size == 0) return 0;
    dst[0] = 0;
    void* handle = dlopen("libnativebridge.so", RTLD_NOLOAD);
    if (handle == nullptr) return 0;

    typedef const char* Func();
    Func* func = reinterpret_cast<Func*>(dlsym(handle, "bst_nbpname"));
    size_t ret = 0;
    if (func) {
        const char* str = func();
        if (str)    ret = my_strncpy(dst, size, str);
    }
    dlclose(handle);
    return ret;
}

class ATTR_HIDDEN StringView {
    const char* m_str;
    size_t      m_len;

    static constexpr bool is_equal(const char* s1, const char* s2, size_t len) {
        return __builtin_memcmp(s1, s2, len) == 0;
    }

public:
    constexpr StringView(const char* str) : m_str(str), m_len(__builtin_strlen(str)) {}
    constexpr StringView(const char* str, size_t len) : m_str(str), m_len(len) {}

    constexpr const char* data() const { return m_str; }
    constexpr size_t      size() const { return m_len; }

    constexpr bool operator==(StringView sv) const { return equals(sv); }
    constexpr bool operator!=(StringView sv) const { return !equals(sv);}

    constexpr bool equals(StringView sv) const {
        return m_len == sv.m_len && is_equal(m_str, sv.m_str, sv.m_len);
    }

    constexpr bool starts_with(StringView sv) const {
        return m_len >= sv.m_len && is_equal(m_str, sv.m_str, sv.m_len);
    }

    constexpr bool ends_with(StringView sv) const {
        return m_len >= sv.m_len && is_equal(&m_str[m_len - sv.m_len], sv.m_str, sv.m_len);
    }

    constexpr StringView skip_prefix(size_t delta) const { return StringView(m_str + delta, m_len - delta);}
};

template<unsigned N = 128>
class ATTR_HIDDEN PackageName {
    char     m_buffer[N] = {};
    uint32_t m_len  = 0;
public:
    PackageName(bool to_init = false)      { if (to_init) init(); }
    constexpr PackageName(const char* str) { my_strncpy(m_buffer, sizeof(m_buffer), str); }

    constexpr auto size() const { return m_len; }
    constexpr auto data() const { return m_buffer; }
    constexpr StringView sv(uint32_t delta = 0) const { return StringView(m_buffer + delta, m_len - delta); }

    void init() {
        if (m_len) return;
        m_len = get_package_name(m_buffer, sizeof(m_buffer));
    }
};
#endif

#ifdef __LP64__  // /proc/pid/maps patch
enum { BST_PROT_ARM_EXEC = 0x10000 };

static inline long make_new_protect(long protect)
{
    return (protect & PROT_EXEC) ? ((protect & ~PROT_EXEC) | BST_PROT_ARM_EXEC) : protect;
}

template<typename T>
struct ATTR_HIDDEN MapsPatchCommon {

    static inline long my_mmap(int syscall_number, void* addr, long len, long prot, long flags, long fd, long off) {
        if (prot & BST_PROT_ARM_EXEC) prot &= ~BST_PROT_ARM_EXEC;

        auto orig_syscall6 = get_houdini_func<decltype(my_mmap)*>(T::offset_syscall_6);
        return orig_syscall6(syscall_number, addr, len, make_new_protect(prot), flags, fd, off);
    }

    static inline long my_arm_mprotect(int syscall_number, void* addr, size_t len, long prot, long pkey) {
        if (prot & BST_PROT_ARM_EXEC) return -EINVAL;
        if (addr == g_houdini_base)   return -EINVAL;

        if (pkey == -1) syscall_number = SYS_mprotect;
        auto orig_syscall4 = get_houdini_func<decltype(my_arm_mprotect)*>(T::offset_syscall_4);
        return orig_syscall4(syscall_number, addr, len, make_new_protect(prot), pkey);
    }

    static inline long my_mprotect(int syscall_number, void* addr, size_t len, long prot) {
        if (prot & BST_PROT_ARM_EXEC) return -EINVAL;

        auto orig_syscall3 = get_houdini_func<decltype(my_mprotect)*>(T::offset_syscall_3);
        return orig_syscall3(syscall_number, addr, len, make_new_protect(prot));
    }
};

struct ATTR_HIDDEN MapsPatch_1301 : MapsPatchCommon<MapsPatch_1301> {
    enum { offset_syscall_3 = 0x4F3FC0, offset_syscall_4 = 0x4F3FD0, offset_syscall_6 = 0x4F3FF0};


    static inline ATTR_FORCE_INLINE void patch_all(Patcher p) {
        // .text:0x317BCF 74 19               jz      loc_317BEA => EB 19  jmp loc_317BEA
        // .text:0x317C10 E8 DB C3 1D 00      call    sub_4F3FF0
        p.patch_call(0x317C10, 0x4F3FF0, my_mmap) && p.patch_value<uint16_t>(0x317BCF, 0x19'74, 0x19'EB);

        // .text:0x318E28 74 18               jz      loc_318E42 => EB 18  jmp loc_318E42
        // .text:0x318E63 E8 88 B1 1D 00      call    sub_4F3FF0
        p.patch_call(0x318E63, 0x4F3FF0, my_mmap) && p.patch_value<uint16_t>(0x318E28, 0x18'74, 0x18'EB);

        // .text:0x317DCD 73 1A               jnb     loc_317DE9 => EB 1A  jmp loc_317DE9
        // .text:0x317DF4 E8 C7 C1 1D 00      call    sub_4F3FC0
        p.patch_call(0x317DF4, 0x4F3FC0, &my_mprotect) && p.patch_value<uint16_t>(0x317DCD, 0x1A'73, 0x1A'EB);

        // .text:0x317EC0 73 20               jnb     loc_317EE2 =>  EB 2A  jmp loc_317EEC
        // .text:0x317EFD E8 CE C0 1D 00      call    sub_4F3FD0
        p.patch_call(0x317EFD, 0x4F3FD0, &my_arm_mprotect) && p.patch_value<uint16_t>(0x317EC0, 0x20'73, 0x2A'EB);

        // .text:0x31B92D 72 64               jb      loc_31B993  -> EB 64  jmp loc_31B993
        // .text:0x31B99F 73 20               jnb     loc_31B9C1  -> EB 2A  jmp loc_31B9CB
        // .text:0x31B9DC E8 EF 85 1D 00      call    sub_4F3FD0
        p.patch_call(0x31B9DC, 0x4F3FD0, &my_arm_mprotect) && p.patch_value<uint16_t>(0x31B99F, 0x20'73, 0x2A'EB) &&
            p.patch_value<uint16_t>(0x31B92D, 0x64'72, 0x64'EB);
    }
};

template<unsigned esize>
static inline void fix_proc_pid_maps(const unsigned char* base)
{
    // Make /proc/pid/maps more similar to the real machine. A kernel patch is also required.
    switch (esize) {
        case esize_1301_z: MapsPatch_1301::patch_all(base); break;
        default: break;
    }
}
#endif


#ifdef __LP64__  // Houdini patch:
template<unsigned esize>
static inline void patch_houdini_1301_z(const unsigned char* base)
{
    MemCode mem(base, esize);
    if (!mem.make_writable()) return;
    fix_proc_pid_maps<esize>(base);
}
#endif

static inline void patch_houdini(const unsigned char* base)
{
    if (base == nullptr) return;
    g_houdini_base = base;
    const unsigned esize = get_houdini_esize(base);
    g_houdini_esize = esize;

    switch (esize) {
#ifdef __LP64__
        case esize_1301_z: patch_houdini_1301_z<esize_1301_z>(base); break;
#else
#endif
        default: break;
    }
}

bool bst_is_ndk_translation_app(void)
{
    const char *path = "/system/lib64/arm64/libtcb.so";

    if (access(path, F_OK) == 0) {
        return false;
    }

    return true;
}

static inline ATTR_FORCE_INLINE android::NativeBridgeCallbacks* my_get_callbacks(void*& native_handle)
{
    if (native_handle) {
        // Should not happen if get_callbacks() is used correctly with its static variable,
        // but as a safeguard, we can return the already found callbacks.
        return reinterpret_cast<android::NativeBridgeCallbacks*>(dlsym(native_handle, "NativeBridgeItf"));
    }

    // Define paths for both potential native bridge libraries.
    const char* lib_ndk = (sizeof(void*) == 8) ? "/system/lib64/libndk_translation.so" : "/system/lib/libndk_translation.so";
    const char* lib_houdini = (sizeof(void*) == 8) ? "/system/lib64/libhoudini.so" : "/system/lib/libhoudini.so";

    const char* preferred_lib = bst_is_ndk_translation_app() ? lib_ndk : lib_houdini;

    ALOGI("Try to open native bridge: %s.", preferred_lib);
    native_handle = dlopen(preferred_lib, RTLD_LAZY);

    if (native_handle == nullptr) {
        ALOGE("Failed to open any native bridge library. Check logs for details.");
        return nullptr;
    }

    auto callbacks = reinterpret_cast<android::NativeBridgeCallbacks*>(dlsym(native_handle, "NativeBridgeItf"));
    ALOGI("Successfully opened '%s' and found NativeBridgeItf version %u", preferred_lib, callbacks ? callbacks->version : 0);
    if (callbacks) {
        Dl_info info;
        if (dladdr(callbacks, &info) && info.dli_fname) {
            if (strstr(info.dli_fname, "houdini") != nullptr) {
                ALOGI("Houdini library detected (%s), applying patches.", info.dli_fname);
                patch_houdini(reinterpret_cast<const unsigned char*>(info.dli_fbase));
            }
        }
    }
    return callbacks;
}
#endif

namespace android {

static void *native_handle = nullptr;

static inline bool is_native_bridge_enabled()
{
    // return property_get_bool("persist.sys.nativebridge", 0);
    return true;
}

static NativeBridgeCallbacks *get_callbacks()
{
    static NativeBridgeCallbacks *callbacks = my_get_callbacks(native_handle);
    return callbacks;
}

// NativeBridgeCallbacks implementations
static bool native_bridge2_initialize(const NativeBridgeRuntimeCallbacks *art_cbs,
                                      const char *app_code_cache_dir,
                                      const char *isa)
{
    ALOGV("enter native_bridge2_initialize %s %s", app_code_cache_dir, isa);
    if (is_native_bridge_enabled()) {
        if (NativeBridgeCallbacks *cb = get_callbacks()) {
            return cb->initialize(art_cbs, app_code_cache_dir, isa);
        }
        ALOGW("Native bridge is enabled but callbacks not found");
    } else {
        ALOGW("Native bridge is disabled");
    }
    return false;
}

static void *native_bridge2_loadLibrary(const char *libpath, int flag)
{
    ALOGV("enter native_bridge2_loadLibrary %s", libpath);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->loadLibrary(libpath, flag) : nullptr;
}

static void *native_bridge2_getTrampoline(void *handle, const char *name,
                                          const char* shorty, uint32_t len)
{
    ALOGV("enter native_bridge2_getTrampoline %s", name);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->getTrampoline(handle, name, shorty, len) : nullptr;
}

static bool native_bridge2_isSupported(const char *libpath)
{
    ALOGV("enter native_bridge2_isSupported %s", libpath);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->isSupported(libpath) : false;
}

static const struct NativeBridgeRuntimeValues *native_bridge2_getAppEnv(const char *abi)
{
    ALOGV("enter native_bridge2_getAppEnv %s", abi);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->getAppEnv(abi) : nullptr;
}

static bool native_bridge2_isCompatibleWith(uint32_t version)
{
    ALOGV("enter native_bridge2_isCompatibleWith %u", version);
    NativeBridgeCallbacks* const cb = native_handle ? get_callbacks() : nullptr;
    const bool ret = cb ? cb->isCompatibleWith(version) : version <= 3;
    return ret;
}

static NativeBridgeSignalHandlerFn native_bridge2_getSignalHandler(int signal)
{
    ALOGV("enter native_bridge2_getSignalHandler %d", signal);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->getSignalHandler(signal) : nullptr;
}

static int native_bridge3_unloadLibrary(void *handle)
{
    ALOGV("enter native_bridge3_unloadLibrary %p", handle);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->unloadLibrary(handle) : -1;
}

static const char *native_bridge3_getError()
{
    ALOGV("enter native_bridge3_getError");
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->getError() : "unknown";
}

static bool native_bridge3_isPathSupported(const char *path)
{
    ALOGV("enter native_bridge3_isPathSupported %s", path);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb && cb->isPathSupported(path);
}

static bool native_bridge3_initAnonymousNamespace(const char *public_ns_sonames,
                                                  const char *anon_ns_library_path)
{
    ALOGV("enter native_bridge3_initAnonymousNamespace %s, %s", public_ns_sonames, anon_ns_library_path);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb && cb->unused_initAnonymousNamespace(public_ns_sonames, anon_ns_library_path);
}

static native_bridge_namespace_t *
native_bridge3_createNamespace(const char *name,
                               const char *ld_library_path,
                               const char *default_library_path,
                               uint64_t type,
                               const char *permitted_when_isolated_path,
                               native_bridge_namespace_t *parent_ns)
{
    ALOGV("enter native_bridge3_createNamespace %s, %s, %s, %s", name, ld_library_path, default_library_path, permitted_when_isolated_path);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->createNamespace(name, ld_library_path, default_library_path, type, permitted_when_isolated_path, parent_ns) : nullptr;
}

static bool native_bridge3_linkNamespaces(native_bridge_namespace_t *from,
                                          native_bridge_namespace_t *to,
                                          const char *shared_libs_soname)
{
    ALOGV("enter native_bridge3_linkNamespaces %s", shared_libs_soname);
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb && cb->linkNamespaces(from, to, shared_libs_soname);
}

static void *native_bridge3_loadLibraryExt(const char *libpath,
                                           int flag,
                                           native_bridge_namespace_t *ns)
{
    ALOGV("enter native_bridge3_loadLibraryExt %s, %d, %p", libpath, flag, ns);
    NativeBridgeCallbacks *cb = get_callbacks();
    void *result = cb ? cb->loadLibraryExt(libpath, flag, ns) : nullptr;
//  void *result = cb ? cb->loadLibrary(libpath, flag) : nullptr;
    ALOGV("native_bridge3_loadLibraryExt: %p", result);
    return result;
}

static native_bridge_namespace_t *native_bridge4_getVendorNamespace()
{
    ALOGV("enter native_bridge4_getVendorNamespace");
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->getVendorNamespace() : nullptr;
}

static native_bridge_namespace_t* native_bridge5_getExportedNamespace(const char* name)
{
    ALOGV("enter native_bridge5_getExportedNamespace");
    NativeBridgeCallbacks *cb = get_callbacks();
    return cb ? cb->getExportedNamespace(name) : nullptr;
}

static void native_bridge6_preZygoteFork()
{
    ALOGV("enter native_bridge6_preZygoteFork");
    NativeBridgeCallbacks *cb = get_callbacks();
    if (cb) cb->preZygoteFork();
}

static void __attribute__ ((destructor)) on_dlclose()
{
    if (native_handle) {
        dlclose(native_handle);
        native_handle = nullptr;
    }
}

extern "C" {

NativeBridgeCallbacks NativeBridgeItf = {
    // v1
    .version = 6,
    .initialize = native_bridge2_initialize,
    .loadLibrary = native_bridge2_loadLibrary,
    .getTrampoline = native_bridge2_getTrampoline,
    .isSupported = native_bridge2_isSupported,
    .getAppEnv = native_bridge2_getAppEnv,
    // v2
    .isCompatibleWith = native_bridge2_isCompatibleWith,
    .getSignalHandler = native_bridge2_getSignalHandler,
    // v3
    .unloadLibrary = native_bridge3_unloadLibrary,
    .getError = native_bridge3_getError,
    .isPathSupported = native_bridge3_isPathSupported,
    .unused_initAnonymousNamespace = native_bridge3_initAnonymousNamespace,
    .createNamespace = native_bridge3_createNamespace,
    .linkNamespaces = native_bridge3_linkNamespaces,
    .loadLibraryExt = native_bridge3_loadLibraryExt,
    // v4
    .getVendorNamespace = native_bridge4_getVendorNamespace,
    // v5
    .getExportedNamespace = native_bridge5_getExportedNamespace,
    // v6
    .preZygoteFork = native_bridge6_preZygoteFork,
};

} // extern "C"
} // namespace android

