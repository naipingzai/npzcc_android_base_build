package com.example.demo

/**
 * JNI接口类 - 用于调用原生C++代码
 */
class NativeLib {
    
    companion object {
        // 加载原生库
        init {
            System.loadLibrary("ndkdemo")
        }
    }
    
    /**
     * 从JNI获取字符串
     */
    external fun helloFromNative(): String

    /**
     * 获取系统信息
     */
    external fun getSystemInfo(): String
}
