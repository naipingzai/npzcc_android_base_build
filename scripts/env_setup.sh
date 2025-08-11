#!/bin/bash

#===============================================================================
# Android 开发环境变量设置脚本
# 用法: source scripts/env_setup.sh 或 . scripts/env_setup.sh
# 功能: 设置 Android 开发所需的环境变量 (包含 NDK 和 CMake)
# 作者: npz
# 版本: 1.2
#===============================================================================

# 颜色输出函数
print_blue() {
    echo -e "\033[0;36m$1\033[0m"
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

# 读取版本配置信息
load_version_config() {
    local config_file="$TOOLS_DIR/.version_config"
    if [ -f "$config_file" ]; then
        source "$config_file"
        print_blue "📋 读取版本配置文件: $config_file"
        print_blue "  安装模式: $INSTALL_MODE"
        print_blue "  安装时间: $INSTALL_DATE"
        return 0
    else
        print_red "❌ 未找到版本配置文件: $config_file"
        print_yellow "请先运行 tools_install.sh 安装开发工具"
        return 1
    fi
}

# 加载版本配置
if ! load_version_config; then
    return 1
fi

# 设置环境变量标志
ENV_VARS_SET=0

#===============================================================================
# 设置 Java 环境变量
#===============================================================================
if [ "$JAVA_INSTALLED" = "true" ] && [ -n "$INSTALLED_JAVA_PATH" ] && [ -d "$INSTALLED_JAVA_PATH" ]; then
    export JAVA_HOME="$INSTALLED_JAVA_PATH"
    export PATH="$JAVA_HOME/bin:$PATH"
    print_green "✓ JAVA_HOME 设置为: $JAVA_HOME"
    print_blue "  版本: $INSTALLED_JAVA_VERSION"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Java 环境未安装或路径无效"
fi

#===============================================================================
# 设置 Android SDK 环境变量
#===============================================================================
if [ "$SDK_INSTALLED" = "true" ] && [ -n "$INSTALLED_SDK_PATH" ] && [ -d "$INSTALLED_SDK_PATH" ]; then
    # Android SDK 根目录
    export ANDROID_HOME="$INSTALLED_SDK_PATH"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"

    # 添加 cmdline-tools 到 PATH
    if [ -n "$INSTALLED_CMDLINE_TOOLS_PATH" ] && [ -d "$INSTALLED_CMDLINE_TOOLS_PATH/bin" ]; then
        export PATH="$INSTALLED_CMDLINE_TOOLS_PATH/bin:$PATH"
    fi

    # 添加 platform-tools 到 PATH
    if [ -d "$ANDROID_HOME/platform-tools" ]; then
        export PATH="$ANDROID_HOME/platform-tools:$PATH"
    fi

    # 添加 build-tools 到 PATH
    if [ -n "$INSTALLED_BUILD_TOOLS_VERSION" ] && [ -d "$ANDROID_HOME/build-tools/$INSTALLED_BUILD_TOOLS_VERSION" ]; then
        export PATH="$ANDROID_HOME/build-tools/$INSTALLED_BUILD_TOOLS_VERSION:$PATH"
        print_green "✓ Android Build Tools ($INSTALLED_BUILD_TOOLS_VERSION) 已添加到 PATH"
    fi

    print_green "✓ ANDROID_HOME 设置为: $ANDROID_HOME"
    print_green "✓ ANDROID_SDK_ROOT 设置为: $ANDROID_SDK_ROOT"
    print_blue "  SDK Tools 版本: $INSTALLED_CMDLINE_TOOLS_VERSION"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Android SDK 未安装或路径无效"
fi

#===============================================================================
# 设置 Gradle 环境变量
#===============================================================================
if [ "$GRADLE_INSTALLED" = "true" ] && [ -n "$INSTALLED_GRADLE_PATH" ] && [ -d "$INSTALLED_GRADLE_PATH" ]; then
    export GRADLE_HOME="$INSTALLED_GRADLE_PATH"
    export PATH="$GRADLE_HOME/bin:$PATH"
    print_green "✓ GRADLE_HOME 设置为: $GRADLE_HOME"
    print_blue "  版本: $INSTALLED_GRADLE_VERSION"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Gradle 未安装或路径无效"
fi

#===============================================================================
# 设置 Android NDK 环境变量 (仅用于IDE支持和命令行工具)
# 注意: 现代Gradle不再使用ANDROID_NDK_HOME，而是通过build.gradle的ndkVersion自动管理
#===============================================================================
if [ "$NDK_INSTALLED" = "true" ] && [ -n "$INSTALLED_NDK_PATH" ] && [ -d "$INSTALLED_NDK_PATH" ]; then
    export ANDROID_NDK_HOME="$INSTALLED_NDK_PATH"
    export NDK_HOME="$ANDROID_NDK_HOME"
    export PATH="$ANDROID_NDK_HOME:$PATH"
    print_green "✓ ANDROID_NDK_HOME 设置为: $ANDROID_NDK_HOME"
    print_blue "  版本: $INSTALLED_NDK_VERSION ($INSTALLED_NDK_INTERNAL_VERSION)"
    print_blue "  用途: IDE支持和命令行工具 (Gradle会自动找到NDK)"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ Android NDK 未安装"
    print_blue "  注意: 现代Android开发推荐在build.gradle中指定ndkVersion"
    print_blue "  Gradle会自动下载和管理NDK，无需手动设置环境变量"
    print_blue "  环境变量主要用于IDE支持和直接使用ndk-build等命令行工具"
fi

#===============================================================================
# 设置 CMake 环境变量
#===============================================================================
if [ "$CMAKE_INSTALLED" = "true" ] && [ -n "$INSTALLED_CMAKE_PATH" ] && [ -d "$INSTALLED_CMAKE_PATH" ]; then
    export CMAKE_HOME="$INSTALLED_CMAKE_PATH"
    export PATH="$CMAKE_HOME/bin:$PATH"
    print_green "✓ CMAKE_HOME 设置为: $CMAKE_HOME"
    print_blue "  版本: $INSTALLED_CMAKE_VERSION"
    ((ENV_VARS_SET++))
else
    print_yellow "⚠ CMake 未安装或路径无效"
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
    if [ "$JAVA_INSTALLED" = "true" ] && command -v java >/dev/null 2>&1; then
        JAVA_VERSION_RUNTIME=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        print_green "  Java: $JAVA_VERSION_RUNTIME (配置版本: $INSTALLED_JAVA_VERSION)"
    fi

    # 验证 Android 工具
    if [ "$SDK_INSTALLED" = "true" ] && command -v adb >/dev/null 2>&1; then
        ADB_VERSION=$(adb version | head -n 1)
        print_green "  ADB: $ADB_VERSION"
    fi

    # 验证 Gradle
    if [ "$GRADLE_INSTALLED" = "true" ] && command -v gradle >/dev/null 2>&1; then
        GRADLE_VERSION_RUNTIME=$(gradle --version | grep "Gradle" | head -n 1)
        print_green "  $GRADLE_VERSION_RUNTIME (配置版本: $INSTALLED_GRADLE_VERSION)"
    fi

    # 验证 NDK
    if [ "$NDK_INSTALLED" = "true" ] && command -v ndk-build >/dev/null 2>&1; then
        print_green "  NDK: ndk-build 可用 (配置版本: $INSTALLED_NDK_VERSION)"
        # 显示 NDK 版本
        if [ -f "$ANDROID_NDK_HOME/source.properties" ]; then
            NDK_VERSION_ACTUAL=$(grep "Pkg.Revision" "$ANDROID_NDK_HOME/source.properties" | cut -d'=' -f2 | sed 's/^[ \t]*//')
            print_green "  NDK Version: $NDK_VERSION_ACTUAL"
        fi
    fi

    # 验证 CMake
    if [ "$CMAKE_INSTALLED" = "true" ] && command -v cmake >/dev/null 2>&1; then
        CMAKE_VERSION_RUNTIME=$(cmake --version | head -n 1)
        print_green "  $CMAKE_VERSION_RUNTIME (配置版本: $INSTALLED_CMAKE_VERSION)"
    fi

    echo
    print_blue "提示: 如需永久设置, 请将以下内容添加到 ~/.bashrc 或 ~/.profile:"
    print_yellow "source $(realpath "$SCRIPT_PATH")"

else
    print_yellow "⚠ 未设置任何环境变量"
    print_yellow "请先运行 tools_install.sh 安装开发工具"
fi
