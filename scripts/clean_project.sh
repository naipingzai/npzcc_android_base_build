#!/bin/bash

#===============================================================================
# Android 项目清理脚本
# 功能: 清理编译产生的中间文件和缓存
# 作者: npz
# 版本: 1.0
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
# 获取目录大小
#===============================================================================
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

#===============================================================================
# 清理函数
#===============================================================================
clean_project() {
    print_header "Android 项目清理工具"

    # 检查Android项目目录
    if [ ! -d "$ANDROID_DIR" ]; then
        print_red "错误: Android项目目录不存在 - $ANDROID_DIR"
        exit 1
    fi

    print_blue "项目路径: $ANDROID_DIR"
    echo

    # 记录清理前的大小
    print_yellow "清理前文件大小统计:"

    local build_size_before=$(get_dir_size "$ANDROID_DIR/app/build")
    local gradle_cache_size_before=$(get_dir_size "$ANDROID_DIR/.gradle")
    local cxx_size_before=$(get_dir_size "$ANDROID_DIR/app/.cxx")
    local external_native_size_before=$(get_dir_size "$ANDROID_DIR/app/.externalNativeBuild")

    print_yellow "  app/build: $build_size_before"
    print_yellow "  .gradle: $gradle_cache_size_before"
    print_yellow "  app/.cxx: $cxx_size_before"
    print_yellow "  app/.externalNativeBuild: $external_native_size_before"
    echo

    # 切换到Android目录
    cd "$ANDROID_DIR" || {
        print_red "无法切换到Android目录: $ANDROID_DIR"
        exit 1
    }

    # 执行Gradle清理
    print_blue "正在执行 Gradle clean..."
    if ./gradlew clean; then
        print_green "✓ Gradle clean 完成"
    else
        print_red "✗ Gradle clean 失败"
        exit 1
    fi

    echo

    # 清理Gradle缓存目录
    print_blue "正在清理Gradle缓存目录..."
    if [ -d ".gradle" ]; then
        local gradle_size_before=$(du -sh .gradle 2>/dev/null | cut -f1)
        rm -rf .gradle
        print_green "✓ Gradle缓存已清理 (清理了 $gradle_size_before)"
    else
        print_yellow "⚠ Gradle缓存目录不存在"
    fi

    echo

    # 清理C++/NDK编译产物
    print_blue "正在清理C++/NDK编译产物..."
    local cpp_cleaned_count=0
    
    # 清理.cxx目录 (CMake编译缓存)
    if [ -d "app/.cxx" ]; then
        local cxx_size=$(du -sh app/.cxx 2>/dev/null | cut -f1)
        rm -rf app/.cxx
        print_green "✓ CMake编译缓存已清理: app/.cxx (清理了 $cxx_size)"
        cpp_cleaned_count=$((cpp_cleaned_count + 1))
    fi
    
    # 清理.externalNativeBuild目录 (旧版NDK构建缓存)
    if [ -d "app/.externalNativeBuild" ]; then
        local external_size=$(du -sh app/.externalNativeBuild 2>/dev/null | cut -f1)
        rm -rf app/.externalNativeBuild
        print_green "✓ NDK构建缓存已清理: app/.externalNativeBuild (清理了 $external_size)"
        cpp_cleaned_count=$((cpp_cleaned_count + 1))
    fi
    
    # 清理build目录中的NDK相关文件 (如果存在)
    if [ -d "app/build" ]; then
        local so_files=$(find app/build -name "*.so" -type f 2>/dev/null | wc -l)
        if [ $so_files -gt 0 ]; then
            find app/build -name "*.so" -type f -delete 2>/dev/null
            print_green "✓ 清理了 $so_files 个.so文件"
        fi
        
        find app/build -name "obj" -type d -exec rm -rf {} + 2>/dev/null
        find app/build -name "cmake" -type d -exec rm -rf {} + 2>/dev/null
    fi
    
    # 清理临时文件
    find . -name "*.tmp" -type f -delete 2>/dev/null
    find . -name "*.log" -type f -delete 2>/dev/null
    
    if [ $cpp_cleaned_count -gt 0 ]; then
        print_green "✓ C++/NDK编译产物清理完成 (清理了 $cpp_cleaned_count 个目录)"
    else
        print_yellow "⚠ 没有发现需要清理的C++/NDK编译产物"
    fi

    echo

    # 清理其他临时文件
    print_blue "清理其他临时文件..."

    # 清理IDE文件
    if [ -d ".idea" ]; then
        rm -rf .idea/caches .idea/shelf .idea/workspace.xml .idea/tasks.xml
        print_green "✓ IDE缓存文件已清理"
    fi

    # 清理本地属性文件 (如果存在敏感信息)
    if [ -f "local.properties" ]; then
        print_yellow "⚠ 保留 local.properties 文件 (包含SDK路径)"
    fi

    echo

    # 显示清理后的统计
    print_header "清理完成"

    print_green "清理后文件大小统计:"
    local build_size_after=$(get_dir_size "$ANDROID_DIR/app/build")
    local gradle_cache_size_after=$(get_dir_size "$ANDROID_DIR/.gradle")
    local cxx_size_after=$(get_dir_size "$ANDROID_DIR/app/.cxx")
    local external_native_size_after=$(get_dir_size "$ANDROID_DIR/app/.externalNativeBuild")

    print_green "  app/build: $build_size_after (原: $build_size_before)"
    print_green "  .gradle: $gradle_cache_size_after (原: $gradle_cache_size_before)"
    print_green "  app/.cxx: $cxx_size_after (原: $cxx_size_before)"
    print_green "  app/.externalNativeBuild: $external_native_size_after (原: $external_native_size_before)"

    echo
    print_blue "清理内容包括:"
    print_blue "  • 所有编译生成的APK文件"
    print_blue "  • 编译过程中的中间文件"
    print_blue "  • 资源处理临时文件"
    print_blue "  • Kotlin/Java编译缓存"
    print_blue "  • C++/NDK编译缓存 (.cxx目录)"
    print_blue "  • 旧版NDK构建缓存 (.externalNativeBuild目录)"
    print_blue "  • 原生库文件 (.so文件)"
    print_blue "  • IDE缓存文件"
    print_blue "  • Gradle本地缓存 (.gradle目录)"

    echo
    print_green "🎉 项目清理完成!"
    print_yellow "💡 下次编译时间可能会稍长, 因为需要重新生成某些文件"
}

#===============================================================================
# 主执行部分
#===============================================================================
main() {
    clean_project
}

# 执行主函数
main "$@"
