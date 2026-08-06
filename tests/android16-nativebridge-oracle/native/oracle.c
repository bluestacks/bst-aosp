#if !defined(__aarch64__)
#error "The native-bridge oracle must be compiled for AArch64"
#endif

typedef int jint;
typedef long long jlong;
typedef void JNIEnv;
typedef void *jclass;

#define JNI_EXPORT __attribute__((visibility("default")))

JNI_EXPORT jint
Java_com_bluestacks_a16nativeoracle_OracleActivity_regularProbe(
        JNIEnv *env, jclass clazz) {
    (void)env;
    (void)clazz;
    return 0x16a64001;
}

JNI_EXPORT jlong
Java_com_bluestacks_a16nativeoracle_OracleActivity_fastProbe(
        JNIEnv *env, jclass clazz, jlong value) {
    (void)env;
    (void)clazz;
    return value ^ 0x55aa55aa55aa55aaLL;
}

JNI_EXPORT jint
Java_com_bluestacks_a16nativeoracle_OracleActivity_criticalProbe(
        jint left, jint right) {
    return left + right;
}
