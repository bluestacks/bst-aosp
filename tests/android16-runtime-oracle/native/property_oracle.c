#if !defined(__x86_64__)
#error "The runtime property oracle must be compiled for x86_64"
#endif

typedef unsigned char jboolean;
typedef void JNIEnv;
typedef void *jclass;

#define JNI_EXPORT __attribute__((visibility("default")))

extern int __system_property_get(const char *name, char *value);

static int strings_equal(const char *left, const char *right) {
    while (*left != '\0' && *left == *right) {
        ++left;
        ++right;
    }
    return *left == *right;
}

JNI_EXPORT jboolean
Java_com_bluestacks_a16oracle_OracleActivity_hasSyntheticBoardPlatform(
        JNIEnv *env, jclass clazz) {
    char value[92];
    (void)env;
    (void)clazz;
    value[0] = '\0';
    return __system_property_get("ro.board.platform2", value) > 0
            && strings_equal(value, "ngg-client");
}
