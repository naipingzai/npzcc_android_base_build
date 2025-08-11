#!/bin/bash

#===============================================================================
# Android 开发环境安装脚本
# 功能: 可选择性安装 Android SDK、Gradle、Java 环境、NDK
# 作者: npz
# 版本: 2.0
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
INSTALL_ALL=false

#===============================================================================
# 显示帮助信息
#===============================================================================
show_help() {
    print_blue "Android 开发环境安装工具"
    echo
    print_blue "用法:"
    print_blue "  $0 [选项]"
    echo
    print_blue "选项:"
    print_blue "  --sdk            安装 Android SDK"
    print_blue "  --gradle         安装 Gradle"
    print_blue "  --java           安装 Java 环境"
    print_blue "  --ndk            安装 Android NDK"
    print_blue "  --all            安装所有组件"
    print_blue "  -h, --help       显示此帮助信息"
    echo
    print_blue "示例:"
    print_blue "  $0 --sdk --java           # 仅安装 SDK 和 Java"
    print_blue "  $0 --gradle               # 仅安装 Gradle"
    print_blue "  $0 --all                  # 安装所有组件"
    print_blue "  $0                        # 显示帮助信息"
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
            --all)
                INSTALL_ALL=true
                INSTALL_SDK=true
                INSTALL_GRADLE=true
                INSTALL_JAVA=true
                INSTALL_NDK=true
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
    if [[ "$INSTALL_SDK" = false && "$INSTALL_GRADLE" = false && "$INSTALL_JAVA" = false && "$INSTALL_NDK" = false ]]; then
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
# 检查当前工作目录是否正确
#===============================================================================
check_working_directory() {
    local current_dir_name
    current_dir_name=$(basename "$(pwd)")

    if [ "$current_dir_name" != "tools" ]; then
        print_red "错误: 当前目录是 $current_dir_name 目录"
        print_yellow "提示: 请在 tools 目录下执行此脚本"
        return 1
    fi
    return 0
}

#===============================================================================
# Android SDK 安装函数
#===============================================================================
android_sdk_install() {
    print_header "安装 Android SDK"

    # 检查工作目录
    if ! check_working_directory; then
        return 1
    fi

    print_yellow "正在检查 Android SDK 工具..."

    # 检查 Android SDK Command Line Tools 是否已存在
    if [ ! -d "cmdline-tools" ]; then
        print_yellow "Android SDK Command Line Tools 不存在, 开始下载..."

        local cmdline_tools_url="https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
        local cmdline_tools_zip="cmdline-tools.zip"

        wget "$cmdline_tools_url" -O "$cmdline_tools_zip"

        if [ $? -eq 0 ]; then
            print_yellow "下载完成, 正在解压..."
            unzip -q "$cmdline_tools_zip"
            rm -f "$cmdline_tools_zip"
            print_yellow "压缩包已清理"
        else
            print_red "下载失败!"
            return 1
        fi
    else
        print_yellow "Android SDK Command Line Tools 已存在"
    fi

    # 设置执行权限
    chmod +x cmdline-tools/bin/*

    # 检查 sdkmanager 是否可用并安装组件
    if [ -f "cmdline-tools/bin/sdkmanager" ]; then
        print_yellow "sdkmanager 可用, 正在安装 SDK 组件..."

        # 接受许可证
        if [ ! -d "cmdline-tools/licenses" ]; then
            print_yellow "正在接受 SDK 许可证..."
            yes | cmdline-tools/bin/sdkmanager --sdk_root=cmdline-tools --licenses >/dev/null 2>&1
        fi

        # 安装必需的 SDK 组件
        local components=("platform-tools" "platforms;android-35" "build-tools;35.0.0")
        local component_dirs=("cmdline-tools/platform-tools" "cmdline-tools/platforms" "cmdline-tools/build-tools")

        for i in "${!components[@]}"; do
            if [ ! -d "${component_dirs[$i]}" ]; then
                print_yellow "正在安装 ${components[$i]}..."
                cmdline-tools/bin/sdkmanager --sdk_root=cmdline-tools "${components[$i]}" >/dev/null 2>&1
            fi
        done

        print_green "✓ Android SDK 工具安装完成!"
    else
        print_red "✗ sdkmanager 不可用, 请检查安装"
        return 1
    fi
}

#===============================================================================
# Gradle 安装函数
#===============================================================================
gradle_install() {
    print_header "安装 Gradle"

    # 检查工作目录
    if ! check_working_directory; then
        return 1
    fi

    print_yellow "正在检查 Gradle 工具..."

    # 检查 Gradle 是否已存在
    if [ ! -d "gradle" ]; then
        print_yellow "Gradle 不存在, 开始下载..."

        local gradle_version="8.5"
        local gradle_zip="gradle-${gradle_version}-bin.zip"
        local gradle_url="https://services.gradle.org/distributions/${gradle_zip}"

        print_yellow "正在下载 Gradle ${gradle_version}..."
        wget "$gradle_url" -O "$gradle_zip"

        if [ $? -eq 0 ]; then
            print_yellow "下载完成, 正在解压..."
            unzip -q "$gradle_zip"

            # 重命名解压后的目录
            if [ -d "gradle-${gradle_version}" ]; then
                mv "gradle-${gradle_version}" gradle
            fi

            rm -f "$gradle_zip"
            print_yellow "压缩包已清理"

            # 设置执行权限
            chmod +x gradle/bin/gradle
            print_green "✓ Gradle 安装完成!"
        else
            print_red "✗ Gradle 下载失败!"
            return 1
        fi
    else
        print_yellow "Gradle 已存在"
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
}

#===============================================================================
# Java 环境安装函数
#===============================================================================
java_environment_install() {
    print_header "安装 Java 环境"

    # 检查工作目录
    if ! check_working_directory; then
        return 1
    fi

    print_yellow "正在检查 Java 环境..."

    # 检查 Java 是否已存在
    if [ ! -d "java" ]; then
        print_yellow "Java 环境不存在, 开始下载..."

        # 使用 Eclipse Temurin OpenJDK 17 (适合 Android 开发)
        local java_version="17.0.9"
        local java_build="9"
        local java_archive="OpenJDK17U-jdk_x64_linux_hotspot_${java_version}_${java_build}.tar.gz"
        local java_url="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${java_version}%2B${java_build}/${java_archive}"

        print_yellow "正在下载 OpenJDK ${java_version}..."
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
            print_yellow "压缩包已清理"

            # 设置执行权限
            chmod +x java/bin/*
            print_green "✓ Java 环境安装完成!"
        else
            print_red "✗ Java 环境下载失败!"
            return 1
        fi
    else
        print_yellow "Java 环境已存在"
    fi

    # 验证 Java 是否可用
    if [ -f "java/bin/java" ]; then
        print_green "✓ Java 可用: java/bin/java"
        print_blue "版本信息:"
        java/bin/java -version 2>&1 | head -n 3

        echo
        print_blue "环境变量设置提示:"
        print_blue "  export JAVA_HOME=$(pwd)/java"
        print_blue "  export PATH=\$PATH:\$JAVA_HOME/bin"
    else
        print_red "✗ Java 不可用, 请检查安装"
        return 1
    fi
}

#===============================================================================
# Android NDK 安装函数
#===============================================================================
android_ndk_install() {
    print_header "安装 Android NDK"

    # 检查工作目录
    if ! check_working_directory; then
        return 1
    fi

    print_yellow "正在检查 Android NDK..."

    # 检查 NDK 是否已存在
    if [ ! -d "ndk" ]; then
        print_yellow "Android NDK 不存在, 开始下载..."

        # 使用最新稳定版本的 NDK
        local ndk_version="26.1.10909125"
        local ndk_archive="android-ndk-r26b-linux.zip"
        local ndk_url="https://dl.google.com/android/repository/${ndk_archive}"

        print_yellow "正在下载 Android NDK r26b..."
        wget "$ndk_url" -O "$ndk_archive"

        if [ $? -eq 0 ]; then
            print_yellow "下载完成, 正在解压..."
            unzip -q "$ndk_archive"

            # 查找解压后的 NDK 目录并重命名
            local ndk_extracted_dir
            ndk_extracted_dir=$(find . -maxdepth 1 -name "android-ndk-r*" -type d | head -1)

            if [ -n "$ndk_extracted_dir" ]; then
                mv "$ndk_extracted_dir" ndk
            fi

            rm -f "$ndk_archive"
            print_yellow "压缩包已清理"

            # 设置执行权限
            chmod +x ndk/ndk-build
            print_green "✓ Android NDK 安装完成!"
        else
            print_red "✗ Android NDK 下载失败!"
            return 1
        fi
    else
        print_yellow "Android NDK 已存在"
    fi

    # 验证 NDK 是否可用
    if [ -f "ndk/ndk-build" ]; then
        print_green "✓ Android NDK 可用: ndk/ndk-build"
        
        # 显示 NDK 版本信息
        if [ -f "ndk/source.properties" ]; then
            print_blue "版本信息:"
            grep "Pkg.Revision" ndk/source.properties | cut -d'=' -f2 | sed 's/^[ \t]*//'
        fi

        echo
        print_blue "环境变量设置提示:"
        print_blue "  export ANDROID_NDK_HOME=$(pwd)/ndk"
        print_blue "  export PATH=\$PATH:\$ANDROID_NDK_HOME"
    else
        print_red "✗ Android NDK 不可用, 请检查安装"
        return 1
    fi
}

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
    print_blue "  Android SDK: $([ "$INSTALL_SDK" = true ] && echo "是" || echo "否")"
    print_blue "  Gradle: $([ "$INSTALL_GRADLE" = true ] && echo "是" || echo "否")"
    print_blue "  Java 环境: $([ "$INSTALL_JAVA" = true ] && echo "是" || echo "否")"
    print_blue "  Android NDK: $([ "$INSTALL_NDK" = true ] && echo "是" || echo "否")"
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
                print_yellow "export ANDROID_HOME=$TOOLS_DIR/cmdline-tools"
            fi
            if [ "$INSTALL_GRADLE" = true ]; then
                print_yellow "export GRADLE_HOME=$TOOLS_DIR/gradle"
            fi
            if [ "$INSTALL_NDK" = true ]; then
                print_yellow "export ANDROID_NDK_HOME=$TOOLS_DIR/ndk"
            fi
            
            # 构建 PATH 变量
            local path_additions=""
            if [ "$INSTALL_JAVA" = true ]; then
                path_additions=":\$JAVA_HOME/bin"
            fi
            if [ "$INSTALL_SDK" = true ]; then
                path_additions="$path_additions:\$ANDROID_HOME/bin"
            fi
            if [ "$INSTALL_GRADLE" = true ]; then
                path_additions="$path_additions:\$GRADLE_HOME/bin"
            fi
            if [ "$INSTALL_NDK" = true ]; then
                path_additions="$path_additions:\$ANDROID_NDK_HOME"
            fi
            
            if [ -n "$path_additions" ]; then
                print_yellow "export PATH=\$PATH$path_additions"
            fi
        fi
    else
        print_yellow "⚠ 部分组件安装失败 ($install_success/$install_total)"
        print_yellow "请检查错误信息并重新运行脚本"
    fi
}

# 执行主函数
main "$@"
