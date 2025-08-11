#!/bin/bash

#===============================================================================
# Android 开发环境变量设置脚本
# 用法: source scripts/env_setup.sh 或 . scripts/env_setup.sh
# 功能: 设置 Android 开发所需的环境变量 (包含 NDK 和 CMake)
# 作者: npz
# 版本: 3.0
#===============================================================================

# 颜色输出函数
print_blue() {
    echo -e "\033[0;34m$1\033[0m"
}

print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_yellow() {
    echo -e "\033[1;33m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

print_header() {
    echo -e "\033[1;36m==== $1 ====\033[0m"
}

# 获取脚本路径
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # 脚本被 source
    if [ -z "$SCRIPT_PATH" ]; then
        readonly SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
    fi
else
    # 脚本被直接执行
    print_red "错误: 此脚本需要使用 source 命令执行"
    print_yellow "正确用法: source scripts/env_setup.sh"
    print_yellow "或者:    . scripts/env_setup.sh"
    exit 1
fi

if [ -z "$SCRIPT_DIR" ]; then
    readonly SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
fi
if [ -z "$PROJECT_DIR" ]; then
    readonly PROJECT_DIR=$(dirname "$SCRIPT_DIR")
fi
if [ -z "$TOOLS_DIR" ]; then
    readonly TOOLS_DIR="$PROJECT_DIR/tools"
fi

print_header "设置 Android 开发环境变量"

# 检查 tools 目录是否存在
if [ ! -d "$TOOLS_DIR" ]; then
    print_red "错误: tools 目录不存在: $TOOLS_DIR"
    print_yellow "请先运行 tools_install.sh 安装开发工具"
    return 1
fi

print_blue "工具目录: $TOOLS_DIR"

# 设置环境变量标志
ENV_VARS_SET=0

#===============================================================================
# 设置 Java 环境变量
#===============================================================================
if [ -d "$TOOLS_DIR/java" ] && [ -f "$TOOLS_DIR/java/bin/java" ]; then
    export JAVA_HOME="$TOOLS_DIR/java"
    export PATH="$JAVA_HOME/bin:$PATH"
    print_green "✓ JAVA_HOME 设置为: $JAVA_HOME"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Java 环境未找到, 跳过 JAVA_HOME 设置"
    print_yellow "  请先运行: scripts/tools_install.sh --java"
fi

#===============================================================================
# 设置 Android SDK 环境变量
#===============================================================================
if [ -d "$TOOLS_DIR/cmdline-tools" ]; then
    # Android SDK 根目录设置为 tools 目录
    export ANDROID_HOME="$TOOLS_DIR"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"

    # 添加 cmdline-tools 到 PATH
    if [ -d "$TOOLS_DIR/cmdline-tools/bin" ]; then
        export PATH="$TOOLS_DIR/cmdline-tools/bin:$PATH"
        print_green "✓ cmdline-tools 已添加到 PATH"
    fi

    # 添加 platform-tools 到 PATH (在 tools 根目录下)
    if [ -d "$TOOLS_DIR/platform-tools" ]; then
        export PATH="$TOOLS_DIR/platform-tools:$PATH"
        print_green "✓ platform-tools 已添加到 PATH"
    fi

    # 添加 build-tools 到 PATH (在 tools 根目录下)
    if [ -d "$TOOLS_DIR/build-tools" ]; then
        # 找到最新的 build-tools 版本
        BUILD_TOOLS_VERSION=$(ls "$TOOLS_DIR/build-tools" | sort -V | tail -n 1)
        if [ -n "$BUILD_TOOLS_VERSION" ]; then
            export PATH="$TOOLS_DIR/build-tools/$BUILD_TOOLS_VERSION:$PATH"
            print_green "✓ Android Build Tools ($BUILD_TOOLS_VERSION) 已添加到 PATH"
        fi
    fi

    print_green "✓ ANDROID_HOME 设置为: $ANDROID_HOME"
    print_green "✓ ANDROID_SDK_ROOT 设置为: $ANDROID_SDK_ROOT"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Android SDK 未找到, 跳过 Android 环境变量设置"
    print_yellow "  请先运行: scripts/tools_install.sh --sdk"
fi

#===============================================================================
# 设置 Gradle 环境变量
#===============================================================================
if [ -d "$TOOLS_DIR/gradle" ] && [ -f "$TOOLS_DIR/gradle/bin/gradle" ]; then
    export GRADLE_HOME="$TOOLS_DIR/gradle"
    export PATH="$GRADLE_HOME/bin:$PATH"
    print_green "✓ GRADLE_HOME 设置为: $GRADLE_HOME"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Gradle 未找到, 跳过 GRADLE_HOME 设置"
    print_yellow "  请先运行: scripts/tools_install.sh --gradle"
fi

#===============================================================================
# 设置 Android NDK 环境变量
#===============================================================================
if [ -d "$TOOLS_DIR/ndk" ]; then
    # 查找 NDK 可执行文件 (可能在版本化子目录中)
    NDK_BUILD_PATH=""
    if [ -f "$TOOLS_DIR/ndk/ndk-build" ]; then
        NDK_BUILD_PATH="$TOOLS_DIR/ndk"
    else
        # 查找版本化目录中的 ndk-build
        for ndk_version_dir in "$TOOLS_DIR/ndk"/*; do
            if [ -f "$ndk_version_dir/ndk-build" ]; then
                NDK_BUILD_PATH="$ndk_version_dir"
                break
            fi
        done
    fi
    
    if [ -n "$NDK_BUILD_PATH" ]; then
        export ANDROID_NDK_HOME="$NDK_BUILD_PATH"
        export NDK_HOME="$ANDROID_NDK_HOME"
        export PATH="$ANDROID_NDK_HOME:$PATH"
        print_green "✓ ANDROID_NDK_HOME 设置为: $ANDROID_NDK_HOME"
        print_green "✓ NDK_HOME 设置为: $NDK_HOME"
        ((ENV_VARS_SET++))
    else
        print_yellow "⚠ NDK 目录存在但 ndk-build 未找到"
    fi
else
    print_yellow "⚠ Android NDK 未找到, 跳过 NDK 环境变量设置"
    print_yellow "  请先运行: scripts/tools_install.sh --ndk"
fi

#===============================================================================
# 设置 CMake 环境变量
#===============================================================================
if [ -d "$TOOLS_DIR/cmake" ]; then
    # 查找 CMake 可执行文件 (可能在版本化子目录中)
    CMAKE_BIN_PATH=""
    if [ -f "$TOOLS_DIR/cmake/bin/cmake" ]; then
        CMAKE_BIN_PATH="$TOOLS_DIR/cmake"
    else
        # 查找版本化目录中的 cmake
        for cmake_version_dir in "$TOOLS_DIR/cmake"/*; do
            if [ -f "$cmake_version_dir/bin/cmake" ]; then
                CMAKE_BIN_PATH="$cmake_version_dir"
                break
            fi
        done
    fi
    
    if [ -n "$CMAKE_BIN_PATH" ]; then
        export CMAKE_HOME="$CMAKE_BIN_PATH"
        export PATH="$CMAKE_HOME/bin:$PATH"
        print_green "✓ CMAKE_HOME 设置为: $CMAKE_HOME"
        ((ENV_VARS_SET++))
    else
        print_yellow "⚠ CMake 目录存在但 cmake 可执行文件未找到"
    fi
else
    print_yellow "⚠ CMake 未找到, 跳过 CMAKE_HOME 设置"
    print_yellow "  请先运行: scripts/tools_install.sh --cmake"
fi

#===============================================================================
# 显示设置结果
#===============================================================================
echo
print_header "环境变量设置完成"

if [ $ENV_VARS_SET -gt 0 ]; then
    print_green "✓ 成功设置 $ENV_VARS_SET 个环境变量"

    echo
    print_blue "当前环境变量:"
    [ -n "$JAVA_HOME" ] && print_blue "  JAVA_HOME = $JAVA_HOME"
    [ -n "$ANDROID_HOME" ] && print_blue "  ANDROID_HOME = $ANDROID_HOME"
    [ -n "$ANDROID_SDK_ROOT" ] && print_blue "  ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT"
    [ -n "$GRADLE_HOME" ] && print_blue "  GRADLE_HOME = $GRADLE_HOME"
    [ -n "$ANDROID_NDK_HOME" ] && print_blue "  ANDROID_NDK_HOME = $ANDROID_NDK_HOME"
    [ -n "$NDK_HOME" ] && print_blue "  NDK_HOME = $NDK_HOME"
    [ -n "$CMAKE_HOME" ] && print_blue "  CMAKE_HOME = $CMAKE_HOME"

    echo
    print_blue "验证工具版本:"

    # 验证 Java
    if command -v java >/dev/null 2>&1; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        print_green "  Java: $JAVA_VERSION"
    fi

    # 验证 Android 工具
    if command -v adb >/dev/null 2>&1; then
        ADB_VERSION=$(adb version | head -n 1)
        print_green "  ADB: $ADB_VERSION"
    fi

    # 验证 Gradle
    if command -v gradle >/dev/null 2>&1; then
        GRADLE_VERSION=$(gradle --version | grep "Gradle" | head -n 1)
        print_green "  $GRADLE_VERSION"
    fi

    # 验证 NDK
    if command -v ndk-build >/dev/null 2>&1; then
        print_green "  NDK: ndk-build 可用"
        # 显示 NDK 版本
        if [ -f "$ANDROID_NDK_HOME/source.properties" ]; then
            NDK_VERSION=$(grep "Pkg.Revision" "$ANDROID_NDK_HOME/source.properties" | cut -d'=' -f2 | sed 's/^[ \t]*//')
            print_green "  NDK Version: $NDK_VERSION"
        fi
    fi

    # 验证 CMake
    if command -v cmake >/dev/null 2>&1; then
        CMAKE_VERSION=$(cmake --version | head -n 1)
        print_green "  $CMAKE_VERSION"
    fi

    echo
    print_blue "提示: 如需永久设置, 请将以下内容添加到 ~/.bashrc 或 ~/.profile:"
    print_yellow "source $(realpath "$SCRIPT_PATH")"

else
    print_yellow "⚠ 未设置任何环境变量"
    print_yellow "请先运行 scripts/tools_install.sh 安装开发工具"
    print_blue "示例:"
    print_blue "  scripts/tools_install.sh --all     # 安装所有工具"
    print_blue "  scripts/tools_install.sh --java --sdk  # 安装基础工具"
fi
