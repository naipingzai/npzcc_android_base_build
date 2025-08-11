#!/bin/bash

#===============================================================================
# Android 开发环境安装脚本 (统一 SDK Manager 版本)
# 功能: 使用 cmdline-tools sdkmanager 统一管理 Android 相关工具
# 支持: Android SDK、NDK、CMake、Build Tools、Platform Tools
# 外部工具: Gradle、Java 环境（无法通过 sdkmanager 管理）
# 作者: npz
# 版本: 3.0
#===============================================================================

# 获取脚本的绝对路径和所在目录
readonly SCRIPT_PATH=$(readlink -f "$0")
readonly SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
readonly PROJECT_DIR=$(dirname "$SCRIPT_DIR")
readonly TOOLS_DIR="$PROJECT_DIR/tools"

# 全局变量
INSTALL_SDK=false
INSTALL_GRADLE=false
INSTALL_JAVA=false
INSTALL_NDK=false
INSTALL_CMAKE=false
INSTALL_ALL=false

# SDK 配置
SDK_ROOT=""
CMDLINE_TOOLS_VERSION="9477386"
ANDROID_API_LEVEL="35"
BUILD_TOOLS_VERSION="35.0.0"
NDK_VERSION="26.1.10909125"
CMAKE_VERSION="3.22.1"

#===============================================================================
# 显示帮助信息
#===============================================================================
show_help() {
    print_blue "Android 开发环境安装工具 (统一 SDK Manager 版本)"
    echo
    print_blue "用法:"
    print_blue "  $0 [选项]"
    echo
    print_blue "选项:"
    print_blue "  --sdk            安装 Android SDK (使用 sdkmanager)"
    print_blue "  --gradle         安装 Gradle (外部下载)"
    print_blue "  --java           安装 Java 环境 (外部下载)"
    print_blue "  --ndk            安装 Android NDK (使用 sdkmanager)"
    print_blue "  --cmake          安装 CMake (使用 sdkmanager)"
    print_blue "  --all            安装所有组件"
    print_blue "  -h, --help       显示此帮助信息"
    echo
    print_blue "说明:"
    print_blue "  • SDK、NDK、CMake 统一通过 cmdline-tools sdkmanager 管理"
    print_blue "  • Gradle、Java 因不在 Android SDK 中，需要外部下载"
    print_blue "  • 推荐先安装 Java 和 SDK，再安装其他组件"
    echo
    print_blue "示例:"
    print_blue "  $0 --java --sdk           # 基础开发环境"
    print_blue "  $0 --gradle               # 仅安装 Gradle"
    print_blue "  $0 --ndk --cmake          # NDK 开发环境 (需要先安装 SDK)"
    print_blue "  $0 --all                  # 完整开发环境"
}

#===============================================================================
# 解析命令行参数
#===============================================================================
parse_arguments() {
    # 如果没有参数，显示帮助
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --sdk)
                INSTALL_SDK=true
                shift
                ;;
            --gradle)
                INSTALL_GRADLE=true
                shift
                ;;
            --java)
                INSTALL_JAVA=true
                shift
                ;;
            --ndk)
                INSTALL_NDK=true
                shift
                ;;
            --cmake)
                INSTALL_CMAKE=true
                shift
                ;;
            --all)
                INSTALL_ALL=true
                INSTALL_SDK=true
                INSTALL_GRADLE=true
                INSTALL_JAVA=true
                INSTALL_NDK=true
                INSTALL_CMAKE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_red "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 检查是否至少选择了一个组件
    if [[ "$INSTALL_SDK" = false && "$INSTALL_GRADLE" = false && "$INSTALL_JAVA" = false && "$INSTALL_NDK" = false && "$INSTALL_CMAKE" = false ]]; then
        print_red "错误: 请至少选择一个组件进行安装"
        echo
        show_help
        exit 1
    fi
}

#===============================================================================
# 颜色输出函数
#===============================================================================
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

#===============================================================================
# 初始化 SDK 环境
#===============================================================================
initialize_sdk() {
    SDK_ROOT="$TOOLS_DIR"
    
    # 确保 cmdline-tools 存在
    if [ ! -f "$SDK_ROOT/cmdline-tools/bin/sdkmanager" ]; then
        print_yellow "cmdline-tools 不存在，需要先安装 Android SDK"
        return 1
    fi
    
    print_green "✓ SDK 环境已初始化: $SDK_ROOT"
    return 0
}

#===============================================================================
# 运行 sdkmanager 命令
#===============================================================================
run_sdkmanager() {
    local cmd="$1"
    shift
    local packages=("$@")
    
    if [ ! -f "$SDK_ROOT/cmdline-tools/bin/sdkmanager" ]; then
        print_red "✗ sdkmanager 不可用"
        return 1
    fi
    
    case "$cmd" in
        "install")
            for package in "${packages[@]}"; do
                print_yellow "正在安装: $package"
                # 自动接受许可证并安装包
                yes | "$SDK_ROOT/cmdline-tools/bin/sdkmanager" --sdk_root="$SDK_ROOT" "$package"
            done
            ;;
        "list")
            "$SDK_ROOT/cmdline-tools/bin/sdkmanager" --sdk_root="$SDK_ROOT" --list
            ;;
        "list_installed")
            "$SDK_ROOT/cmdline-tools/bin/sdkmanager" --sdk_root="$SDK_ROOT" --list_installed
            ;;
        "accept_licenses")
            yes | "$SDK_ROOT/cmdline-tools/bin/sdkmanager" --sdk_root="$SDK_ROOT" --licenses >/dev/null 2>&1
            ;;
        *)
            print_red "✗ 未知的 sdkmanager 命令: $cmd"
            return 1
            ;;
    esac
}

#===============================================================================
# Android SDK 安装函数 (cmdline-tools 基础)
#===============================================================================
android_sdk_install() {
    print_header "安装 Android SDK"

    # 切换到 tools 目录
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    print_yellow "正在检查 Android SDK Command Line Tools..."

    # 检查 cmdline-tools 是否已存在
    if [ ! -d "cmdline-tools" ]; then
        print_yellow "正在下载 Android SDK Command Line Tools..."

        # 使用最新版本的 cmdline-tools
        local cmdline_tools_url="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
        local cmdline_tools_zip="cmdline-tools.zip"

        wget "$cmdline_tools_url" -O "$cmdline_tools_zip"

        if [ $? -eq 0 ]; then
            print_yellow "下载完成, 正在解压..."
            unzip -q "$cmdline_tools_zip"
            rm -f "$cmdline_tools_zip"
            
            # 设置执行权限
            chmod +x cmdline-tools/bin/*
            print_green "✓ Command Line Tools 安装完成"
        else
            print_red "✗ Command Line Tools 下载失败"
            return 1
        fi
    else
        print_green "✓ Command Line Tools 已存在"
    fi

    # 初始化 SDK 环境
    if ! initialize_sdk; then
        return 1
    fi

    # 接受许可证
    print_yellow "正在接受 SDK 许可证..."
    run_sdkmanager "accept_licenses"

    # 安装基础 SDK 组件
    print_yellow "正在检查基础 SDK 组件..."
    
    # 检查本地是否已有 SDK 组件
    local missing_components=()
    local existing_components=()
    
    if [ ! -d "platform-tools" ]; then
        missing_components+=("platform-tools")
    else
        existing_components+=("Platform Tools")
    fi
    
    if [ ! -d "platforms" ]; then
        missing_components+=("platforms;android-${ANDROID_API_LEVEL}")
    else
        existing_components+=("Android API ${ANDROID_API_LEVEL}")
    fi
    
    if [ ! -d "build-tools" ]; then
        missing_components+=("build-tools;${BUILD_TOOLS_VERSION}")
    else
        existing_components+=("Build Tools ${BUILD_TOOLS_VERSION}")
    fi
    
    # 显示已存在的组件
    if [ ${#existing_components[@]} -gt 0 ]; then
        print_green "✓ 以下组件已存在:"
        for component in "${existing_components[@]}"; do
            print_green "  - $component"
        done
    fi
    
    # 只安装缺失的组件
    if [ ${#missing_components[@]} -gt 0 ]; then
        print_yellow "正在安装缺失的组件:"
        for component in "${missing_components[@]}"; do
            print_yellow "  - $component"
        done
        run_sdkmanager "install" "${missing_components[@]}"
    else
        print_green "✓ 所有 SDK 组件已存在，跳过下载"
    fi
    
    # 将 SDK 组件从 cmdline-tools 目录移动到 tools 根目录
    print_yellow "正在整理 SDK 目录结构..."
    
    # 移动 platform-tools
    if [ -d "cmdline-tools/platform-tools" ] && [ ! -d "platform-tools" ]; then
        print_yellow "移动 platform-tools 到根目录"
        mv cmdline-tools/platform-tools .
    fi
    
    # 移动 platforms
    if [ -d "cmdline-tools/platforms" ] && [ ! -d "platforms" ]; then
        print_yellow "移动 platforms 到根目录"
        mv cmdline-tools/platforms .
    fi
    
    # 移动 build-tools
    if [ -d "cmdline-tools/build-tools" ] && [ ! -d "build-tools" ]; then
        print_yellow "移动 build-tools 到根目录"
        mv cmdline-tools/build-tools .
    fi
    
    # 移动 licenses
    if [ -d "cmdline-tools/licenses" ] && [ ! -d "licenses" ]; then
        print_yellow "移动 licenses 到根目录"
        mv cmdline-tools/licenses .
    fi

    print_green "✓ Android SDK 检查完成!"
    print_blue "SDK 组件状态:"
    print_blue "  - Platform Tools: $([ -d "platform-tools" ] && echo "已安装" || echo "未安装")"
    print_blue "  - Android API ${ANDROID_API_LEVEL}: $([ -d "platforms" ] && echo "已安装" || echo "未安装")"
    print_blue "  - Build Tools ${BUILD_TOOLS_VERSION}: $([ -d "build-tools" ] && echo "已安装" || echo "未安装")"
    
    return 0
}

#===============================================================================
# Gradle 安装函数 (外部下载 - 无法通过 sdkmanager 管理)
#===============================================================================
gradle_install() {
    print_header "安装 Gradle"

    # 切换到 tools 目录
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    print_yellow "正在检查 Gradle..."
    print_yellow "注释: Gradle 不在 Android SDK 中，需要外部下载"

    # 检查 Gradle 是否已存在
    if [ ! -d "gradle" ]; then
        print_yellow "正在下载 Gradle..."

        local gradle_version="8.5"
        local gradle_zip="gradle-${gradle_version}-bin.zip"
        local gradle_url="https://services.gradle.org/distributions/${gradle_zip}"

        wget "$gradle_url" -O "$gradle_zip"

        if [ $? -eq 0 ]; then
            print_yellow "下载完成, 正在解压..."
            unzip -q "$gradle_zip"

            # 重命名解压后的目录
            if [ -d "gradle-${gradle_version}" ]; then
                mv "gradle-${gradle_version}" gradle
            fi

            rm -f "$gradle_zip"
            chmod +x gradle/bin/gradle
            print_green "✓ Gradle 安装完成!"
        else
            print_red "✗ Gradle 下载失败!"
            return 1
        fi
    else
        print_green "✓ Gradle 已存在"
    fi

    # 验证 Gradle 是否可用
    if [ -f "gradle/bin/gradle" ]; then
        print_green "✓ Gradle 可用: gradle/bin/gradle"
        print_blue "版本信息:"
        gradle/bin/gradle --version | head -n 3
    else
        print_red "✗ Gradle 不可用, 请检查安装"
        return 1
    fi
    
    return 0
}

# 备用 Gradle 下载方法 (注释保留)
# Gradle 官方下载地址:
# https://services.gradle.org/distributions/
# 推荐版本: 8.5, 8.6, 8.7
# 下载命令: wget https://services.gradle.org/distributions/gradle-8.5-bin.zip

#===============================================================================
# Java 环境安装函数 (外部下载 - 无法通过 sdkmanager 管理)
#===============================================================================
java_environment_install() {
    print_header "安装 Java 环境"

    # 切换到 tools 目录
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    print_yellow "正在检查 Java 环境..."
    print_yellow "注释: Java 不在 Android SDK 中，需要外部下载"

    # 检查 Java 是否已存在
    if [ ! -d "java" ]; then
        print_yellow "正在下载 Java 环境..."

        # 使用 Eclipse Temurin OpenJDK 17 (适合 Android 开发)
        local java_version="17.0.9"
        local java_build="9"
        local java_archive="OpenJDK17U-jdk_x64_linux_hotspot_${java_version}_${java_build}.tar.gz"
        local java_url="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${java_version}%2B${java_build}/${java_archive}"

        wget "$java_url" -O "$java_archive"

        if [ $? -eq 0 ]; then
            print_yellow "下载完成, 正在解压..."
            tar -xzf "$java_archive"

            # 查找解压后的 Java 目录并重命名
            local java_extracted_dir
            java_extracted_dir=$(find . -maxdepth 1 -name "jdk-${java_version}*" -type d | head -1)

            if [ -n "$java_extracted_dir" ]; then
                mv "$java_extracted_dir" java
            fi

            rm -f "$java_archive"
            chmod +x java/bin/*
            print_green "✓ Java 环境安装完成!"
        else
            print_red "✗ Java 环境下载失败!"
            return 1
        fi
    else
        print_green "✓ Java 环境已存在"
    fi

    # 验证 Java 是否可用
    if [ -f "java/bin/java" ]; then
        print_green "✓ Java 可用: java/bin/java"
        print_blue "版本信息:"
        java/bin/java -version 2>&1 | head -n 3
    else
        print_red "✗ Java 不可用, 请检查安装"
        return 1
    fi
    
    return 0
}

# 备用 Java 下载方法 (注释保留)
# OpenJDK 官方下载地址:
# https://adoptium.net/temurin/releases/
# Eclipse Temurin (推荐): https://github.com/adoptium/temurin17-binaries/releases
# Oracle JDK: https://www.oracle.com/java/technologies/downloads/
# 推荐版本: JDK 17 (LTS), JDK 11 (LTS)

#===============================================================================
# Android NDK 安装函数 (使用 sdkmanager)
#===============================================================================
android_ndk_install() {
    print_header "安装 Android NDK"

    # 切换到 tools 目录
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    # 检查 SDK 是否已安装
    if ! initialize_sdk; then
        print_red "✗ 请先安装 Android SDK (--sdk)"
        return 1
    fi

    print_yellow "正在检查 Android NDK..."

    # 首先检查本地是否已有 NDK 目录
    if [ -d "ndk" ]; then
        print_green "✓ Android NDK 已存在于本地目录"
        print_blue "NDK 版本: ${NDK_VERSION}"
        return 0
    fi

    # 检查 NDK 是否已通过 sdkmanager 安装
    local ndk_package="ndk;${NDK_VERSION}"
    if run_sdkmanager "list_installed" | grep -q "$ndk_package"; then
        print_green "✓ Android NDK 已通过 sdkmanager 安装"
    else
        print_yellow "正在通过 sdkmanager 安装 NDK..."
        run_sdkmanager "install" "$ndk_package"
        
        if [ $? -eq 0 ]; then
            print_green "✓ Android NDK 安装完成!"
        else
            print_red "✗ NDK 安装失败"
            return 1
        fi
    fi

    # 将 NDK 从 cmdline-tools 目录移动到 tools 根目录
    print_yellow "正在整理 NDK 目录结构..."
    
    # 首先检查 cmdline-tools 下是否有 ndk 目录
    if [ -d "cmdline-tools/ndk" ] && [ ! -d "ndk" ]; then
        print_yellow "移动 NDK 目录到根目录"
        mv cmdline-tools/ndk .
    fi
    
    # 检查是否有版本化的 NDK 目录需要处理
    if [ -d "cmdline-tools/ndk/${NDK_VERSION}" ] && [ ! -d "ndk" ]; then
        print_yellow "处理版本化的 NDK 目录"
        mkdir -p ndk
        mv "cmdline-tools/ndk/${NDK_VERSION}"/* ndk/
        rm -rf "cmdline-tools/ndk"
    fi

    print_blue "NDK 版本: ${NDK_VERSION}"
    
    # 提示原始下载方法 (保留作为注释)
    print_yellow "注释: 原始 NDK 下载方法已保留在脚本中作为备用"
    
    return 0
}

# 备用 NDK 下载方法 (注释保留)
# 如果 sdkmanager 安装失败，可以使用以下方法手动下载:
#
# android_ndk_install_manual() {
#     local ndk_version="26.1.10909125"
#     local ndk_archive="android-ndk-r26b-linux.zip"
#     local ndk_url="https://dl.google.com/android/repository/${ndk_archive}"
#     
#     wget "$ndk_url" -O "$ndk_archive"
#     unzip -q "$ndk_archive"
#     mv android-ndk-r* ndk
#     rm -f "$ndk_archive"
#     chmod +x ndk/ndk-build
# }

#===============================================================================
# CMake 安装函数 (使用 sdkmanager)
#===============================================================================
cmake_install() {
    print_header "安装 CMake"

    # 切换到 tools 目录
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    # 检查 SDK 是否已安装
    if ! initialize_sdk; then
        print_red "✗ 请先安装 Android SDK (--sdk)"
        return 1
    fi

    print_yellow "正在检查 CMake..."

    # 首先检查本地是否已有 CMake 目录
    if [ -d "cmake" ]; then
        print_green "✓ CMake 已存在于本地目录"
        print_blue "CMake 版本: ${CMAKE_VERSION}"
        return 0
    fi

    # 检查 CMake 是否已通过 sdkmanager 安装
    local cmake_package="cmake;${CMAKE_VERSION}"
    if run_sdkmanager "list_installed" | grep -q "$cmake_package"; then
        print_green "✓ CMake 已通过 sdkmanager 安装"
    else
        print_yellow "正在通过 sdkmanager 安装 CMake..."
        run_sdkmanager "install" "$cmake_package"
        
        if [ $? -eq 0 ]; then
            print_green "✓ CMake 安装完成!"
        else
            print_red "✗ CMake 安装失败"
            return 1
        fi
    fi

    # 将 CMake 从 cmdline-tools 目录移动到 tools 根目录
    print_yellow "正在整理 CMake 目录结构..."
    
    # 首先检查 cmdline-tools 下是否有 cmake 目录
    if [ -d "cmdline-tools/cmake" ] && [ ! -d "cmake" ]; then
        print_yellow "移动 CMake 目录到根目录"
        mv cmdline-tools/cmake .
    fi
    
    # 检查是否有版本化的 CMake 目录需要处理
    if [ -d "cmdline-tools/cmake/${CMAKE_VERSION}" ] && [ ! -d "cmake" ]; then
        print_yellow "处理版本化的 CMake 目录"
        mkdir -p cmake
        mv "cmdline-tools/cmake/${CMAKE_VERSION}"/* cmake/
        rm -rf "cmdline-tools/cmake"
    fi

    print_blue "CMake 版本: ${CMAKE_VERSION}"
    
    # 提示原始下载方法 (保留作为注释)
    print_yellow "注释: 原始 CMake 下载方法已保留在脚本中作为备用"
    
    return 0
}

# 备用 CMake 下载方法 (注释保留)
# 如果 sdkmanager 安装失败，可以使用以下方法手动下载:
#
# cmake_install_manual() {
#     local cmake_version="3.22.1"
#     local cmake_archive="cmake-${cmake_version}-linux-x86_64.tar.gz"
#     local cmake_url="https://github.com/Kitware/CMake/releases/download/v${cmake_version}/${cmake_archive}"
#     
#     wget "$cmake_url" -O "$cmake_archive"
#     tar -xzf "$cmake_archive"
#     mv cmake-${cmake_version}-* cmake
#     rm -f "$cmake_archive"
#     chmod +x cmake/bin/*
# }

#===============================================================================
# 主执行部分
#===============================================================================
main() {
    # 解析命令行参数
    parse_arguments "$@"

    print_header "Android 开发环境安装工具"

    print_blue "脚本信息:"
    print_blue "  脚本目录: $SCRIPT_DIR"
    print_blue "  工程路径: $PROJECT_DIR"
    print_blue "  工具路径: $TOOLS_DIR"
    echo
    print_blue "安装计划:"
    print_blue "  Android SDK: $([ "$INSTALL_SDK" = true ] && echo "是 (使用 sdkmanager)" || echo "否")"
    print_blue "  Gradle: $([ "$INSTALL_GRADLE" = true ] && echo "是 (外部下载)" || echo "否")"
    print_blue "  Java 环境: $([ "$INSTALL_JAVA" = true ] && echo "是 (外部下载)" || echo "否")"
    print_blue "  Android NDK: $([ "$INSTALL_NDK" = true ] && echo "是 (使用 sdkmanager)" || echo "否")"
    print_blue "  CMake: $([ "$INSTALL_CMAKE" = true ] && echo "是 (使用 sdkmanager)" || echo "否")"
    echo
    print_blue "SDK 配置:"
    print_blue "  Android API Level: ${ANDROID_API_LEVEL}"
    print_blue "  Build Tools Version: ${BUILD_TOOLS_VERSION}"
    print_blue "  NDK Version: ${NDK_VERSION}"
    print_blue "  CMake Version: ${CMAKE_VERSION}"
    echo

    # 创建 tools 目录 (如果不存在)
    if [ ! -d "$TOOLS_DIR" ]; then
        print_yellow "创建工具目录: $TOOLS_DIR"
        mkdir -p "$TOOLS_DIR"
    fi

    # 切换到 tools 目录
    print_yellow "切换到工具目录: $TOOLS_DIR"
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        exit 1
    }

    # 开始安装各个组件
    local install_success=0
    local install_total=0

    # 计算总安装数
    [ "$INSTALL_SDK" = true ] && ((install_total++))
    [ "$INSTALL_GRADLE" = true ] && ((install_total++))
    [ "$INSTALL_JAVA" = true ] && ((install_total++))
    [ "$INSTALL_NDK" = true ] && ((install_total++))
    [ "$INSTALL_CMAKE" = true ] && ((install_total++))

    # 安装 Android SDK (如果指定)
    if [ "$INSTALL_SDK" = true ]; then
        if android_sdk_install; then
            ((install_success++))
        fi
        echo
    fi

    # 安装 Gradle (如果指定)
    if [ "$INSTALL_GRADLE" = true ]; then
        if gradle_install; then
            ((install_success++))
        fi
        echo
    fi

    # 安装 Java 环境 (如果指定)
    if [ "$INSTALL_JAVA" = true ]; then
        if java_environment_install; then
            ((install_success++))
        fi
        echo
    fi

    # 安装 NDK (如果指定)
    if [ "$INSTALL_NDK" = true ]; then
        if android_ndk_install; then
            ((install_success++))
        fi
        echo
    fi

    # 安装 CMake (如果指定)
    if [ "$INSTALL_CMAKE" = true ]; then
        if cmake_install; then
            ((install_success++))
        fi
        echo
    fi

    # 显示安装结果
    print_header "安装完成"
    if [ $install_success -eq $install_total ]; then
        print_green "✓ 所有选定组件安装成功 ($install_success/$install_total)"
        print_blue "Android 开发环境已准备就绪!"
        
        # 显示环境变量设置建议
        if [ $install_total -gt 0 ]; then
            echo
            print_header "环境变量设置建议"
            print_blue "请将以下环境变量添加到您的 ~/.bashrc 或 ~/.zshrc 文件中:"
            echo
            
            if [ "$INSTALL_JAVA" = true ]; then
                print_yellow "export JAVA_HOME=$TOOLS_DIR/java"
            fi
            if [ "$INSTALL_SDK" = true ]; then
                print_yellow "export ANDROID_HOME=$TOOLS_DIR"
                print_yellow "export ANDROID_SDK_ROOT=$TOOLS_DIR"
            fi
            if [ "$INSTALL_GRADLE" = true ]; then
                print_yellow "export GRADLE_HOME=$TOOLS_DIR/gradle"
            fi
            if [ "$INSTALL_NDK" = true ]; then
                print_yellow "export ANDROID_NDK_HOME=$TOOLS_DIR/ndk"
            fi
            if [ "$INSTALL_CMAKE" = true ]; then
                print_yellow "export CMAKE_HOME=$TOOLS_DIR/cmake"
            fi
            
            # 构建 PATH 变量
            local path_additions=""
            if [ "$INSTALL_JAVA" = true ]; then
                path_additions=":\$JAVA_HOME/bin"
            fi
            if [ "$INSTALL_SDK" = true ]; then
                path_additions="$path_additions:\$ANDROID_HOME/cmdline-tools/bin:\$ANDROID_HOME/platform-tools"
            fi
            if [ "$INSTALL_GRADLE" = true ]; then
                path_additions="$path_additions:\$GRADLE_HOME/bin"
            fi
            if [ "$INSTALL_NDK" = true ]; then
                path_additions="$path_additions:\$ANDROID_NDK_HOME"
            fi
            if [ "$INSTALL_CMAKE" = true ]; then
                path_additions="$path_additions:\$CMAKE_HOME/bin"
            fi
            
            if [ -n "$path_additions" ]; then
                print_yellow "export PATH=\$PATH$path_additions"
            fi
            
            echo
            print_blue "SDK Manager 使用说明:"
            print_blue "  查看可用包: sdkmanager --list"
            print_blue "  安装包: sdkmanager \"package-name\""
            print_blue "  查看已安装: sdkmanager --list_installed"
        fi
    else
        print_yellow "⚠ 部分组件安装失败 ($install_success/$install_total)"
        print_yellow "请检查错误信息并重新运行脚本"
    fi
}

# 执行主函数
main "$@"
