#!/bin/bash

#===============================================================================
# Android 开发环境安装脚本
# 功能: 三种安装模式 - 单独安装/不完整预装/完整预装
# 策略: 单独安装使用独立下载，预装模式使用cmdline-tools管理
# 作者: npz
# 版本: 4.0
#===============================================================================

#===============================================================================
# 颜色输出函数
#===============================================================================
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

# 获取脚本的绝对路径和所在目录
readonly SCRIPT_PATH=$(readlink -f "$0")
readonly SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
readonly PROJECT_DIR=$(dirname "$SCRIPT_DIR")
readonly TOOLS_DIR="$PROJECT_DIR/tools"

# 安装模式选择
MODE_STANDALONE=false           # 模式1: 单独安装 (独立下载方式)
MODE_MINIMAL_PREINSTALL=false   # 模式2: 不完整预装 (基础工具+环境路径)
MODE_FULL_PREINSTALL=false      # 模式3: 完整预装 (所有工具预装)

# 单独安装工具选项 (独立下载)
INSTALL_JAVA=false         # Java 环境
INSTALL_SDK=false          # Android SDK 基础
INSTALL_GRADLE=false       # Gradle 构建工具
INSTALL_NDK=false          # Android NDK
INSTALL_CMAKE=false        # CMake 工具

# 安装控制选项
FORCE_REINSTALL=false      # 强制重新安装 (删除现有环境)

# 用户指定版本号 (如果用户未指定则使用默认值)
USER_JAVA_VERSION=""
USER_GRADLE_VERSION=""
USER_NDK_VERSION=""
USER_CMAKE_VERSION=""
USER_CMDLINE_TOOLS_VERSION=""

# SDK 配置 (默认版本)
CMDLINE_TOOLS_VERSION="11076708"
ANDROID_API_LEVEL="33"
BUILD_TOOLS_VERSION="33.0.0"
NDK_VERSION="25.1.8937393"
CMAKE_VERSION="3.22.1"

# 独立下载版本配置 (默认版本)
JAVA_VERSION="17.0.9"
JAVA_BUILD="9"
GRADLE_VERSION="8.5"
NDK_STANDALONE_VERSION="r26c"
CMAKE_STANDALONE_VERSION="3.22.1"

#===============================================================================
# 显示帮助信息
#===============================================================================
show_help() {
    print_blue "Android 开发环境安装工具"
    echo
    print_blue "用法:"
    print_blue "  $0 [安装模式] [工具选项]"
    echo
    print_blue "安装模式 (三选一):"
    print_blue "  --standalone     模式1: 单独安装 (独立下载方式)"
    print_blue "  --minimal        模式2: 不完整预装 (基础工具+环境路径，编译时自动下载)"
    print_blue "  --full           模式3: 完整预装 (使用cmdline-tools预装所有工具)"
    echo
    print_blue "单独安装工具选项 (仅在 --standalone 模式下使用):"
    print_blue "  --java           安装 Java 环境 (独立下载)"
    print_blue "  --sdk            安装 Android SDK 基础"
    print_blue "  --gradle         安装 Gradle 构建工具 (独立下载)"
    print_blue "  --ndk            安装 Android NDK (独立下载)"
    print_blue "  --cmake          安装 CMake 工具 (独立下载)"
    echo
    print_blue "安装控制选项:"
    print_blue "  --force          强制重新安装 (删除现有环境后重新安装)"
    echo
    print_blue "版本指定选项:"
    print_blue "  --java-version=VERSION      指定Java版本 (默认: 17.0.9)"
    print_blue "  --gradle-version=VERSION    指定Gradle版本 (默认: 8.5)"
    print_blue "  --ndk-version=VERSION       指定NDK版本 (默认: r26c)"
    print_blue "  --cmake-version=VERSION     指定CMake版本 (默认: 3.22.1)"
    print_blue "  --cmdtools-version=VERSION  指定CommandLineTools版本 (默认: 11076708)"
    echo
    print_blue "  -h, --help       显示此帮助信息"
    echo
    print_blue "三种模式详细说明:"
    print_blue "  🔧 模式1 (单独安装): 精确控制，使用独立下载，不依赖cmdline-tools"
    print_blue "  ⚡ 模式2 (不完整预装): 只安装基础工具，环境脚本提供路径，编译时自动下载"
    print_blue "  📦 模式3 (完整预装): 预装所有开发工具，避免编译时网络下载"
    echo
    print_blue "示例:"
    print_blue "  $0 --standalone --java --gradle                    # 单独安装Java和Gradle"
    print_blue "  $0 --minimal                                       # 不完整预装模式"
    print_blue "  $0 --full                                          # 完整预装模式"
    print_blue "  $0 --full --force                                  # 强制重新安装完整预装模式"
    print_blue "  $0 --standalone --java --java-version=11.0.21     # 安装指定版本的Java"
    print_blue "  $0 --full --gradle-version=7.6 --ndk-version=r25c # 使用指定版本"
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
            # 安装模式选择 (三选一)
            --standalone)
                MODE_STANDALONE=true
                shift
                ;;
            --minimal)
                MODE_MINIMAL_PREINSTALL=true
                shift
                ;;
            --full)
                MODE_FULL_PREINSTALL=true
                shift
                ;;
            # 单独安装工具选项 (仅在 standalone 模式下有效)
            --java)
                INSTALL_JAVA=true
                shift
                ;;
            --sdk)
                INSTALL_SDK=true
                shift
                ;;
            --gradle)
                INSTALL_GRADLE=true
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
            --force)
                FORCE_REINSTALL=true
                shift
                ;;
            --java-version=*)
                USER_JAVA_VERSION="${1#*=}"
                shift
                ;;
            --gradle-version=*)
                USER_GRADLE_VERSION="${1#*=}"
                shift
                ;;
            --ndk-version=*)
                USER_NDK_VERSION="${1#*=}"
                shift
                ;;
            --cmake-version=*)
                USER_CMAKE_VERSION="${1#*=}"
                shift
                ;;
            --cmdtools-version=*)
                USER_CMDLINE_TOOLS_VERSION="${1#*=}"
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

    # 检查安装模式选择
    local mode_count=0
    [ "$MODE_STANDALONE" = true ] && ((mode_count++))
    [ "$MODE_MINIMAL_PREINSTALL" = true ] && ((mode_count++))
    [ "$MODE_FULL_PREINSTALL" = true ] && ((mode_count++))

    if [ $mode_count -eq 0 ]; then
        print_red "错误: 请选择一个安装模式 (--standalone, --minimal, --full)"
        echo
        show_help
        exit 1
    elif [ $mode_count -gt 1 ]; then
        print_red "错误: 只能选择一个安装模式"
        echo
        show_help
        exit 1
    fi

    # 如果是单独安装模式，检查是否选择了工具
    if [ "$MODE_STANDALONE" = true ]; then
        if [[ "$INSTALL_JAVA" = false && "$INSTALL_SDK" = false && "$INSTALL_GRADLE" = false && "$INSTALL_NDK" = false && "$INSTALL_CMAKE" = false ]]; then
            print_red "错误: 单独安装模式需要选择至少一个工具"
            echo
            show_help
            exit 1
        fi
    fi
}

#===============================================================================
# 初始化版本配置
#===============================================================================
init_versions() {
    # 使用用户指定版本或默认版本
    if [ -n "$USER_JAVA_VERSION" ]; then
        JAVA_VERSION="$USER_JAVA_VERSION"
        JAVA_BUILD=""  # 用户指定版本时，build号需要自动解析或提示用户
        print_blue "📌 使用用户指定的Java版本: $JAVA_VERSION"
    fi
    
    if [ -n "$USER_GRADLE_VERSION" ]; then
        GRADLE_VERSION="$USER_GRADLE_VERSION"
        print_blue "📌 使用用户指定的Gradle版本: $GRADLE_VERSION"
    fi
    
    if [ -n "$USER_NDK_VERSION" ]; then
        NDK_STANDALONE_VERSION="$USER_NDK_VERSION"
        print_blue "📌 使用用户指定的NDK版本: $NDK_STANDALONE_VERSION"
    fi
    
    if [ -n "$USER_CMAKE_VERSION" ]; then
        CMAKE_STANDALONE_VERSION="$USER_CMAKE_VERSION"
        CMAKE_VERSION="$USER_CMAKE_VERSION"  # 同时更新SDK管理器版本
        print_blue "📌 使用用户指定的CMake版本: $CMAKE_STANDALONE_VERSION"
    fi
    
    if [ -n "$USER_CMDLINE_TOOLS_VERSION" ]; then
        CMDLINE_TOOLS_VERSION="$USER_CMDLINE_TOOLS_VERSION"
        print_blue "📌 使用用户指定的CommandLineTools版本: $CMDLINE_TOOLS_VERSION"
    fi
    
    # 显示最终使用的版本配置
    if [ -n "$USER_JAVA_VERSION$USER_GRADLE_VERSION$USER_NDK_VERSION$USER_CMAKE_VERSION$USER_CMDLINE_TOOLS_VERSION" ]; then
        echo
        print_blue "📋 最终版本配置:"
        print_blue "  Java: $JAVA_VERSION$([ -n "$JAVA_BUILD" ] && echo "+$JAVA_BUILD")"
        print_blue "  Gradle: $GRADLE_VERSION"
        print_blue "  NDK: $NDK_STANDALONE_VERSION"
        print_blue "  CMake: $CMAKE_STANDALONE_VERSION"
        print_blue "  CommandLineTools: $CMDLINE_TOOLS_VERSION"
        echo
    fi
}

#===============================================================================
# 读取现有版本配置信息
#===============================================================================
load_existing_config() {
    local config_file="$TOOLS_DIR/.version_config"
    
    # 清空全局变量
    EXISTING_JAVA_VERSION=""
    EXISTING_JAVA_PATH=""
    EXISTING_GRADLE_VERSION=""
    EXISTING_GRADLE_PATH=""
    EXISTING_NDK_VERSION=""
    EXISTING_NDK_INTERNAL_VERSION=""
    EXISTING_NDK_PATH=""
    EXISTING_CMAKE_VERSION=""
    EXISTING_CMAKE_INTERNAL_VERSION=""
    EXISTING_CMAKE_PATH=""
    EXISTING_CMDLINE_TOOLS_VERSION=""
    EXISTING_CMDLINE_TOOLS_PATH=""
    EXISTING_SDK_PATH=""
    EXISTING_BUILD_TOOLS_VERSION=""
    EXISTING_INSTALL_MODE=""
    EXISTING_INSTALL_DATE=""
    
    # 如果配置文件存在，读取现有信息
    if [ -f "$config_file" ]; then
        print_blue "� 读取现有版本配置..."
        source "$config_file" 2>/dev/null || true
        
        # 保存现有信息到临时变量
        EXISTING_JAVA_VERSION="$INSTALLED_JAVA_VERSION"
        EXISTING_JAVA_PATH="$INSTALLED_JAVA_PATH"
        EXISTING_GRADLE_VERSION="$INSTALLED_GRADLE_VERSION"
        EXISTING_GRADLE_PATH="$INSTALLED_GRADLE_PATH"
        EXISTING_NDK_VERSION="$INSTALLED_NDK_VERSION"
        EXISTING_NDK_INTERNAL_VERSION="$INSTALLED_NDK_INTERNAL_VERSION"
        EXISTING_NDK_PATH="$INSTALLED_NDK_PATH"
        EXISTING_CMAKE_VERSION="$INSTALLED_CMAKE_VERSION"
        EXISTING_CMAKE_INTERNAL_VERSION="$INSTALLED_CMAKE_INTERNAL_VERSION"
        EXISTING_CMAKE_PATH="$INSTALLED_CMAKE_PATH"
        EXISTING_CMDLINE_TOOLS_VERSION="$INSTALLED_CMDLINE_TOOLS_VERSION"
        EXISTING_CMDLINE_TOOLS_PATH="$INSTALLED_CMDLINE_TOOLS_PATH"
        EXISTING_SDK_PATH="$INSTALLED_SDK_PATH"
        EXISTING_BUILD_TOOLS_VERSION="$INSTALLED_BUILD_TOOLS_VERSION"
        EXISTING_INSTALL_MODE="$INSTALL_MODE"
        EXISTING_INSTALL_DATE="$INSTALL_DATE"
    fi
}

#===============================================================================
# 清理指定工具的版本信息 (覆盖安装前调用)
#===============================================================================
clear_tool_version_info() {
    local tool_name="$1"
    
    case "$tool_name" in
        "java")
            EXISTING_JAVA_VERSION=""
            EXISTING_JAVA_PATH=""
            ;;
        "gradle")
            EXISTING_GRADLE_VERSION=""
            EXISTING_GRADLE_PATH=""
            ;;
        "ndk")
            EXISTING_NDK_VERSION=""
            EXISTING_NDK_INTERNAL_VERSION=""
            EXISTING_NDK_PATH=""
            ;;
        "cmake")
            EXISTING_CMAKE_VERSION=""
            EXISTING_CMAKE_INTERNAL_VERSION=""
            EXISTING_CMAKE_PATH=""
            ;;
        "sdk")
            EXISTING_CMDLINE_TOOLS_VERSION=""
            EXISTING_CMDLINE_TOOLS_PATH=""
            EXISTING_SDK_PATH=""
            EXISTING_BUILD_TOOLS_VERSION=""
            ;;
        "all")
            # 清理所有工具版本信息
            EXISTING_JAVA_VERSION=""
            EXISTING_JAVA_PATH=""
            EXISTING_GRADLE_VERSION=""
            EXISTING_GRADLE_PATH=""
            EXISTING_NDK_VERSION=""
            EXISTING_NDK_INTERNAL_VERSION=""
            EXISTING_NDK_PATH=""
            EXISTING_CMAKE_VERSION=""
            EXISTING_CMAKE_INTERNAL_VERSION=""
            EXISTING_CMAKE_PATH=""
            EXISTING_CMDLINE_TOOLS_VERSION=""
            EXISTING_CMDLINE_TOOLS_PATH=""
            EXISTING_SDK_PATH=""
            EXISTING_BUILD_TOOLS_VERSION=""
            ;;
    esac
}

#===============================================================================
# 检测并更新指定工具的版本信息
#===============================================================================
update_tool_version_info() {
    local tool_name="$1"
    
    case "$tool_name" in
        "java")
            if [ -d "$TOOLS_DIR/java" ]; then
                EXISTING_JAVA_PATH="$TOOLS_DIR/java"
                if [ -f "$EXISTING_JAVA_PATH/bin/java" ]; then
                    EXISTING_JAVA_VERSION=$("$EXISTING_JAVA_PATH/bin/java" -version 2>&1 | head -n 1 | cut -d'"' -f2)
                fi
            fi
            ;;
        "gradle")
            if [ -d "$TOOLS_DIR/gradle" ]; then
                EXISTING_GRADLE_PATH="$TOOLS_DIR/gradle"
                if [ -f "$EXISTING_GRADLE_PATH/bin/gradle" ]; then
                    EXISTING_GRADLE_VERSION=$("$EXISTING_GRADLE_PATH/bin/gradle" --version 2>/dev/null | grep "Gradle" | head -n 1 | awk '{print $2}')
                fi
            fi
            ;;
        "ndk")
            if [ -d "$TOOLS_DIR/ndk" ]; then
                # 优先检查版本号子目录结构
                local ndk_version_dir=$(find "$TOOLS_DIR/ndk" -maxdepth 1 -type d -name "*.*.*" | sort -V | tail -n 1)
                if [ -n "$ndk_version_dir" ] && [ -f "$ndk_version_dir/ndk-build" ]; then
                    EXISTING_NDK_PATH="$ndk_version_dir"
                    EXISTING_NDK_INTERNAL_VERSION=$(basename "$ndk_version_dir")
                    if [ -f "$ndk_version_dir/source.properties" ]; then
                        EXISTING_NDK_VERSION=$(grep "Pkg.Revision" "$ndk_version_dir/source.properties" | cut -d'=' -f2 | sed 's/^[ \t]*//' | cut -d'.' -f1-3)
                        EXISTING_NDK_VERSION="r${EXISTING_NDK_VERSION}"
                    fi
                # 检查直接目录结构
                elif [ -f "$TOOLS_DIR/ndk/ndk-build" ]; then
                    EXISTING_NDK_PATH="$TOOLS_DIR/ndk"
                    if [ -f "$EXISTING_NDK_PATH/source.properties" ]; then
                        EXISTING_NDK_VERSION=$(grep "Pkg.Revision" "$EXISTING_NDK_PATH/source.properties" | cut -d'=' -f2 | sed 's/^[ \t]*//' | cut -d'.' -f1-3)
                        EXISTING_NDK_VERSION="r${EXISTING_NDK_VERSION}"
                        EXISTING_NDK_INTERNAL_VERSION=$(grep "Pkg.Revision" "$EXISTING_NDK_PATH/source.properties" | cut -d'=' -f2 | sed 's/^[ \t]*//')
                    fi
                fi
            fi
            ;;
        "cmake")
            if [ -d "$TOOLS_DIR/cmake" ]; then
                # 优先检查版本号子目录结构
                local cmake_version_dir=$(find "$TOOLS_DIR/cmake" -maxdepth 1 -type d -name "*.*.*" | sort -V | tail -n 1)
                if [ -n "$cmake_version_dir" ] && [ -f "$cmake_version_dir/bin/cmake" ]; then
                    EXISTING_CMAKE_PATH="$cmake_version_dir"
                    EXISTING_CMAKE_INTERNAL_VERSION=$(basename "$cmake_version_dir")
                    EXISTING_CMAKE_VERSION=$("$cmake_version_dir/bin/cmake" --version 2>/dev/null | head -n 1 | awk '{print $3}')
                # 检查直接目录结构
                elif [ -f "$TOOLS_DIR/cmake/bin/cmake" ]; then
                    EXISTING_CMAKE_PATH="$TOOLS_DIR/cmake"
                    EXISTING_CMAKE_VERSION=$("$EXISTING_CMAKE_PATH/bin/cmake" --version 2>/dev/null | head -n 1 | awk '{print $3}')
                    EXISTING_CMAKE_INTERNAL_VERSION="$EXISTING_CMAKE_VERSION"
                fi
            fi
            ;;
        "sdk")
            if [ -d "$TOOLS_DIR/cmdline-tools" ]; then
                EXISTING_CMDLINE_TOOLS_PATH="$TOOLS_DIR/cmdline-tools"
                EXISTING_SDK_PATH="$TOOLS_DIR"
                EXISTING_CMDLINE_TOOLS_VERSION="$CMDLINE_TOOLS_VERSION"
                
                # 检测build-tools版本
                if [ -d "$TOOLS_DIR/build-tools" ]; then
                    EXISTING_BUILD_TOOLS_VERSION=$(ls "$TOOLS_DIR/build-tools" | sort -V | tail -n 1)
                fi
            fi
            ;;
    esac
}

#===============================================================================
# 保存版本配置信息
#===============================================================================
save_version_config() {
    local config_file="$TOOLS_DIR/.version_config"
    
    print_blue "💾 保存版本配置信息..."
    
    # 使用现有配置信息（已读取并可能已更新）
    cat > "$config_file" << EOF
# Android 开发环境版本配置
# 由 tools_install.sh 自动生成，请勿手动编辑
# 生成时间: $(date)

# Java 配置
INSTALLED_JAVA_VERSION="$EXISTING_JAVA_VERSION"
INSTALLED_JAVA_PATH="$EXISTING_JAVA_PATH"

# Gradle 配置
INSTALLED_GRADLE_VERSION="$EXISTING_GRADLE_VERSION"
INSTALLED_GRADLE_PATH="$EXISTING_GRADLE_PATH"

# Android NDK 配置
INSTALLED_NDK_VERSION="$EXISTING_NDK_VERSION"
INSTALLED_NDK_INTERNAL_VERSION="$EXISTING_NDK_INTERNAL_VERSION"
INSTALLED_NDK_PATH="$EXISTING_NDK_PATH"

# CMake 配置
INSTALLED_CMAKE_VERSION="$EXISTING_CMAKE_VERSION"
INSTALLED_CMAKE_INTERNAL_VERSION="$EXISTING_CMAKE_INTERNAL_VERSION"
INSTALLED_CMAKE_PATH="$EXISTING_CMAKE_PATH"

# Android SDK 配置
INSTALLED_CMDLINE_TOOLS_VERSION="$EXISTING_CMDLINE_TOOLS_VERSION"
INSTALLED_CMDLINE_TOOLS_PATH="$EXISTING_CMDLINE_TOOLS_PATH"
INSTALLED_SDK_PATH="$EXISTING_SDK_PATH"
INSTALLED_BUILD_TOOLS_VERSION="$EXISTING_BUILD_TOOLS_VERSION"

# 安装模式信息
INSTALL_MODE="$([ "$MODE_STANDALONE" = true ] && echo "standalone" || ([ "$MODE_MINIMAL_PREINSTALL" = true ] && echo "minimal" || echo "full"))"
INSTALL_DATE="$(date)"

# 工具安装状态
JAVA_INSTALLED="$([ -n "$EXISTING_JAVA_PATH" ] && echo "true" || echo "false")"
GRADLE_INSTALLED="$([ -n "$EXISTING_GRADLE_PATH" ] && echo "true" || echo "false")"
NDK_INSTALLED="$([ -n "$EXISTING_NDK_PATH" ] && echo "true" || echo "false")"
CMAKE_INSTALLED="$([ -n "$EXISTING_CMAKE_PATH" ] && echo "true" || echo "false")"
SDK_INSTALLED="$([ -n "$EXISTING_CMDLINE_TOOLS_PATH" ] && echo "true" || echo "false")"
EOF

    print_green "✅ 版本配置已更新到: $config_file"
    
    # 显示当前工具信息
    echo
    print_blue "📋 当前工具信息:"
    [ -n "$EXISTING_JAVA_VERSION" ] && print_green "  Java: $EXISTING_JAVA_VERSION ($EXISTING_JAVA_PATH)"
    [ -n "$EXISTING_GRADLE_VERSION" ] && print_green "  Gradle: $EXISTING_GRADLE_VERSION ($EXISTING_GRADLE_PATH)"
    [ -n "$EXISTING_NDK_VERSION" ] && print_green "  NDK: $EXISTING_NDK_VERSION ($EXISTING_NDK_PATH)"
    [ -n "$EXISTING_CMAKE_VERSION" ] && print_green "  CMake: $EXISTING_CMAKE_VERSION ($EXISTING_CMAKE_PATH)"
    [ -n "$EXISTING_CMDLINE_TOOLS_VERSION" ] && print_green "  SDK Tools: $EXISTING_CMDLINE_TOOLS_VERSION ($EXISTING_SDK_PATH)"
    [ -n "$EXISTING_BUILD_TOOLS_VERSION" ] && print_green "  Build Tools: $EXISTING_BUILD_TOOLS_VERSION"
}

#===============================================================================
# 检查环境是否已安装
#===============================================================================
check_environment_installed() {
    local has_any_tools=false
    local installed_tools=()
    
    cd "$TOOLS_DIR" 2>/dev/null || return 1
    
    # 检查各个工具是否已存在
    if [ -d "java" ]; then
        has_any_tools=true
        installed_tools+=("Java")
    fi
    
    if [ -d "cmdline-tools/latest" ]; then
        has_any_tools=true
        installed_tools+=("Android SDK")
    fi
    
    if [ -d "gradle" ]; then
        has_any_tools=true
        installed_tools+=("Gradle")
    fi
    
    if [ -d "ndk" ] || [ -d "ndk/${NDK_VERSION}" ]; then
        has_any_tools=true
        installed_tools+=("Android NDK")
    fi
    
    if [ -d "cmake" ] || [ -d "cmake/${CMAKE_VERSION}" ]; then
        has_any_tools=true
        installed_tools+=("CMake")
    fi
    
    if [ -d "platform-tools" ]; then
        has_any_tools=true
        installed_tools+=("Platform Tools")
    fi
    
    if [ -d "build-tools" ]; then
        has_any_tools=true
        installed_tools+=("Build Tools")
    fi
    
    if [ -d "platforms" ]; then
        has_any_tools=true
        installed_tools+=("Android Platforms")
    fi
    
    # 如果发现已安装的工具
    if [ "$has_any_tools" = true ]; then
        print_yellow "⚠️  发现已安装的 Android 开发环境"
        echo
        print_blue "📦 已安装的工具:"
        for tool in "${installed_tools[@]}"; do
            print_blue "  • $tool"
        done
        echo
        
        if [ "$FORCE_REINSTALL" = true ]; then
            print_yellow "🔄 检测到 --force 参数，将删除现有环境并重新安装"
            echo
            print_blue "🗑️  清理现有环境..."
            
            # 清理所有版本信息
            clear_tool_version_info "all"
            
            # 删除所有可能的工具目录
            rm -rf java cmdline-tools gradle ndk cmake platform-tools build-tools platforms extras licenses .temp 2>/dev/null || true
            
            print_green "✅ 现有环境已清理完成"
            echo
            return 0
        else
            print_blue "💡 环境已存在，如需重新安装请使用 --force 参数"
            print_blue "   示例: $0 --full --force"
            echo
            print_green "🎉 Android 开发环境已就绪!"
            echo
            print_blue "💡 接下来的步骤:"
            print_blue "  1. 运行 source env_setup.sh 设置环境变量"
            print_blue "  2. 进入 android/ 目录"
            print_blue "  3. 执行 ./gradlew build 开始构建"
            exit 0
        fi
    fi
    
    return 0
}

#===============================================================================
# 安装 Java 环境 (独立下载)
#===============================================================================
install_java() {
    print_header "安装 Java 环境"
    
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    if [ -d "java" ]; then
        print_green "✅ Java 环境已存在"
        java/bin/java -version 2>&1 | head -n 1
        return 0
    fi

    # 清理Java版本信息（即将安装新版本）
    clear_tool_version_info "java"

    print_blue "📥 下载 Eclipse Temurin OpenJDK ${JAVA_VERSION}..."
    local java_version="$JAVA_VERSION"
    local java_build="$JAVA_BUILD"
    
    # 如果用户指定了自定义版本但没有build号，尝试使用默认格式
    if [ -z "$java_build" ]; then
        case "$java_version" in
            17.*)
                java_build="9"  # 默认build号
                ;;
            11.*)
                java_build="9"  # 默认build号
                ;;
            8.*)
                java_build="7"  # 默认build号
                ;;
            *)
                java_build="1"  # 通用默认build号
                ;;
        esac
        print_yellow "⚠️  未指定build号，使用默认值: +$java_build"
    fi
    
    local java_archive="OpenJDK17U-jdk_x64_linux_hotspot_${java_version}_${java_build}.tar.gz"
    local java_url="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${java_version}%2B${java_build}/${java_archive}"

    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$java_archive" "$java_url"
    else
        wget -O "$java_archive" "$java_url"
    fi

    if [ $? -ne 0 ]; then
        print_red "❌ Java 下载失败"
        return 1
    fi

    print_blue "📦 解压 Java..."
    tar -xzf "$java_archive"
    local java_extracted_dir=$(find . -maxdepth 1 -name "jdk-${java_version}*" -type d | head -1)
    if [ -n "$java_extracted_dir" ]; then
        mv "$java_extracted_dir" java
    fi
    rm -f "$java_archive"
    chmod +x java/bin/*
    
    # 更新Java版本信息
    update_tool_version_info "java"
    
    print_green "✅ Java 环境安装完成"
    java/bin/java -version 2>&1 | head -n 1
    return 0
}

#===============================================================================
# 安装 Android SDK 基础 (cmdline-tools)
#===============================================================================
install_sdk() {
    print_header "安装 Android SDK 基础"
    
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }
    
    if [ -d "cmdline-tools/latest" ]; then
        print_green "✅ Android SDK cmdline-tools 已存在"
        return 0
    fi

    # 清理SDK版本信息（即将安装新版本）
    clear_tool_version_info "sdk"

    print_blue "📥 下载 Android SDK Command Line Tools ${CMDLINE_TOOLS_VERSION}..."
    CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o cmdline-tools.zip "$CMDTOOLS_URL"
    else
        wget -O cmdline-tools.zip "$CMDTOOLS_URL"
    fi
    
    if [ $? -ne 0 ]; then
        print_red "❌ 下载失败，请检查网络连接"
        return 1
    fi
    
    print_blue "📦 解压 cmdline-tools..."
    unzip -q cmdline-tools.zip
    rm cmdline-tools.zip
    
    # 创建正确的目录结构
    mkdir -p cmdline-tools/latest
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
    chmod +x cmdline-tools/latest/bin/*
    
    # 接受许可证
    print_blue "📝 接受 SDK 许可证..."
    yes | ./cmdline-tools/latest/bin/sdkmanager --sdk_root=. --licenses >/dev/null 2>&1
    
    # 更新SDK版本信息
    update_tool_version_info "sdk"
    
    print_green "✅ Android SDK 基础安装完成"
    return 0
}

#===============================================================================
# 安装 Gradle (独立下载)
#===============================================================================
install_gradle_standalone() {
    print_header "安装 Gradle (独立下载)"

    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    if [ -d "gradle" ]; then
        print_green "✅ Gradle 已存在"
        gradle/bin/gradle --version | head -n 1
        return 0
    fi

    # 清理Gradle版本信息（即将安装新版本）
    clear_tool_version_info "gradle"

    print_blue "📥 下载 Gradle ${GRADLE_VERSION}..."
    local gradle_zip="gradle-${GRADLE_VERSION}-bin.zip"
    local gradle_url="https://services.gradle.org/distributions/${gradle_zip}"

    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$gradle_zip" "$gradle_url"
    else
        wget -O "$gradle_zip" "$gradle_url"
    fi

    if [ $? -ne 0 ]; then
        print_red "❌ Gradle 下载失败"
        return 1
    fi

    print_blue "📦 解压 Gradle..."
    unzip -q "$gradle_zip"
    if [ -d "gradle-${GRADLE_VERSION}" ]; then
        mv "gradle-${GRADLE_VERSION}" gradle
    fi
    rm -f "$gradle_zip"
    chmod +x gradle/bin/gradle
    
    # 更新Gradle版本信息
    update_tool_version_info "gradle"
    
    print_green "✅ Gradle 安装完成"
    gradle/bin/gradle --version | head -n 1
    return 0
}

#===============================================================================
# 安装 Android NDK (独立下载)
#===============================================================================
install_ndk_standalone() {
    print_header "安装 Android NDK (独立下载)"
    
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    if [ -d "ndk" ]; then
        print_green "✅ Android NDK 已存在"
        return 0
    fi

    # 清理NDK版本信息（即将安装新版本）
    clear_tool_version_info "ndk"

    print_blue "📥 下载 Android NDK ${NDK_STANDALONE_VERSION}..."
    local ndk_archive="android-ndk-${NDK_STANDALONE_VERSION}-linux.zip"
    local ndk_url="https://dl.google.com/android/repository/${ndk_archive}"

    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$ndk_archive" "$ndk_url"
    else
        wget -O "$ndk_archive" "$ndk_url"
    fi

    if [ $? -ne 0 ]; then
        print_red "❌ Android NDK 下载失败"
        return 1
    fi

    print_blue "📦 解压 Android NDK..."
    unzip -q "$ndk_archive"
    # 创建版本号子目录结构，与cmdline-tools安装方式保持一致
    local ndk_extracted_dir=$(find . -maxdepth 1 -name "android-ndk-${NDK_STANDALONE_VERSION}*" -type d | head -1)
    if [ -n "$ndk_extracted_dir" ]; then
        # 创建 ndk/版本号 目录结构
        mkdir -p "ndk"
        mv "$ndk_extracted_dir" "ndk/${NDK_VERSION}"
        chmod +x "ndk/${NDK_VERSION}/ndk-build"
    fi
    rm -f "$ndk_archive"
    
    # 更新NDK版本信息
    update_tool_version_info "ndk"
    
    print_green "✅ Android NDK 安装完成"
    return 0
}

#===============================================================================
# 安装 CMake (独立下载)
#===============================================================================
install_cmake_standalone() {
    print_header "安装 CMake (独立下载)"
    
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    if [ -d "cmake" ]; then
        print_green "✅ CMake 已存在"
        cmake/bin/cmake --version | head -n 1
        return 0
    fi

    # 清理CMake版本信息（即将安装新版本）
    clear_tool_version_info "cmake"

    print_blue "📥 下载 CMake ${CMAKE_STANDALONE_VERSION}..."
    local cmake_archive="cmake-${CMAKE_STANDALONE_VERSION}-linux-x86_64.tar.gz"
    local cmake_url="https://github.com/Kitware/CMake/releases/download/v${CMAKE_STANDALONE_VERSION}/${cmake_archive}"

    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$cmake_archive" "$cmake_url"
    else
        wget -O "$cmake_archive" "$cmake_url"
    fi

    if [ $? -ne 0 ]; then
        print_red "❌ CMake 下载失败"
        return 1
    fi

    print_blue "📦 解压 CMake..."
    tar -xzf "$cmake_archive"
    # 创建版本号子目录结构，与cmdline-tools安装方式保持一致
    local cmake_extracted_dir=$(find . -maxdepth 1 -name "cmake-${CMAKE_STANDALONE_VERSION}*" -type d | head -1)
    if [ -n "$cmake_extracted_dir" ]; then
        # 创建 cmake/版本号 目录结构
        mkdir -p "cmake"
        mv "$cmake_extracted_dir" "cmake/${CMAKE_VERSION}"
        chmod +x "cmake/${CMAKE_VERSION}/bin/*"
    fi
    rm -f "$cmake_archive"
    
    # 更新CMake版本信息
    update_tool_version_info "cmake"
    
    print_green "✅ CMake 安装完成"
    cmake/${CMAKE_VERSION}/bin/cmake --version | head -n 1
    return 0
}

#===============================================================================
# 模式2: 不完整预装 (基础工具+环境路径配置)
#===============================================================================
install_minimal_preinstall() {
    print_header "模式2: 不完整预装"
    
    print_blue "📋 安装策略:"
    print_blue "  • 安装 Java、Android SDK、Gradle 基础工具"
    print_blue "  • 配置环境路径，让编译过程自动下载 NDK、Build-Tools 等"
    print_blue "  • 节省磁盘空间，确保版本兼容性"
    echo

    # 安装 Java 环境
    if ! install_java; then
        return 1
    fi
    echo

    # 安装 Android SDK 基础
    if ! install_sdk; then
        return 1
    fi
    echo

    # 安装 Gradle (独立下载，避免编译时下载)
    if ! install_gradle_standalone; then
        return 1
    fi
    echo

    print_green "✅ 不完整预装模式完成"
    print_blue "💡 说明:"
    print_blue "  • 基础工具已安装: Java, Android SDK, Gradle"
    print_blue "  • 环境变量已配置在 env_setup.sh 中"
    print_blue "  • 编译时会自动下载: NDK, Build-Tools, Platform 等"
    return 0
}

#===============================================================================
# 模式3: 完整预装 (预装所有开发工具)
#===============================================================================
install_full_preinstall() {
    print_header "模式3: 完整预装"
    
    print_blue "📋 安装策略:"
    print_blue "  • 安装所有开发工具"
    print_blue "  • Java, Gradle 使用独立下载"
    print_blue "  • 其他工具使用 cmdline-tools 安装"
    print_blue "  • 避免编译时网络下载"
    echo

    # 1. 安装 Java 环境 (独立下载)
    if ! install_java; then
        return 1
    fi
    echo

    # 2. 安装 Android SDK 基础
    if ! install_sdk; then
        return 1
    fi
    echo

    # 3. 安装 Gradle (独立下载)
    if ! install_gradle_standalone; then
        return 1
    fi
    echo

    # 4. 使用 cmdline-tools 安装其他工具
    cd "$TOOLS_DIR" || {
        print_red "无法切换到工具目录: $TOOLS_DIR"
        return 1
    }

    print_blue "📦 使用 cmdline-tools 安装完整工具集..."
    print_blue "📱 安装: Platform Tools, Build Tools, NDK, CMake, 多个API版本..."
    
    yes | ./cmdline-tools/latest/bin/sdkmanager --sdk_root=. \
        "platform-tools" \
        "platforms;android-33" \
        "platforms;android-34" \
        "build-tools;33.0.0" \
        "build-tools;34.0.0" \
        "ndk;${NDK_VERSION}" \
        "cmake;${CMAKE_VERSION}" \
        "extras;android;m2repository" \
        "extras;google;m2repository"
    
    if [ $? -eq 0 ]; then
        # 更新通过cmdline-tools安装的工具版本信息
        update_tool_version_info "ndk"
        update_tool_version_info "cmake"
        update_tool_version_info "sdk"  # 重新检测build-tools等
        
        print_green "✅ 完整预装模式完成"
        print_blue "📋 已安装的工具:"
        print_blue "  • Java 环境 (独立下载)"
        print_blue "  • Android SDK 基础"
        print_blue "  • Gradle 构建工具 (独立下载)"
        print_blue "  • Platform Tools (adb, fastboot)"
        print_blue "  • Build Tools (33.0.0, 34.0.0)"
        print_blue "  • Android Platforms (API 33, 34)"
        print_blue "  • Android NDK (${NDK_VERSION})"
        print_blue "  • CMake (${CMAKE_VERSION})"
        print_blue "  • Support Repositories"
        return 0
    else
        print_red "❌ 完整预装模式失败"
        return 1
    fi
}

#===============================================================================
# 主执行部分
#===============================================================================
main() {
    # 解析命令行参数
    parse_arguments "$@"
    
    # 初始化版本配置
    init_versions

    print_header "Android 开发环境安装工具"

    print_blue "脚本信息:"
    print_blue "  脚本目录: $SCRIPT_DIR"
    print_blue "  工程路径: $PROJECT_DIR"
    print_blue "  工具路径: $TOOLS_DIR"
    echo
    
    # 创建 tools 目录 (如果不存在)
    if [ ! -d "$TOOLS_DIR" ]; then
        print_blue "📁 创建工具目录: $TOOLS_DIR"
        mkdir -p "$TOOLS_DIR"
    fi
    
    # 读取现有配置信息
    load_existing_config
    
    # 检查环境是否已安装
    check_environment_installed

    local install_success=false

    # 根据选择的模式执行安装
    if [ "$MODE_STANDALONE" = true ]; then
        print_header "模式1: 单独安装 (独立下载)"
        
        print_blue "📋 安装计划:"
        print_blue "  Java 环境: $([ "$INSTALL_JAVA" = true ] && echo "✓" || echo "✗")"
        print_blue "  Android SDK: $([ "$INSTALL_SDK" = true ] && echo "✓" || echo "✗")"
        print_blue "  Gradle: $([ "$INSTALL_GRADLE" = true ] && echo "✓" || echo "✗")"
        print_blue "  Android NDK: $([ "$INSTALL_NDK" = true ] && echo "✓" || echo "✗")"
        print_blue "  CMake: $([ "$INSTALL_CMAKE" = true ] && echo "✓" || echo "✗")"
        echo

        local success_count=0
        local total_count=0

        # 统计并安装选择的工具
        [ "$INSTALL_JAVA" = true ] && ((total_count++))
        [ "$INSTALL_SDK" = true ] && ((total_count++))
        [ "$INSTALL_GRADLE" = true ] && ((total_count++))
        [ "$INSTALL_NDK" = true ] && ((total_count++))
        [ "$INSTALL_CMAKE" = true ] && ((total_count++))

        # 按顺序安装工具
        if [ "$INSTALL_JAVA" = true ]; then
            if install_java; then
                ((success_count++))
            fi
            echo
        fi

        if [ "$INSTALL_SDK" = true ]; then
            if install_sdk; then
                ((success_count++))
            fi
            echo
        fi

        if [ "$INSTALL_GRADLE" = true ]; then
            if install_gradle_standalone; then
                ((success_count++))
            fi
            echo
        fi

        if [ "$INSTALL_NDK" = true ]; then
            if install_ndk_standalone; then
                ((success_count++))
            fi
            echo
        fi

        if [ "$INSTALL_CMAKE" = true ]; then
            if install_cmake_standalone; then
                ((success_count++))
            fi
            echo
        fi

        # 检查安装结果
        if [ $success_count -eq $total_count ]; then
            install_success=true
        fi

    elif [ "$MODE_MINIMAL_PREINSTALL" = true ]; then
        if install_minimal_preinstall; then
            install_success=true
        fi

    elif [ "$MODE_FULL_PREINSTALL" = true ]; then
        if install_full_preinstall; then
            install_success=true
        fi
    fi

    # 显示最终结果
    echo
    print_header "安装完成"
    
    if [ "$install_success" = true ]; then
        # 保存版本配置
        save_version_config
        echo
        
        print_green "🎉 安装成功完成!"
        echo
        print_blue "💡 接下来的步骤:"
        print_blue "  1. 运行 source env_setup.sh 设置环境变量"
        print_blue "  2. 进入 android/ 目录"
        print_blue "  3. 执行 ./gradlew build 开始构建"
        echo
        print_header "环境变量配置"
        print_blue "所有环境变量已配置在 env_setup.sh 中"
        
    else
        print_red "❌ 安装失败"
        print_red "请检查错误信息并重新运行脚本"
        exit 1
    fi
}

# 执行主函数
main "$@"
