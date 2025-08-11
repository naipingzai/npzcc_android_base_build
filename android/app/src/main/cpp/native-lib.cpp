#include <jni.h>
#include <string>
#include <android/log.h>

#define TAG "NativeLib"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_demo_NativeLib_helloFromNative(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    LOGI("helloFromNative called");
    return env->NewStringUTF(hello.c_str());
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_demo_NativeLib_getSystemInfo(
        JNIEnv* env,
        jobject /* this */) {
    std::string info = "NDK Demo - System Info:\n";
    info += "- C++ Standard: C++17\n";
    info += "- Architecture: ";
    
#if defined(__aarch64__)
    info += "ARM64 (aarch64)";
#elif defined(__arm__)
    info += "ARM (32-bit)";
#elif defined(__x86_64__)
    info += "x86_64";
#elif defined(__i386__)
    info += "x86 (32-bit)";
#else
    info += "Unknown";
#endif
    
    LOGI("System info requested");
    return env->NewStringUTF(info.c_str());
}
