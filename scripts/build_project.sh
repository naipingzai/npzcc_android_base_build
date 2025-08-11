#!/bin/bash

#===============================================================================
# Android 项目编译脚本
# 功能: 自动设置环境变量并编译Android项目 (支持NDK)
# 作者: npz
# 版本: 1.1
#===============================================================================

# 获取脚本的绝对路径和所在目录
readonly SCRIPT_PATH=$(readlink -f "$0")
readonly SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
readonly PROJECT_DIR=$(dirname "$SCRIPT_DIR")
readonly ANDROID_DIR="$PROJECT_DIR/android"

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
# 检查环境变量
#===============================================================================
check_environment() {
    print_blue "检查开发环境..."

    # 检查JAVA_HOME
    if [ -z "$JAVA_HOME" ]; then
        print_yellow "⚠ JAVA_HOME 未设置, 正在自动设置环境变量..."
        source "$SCRIPT_DIR/env_setup.sh"
        return $?
    fi

    # 检查ANDROID_HOME
    if [ -z "$ANDROID_HOME" ]; then
        print_yellow "⚠ ANDROID_HOME 未设置, 正在自动设置环境变量..."
        source "$SCRIPT_DIR/env_setup.sh"
        return $?
    fi

    # 检查NDK (对于NDK项目)
    if [ ! -d "$PROJECT_DIR/tools/ndk" ]; then
        print_yellow "⚠ NDK 未安装"
        print_blue "此项目包含NDK代码，需要安装Android NDK"
        read -p "是否现在安装NDK开发环境? [Y/n]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_blue "正在安装NDK开发环境..."
            if [ -f "$SCRIPT_DIR/ndk_setup.sh" ]; then
                bash "$SCRIPT_DIR/ndk_setup.sh"
            else
                print_red "NDK安装脚本不存在"
                return 1
            fi
        else
            print_yellow "跳过NDK安装，可能会导致编译失败"
        fi
    fi

    # 检查CMake (对于NDK项目)
    if ! command -v cmake >/dev/null 2>&1; then
        print_yellow "⚠ CMake 未找到"
        print_blue "NDK项目需要CMake支持"
        source "$SCRIPT_DIR/env_setup.sh"
    fi

    print_green "✓ 环境变量已设置"
    print_blue "  JAVA_HOME: $JAVA_HOME"
    print_blue "  ANDROID_HOME: $ANDROID_HOME"
    [ -n "$ANDROID_NDK_HOME" ] && print_blue "  ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
    [ -n "$CMAKE_HOME" ] && print_blue "  CMAKE_HOME: $CMAKE_HOME"
    return 0
}

#===============================================================================
# 编译项目
#===============================================================================
build_project() {
    local build_type="$1"
    local clean_before="$2"

    print_header "Android 项目编译工具"

    # 检查Android项目目录
    if [ ! -d "$ANDROID_DIR" ]; then
        print_red "错误: Android项目目录不存在 - $ANDROID_DIR"
        exit 1
    fi

    print_blue "项目路径: $ANDROID_DIR"

    # 检查环境变量
    if ! check_environment; then
        print_red "环境变量设置失败"
        exit 1
    fi

    # 切换到Android目录
    cd "$ANDROID_DIR" || {
        print_red "无法切换到Android目录: $ANDROID_DIR"
        exit 1
    }

    # 检查Gradle Wrapper
    if [ ! -f "./gradlew" ]; then
        print_red "错误: gradlew 文件不存在"
        print_yellow "请先运行: gradle wrapper"
        exit 1
    fi

    # 可选清理
    if [ "$clean_before" = "true" ]; then
        print_blue "正在清理项目..."
        if ./gradlew clean; then
            print_green "✓ 项目清理完成"
        else
            print_red "✗ 项目清理失败"
            exit 1
        fi
        echo
    fi

    # 开始编译
    local gradle_task=""
    case "$build_type" in
        "debug")
            gradle_task="assembleDebug"
            print_blue "正在编译 Debug 版本..."
            ;;
        "release")
            gradle_task="assembleRelease"
            print_blue "正在编译 Release 版本..."
            ;;
        "all")
            gradle_task="assemble"
            print_blue "正在编译所有版本..."
            ;;
        *)
            print_red "错误: 未知的编译类型 - $build_type"
            exit 1
            ;;
    esac

    # 记录开始时间
    local start_time=$(date +%s)

    # 执行编译
    if ./gradlew "$gradle_task"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        print_green "✓ 编译成功!"
        print_blue "编译耗时: ${duration}秒"

        # 显示生成的APK文件
        echo
        print_header "生成的APK文件"
        local apk_files
        apk_files=$(find app/build/outputs/apk -name "*.apk" -type f 2>/dev/null)

        if [ -n "$apk_files" ]; then
            # 创建输出目录
            local output_dir="$PROJECT_DIR/output"
            print_blue "创建输出目录: $output_dir"
            mkdir -p "$output_dir"

            # 显示和拷贝APK文件
            local copy_count=0
            while IFS= read -r apk; do
                local size=$(du -h "$apk" | cut -f1)
                local apk_name=$(basename "$apk")
                local apk_type=""

                # 确定APK类型
                if [[ "$apk" == *"debug"* ]]; then
                    apk_type="debug"
                elif [[ "$apk" == *"release"* ]]; then
                    apk_type="release"
                else
                    apk_type="unknown"
                fi

                local output_name="app_${apk_type}.apk"
                local output_path="$output_dir/$output_name"

                print_green "📱 $apk ($size)"

                # 拷贝APK文件
                if cp "$apk" "$output_path"; then
                    print_green "✓ 已拷贝到: $output_path"
                    copy_count=$((copy_count + 1))
                else
                    print_red "✗ 拷贝失败: $output_path"
                fi
            done <<< "$apk_files"

            echo
            print_blue "APK拷贝结果: 成功拷贝 $copy_count 个文件到 $output_dir"
            print_blue "APK安装命令示例:"
            local debug_apk=$(echo "$apk_files" | grep debug | head -1)
            if [ -n "$debug_apk" ]; then
                print_yellow "  adb install \"$(realpath "$debug_apk")\""
            fi
        else
            print_yellow "⚠ 未找到生成的APK文件"
        fi

    else
        print_red "✗ 编译失败!"
        exit 1
    fi
}

#===============================================================================
# 显示帮助信息
#===============================================================================
show_help() {
    echo "Android 项目编译脚本"
    echo
    echo "用法: $0 [选项] [编译类型]"
    echo
    echo "编译类型:"
    echo "  debug     编译Debug版本 (默认)"
    echo "  release   编译Release版本"
    echo "  all       编译所有版本"
    echo
    echo "选项:"
    echo "  -c, --clean    编译前先清理项目"
    echo "  -h, --help     显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0              # 编译Debug版本"
    echo "  $0 debug        # 编译Debug版本"
    echo "  $0 release      # 编译Release版本"
    echo "  $0 -c debug     # 清理后编译Debug版本"
    echo "  $0 --clean all  # 清理后编译所有版本"
}

#===============================================================================
# 主执行部分
#===============================================================================
main() {
    local build_type="debug"
    local clean_before="false"

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--clean)
                clean_before="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            debug|release|all)
                build_type="$1"
                shift
                ;;
            *)
                print_red "错误: 未知参数 - $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done

    # 开始编译
    build_project "$build_type" "$clean_before"
}

# 执行主函数
main "$@"
