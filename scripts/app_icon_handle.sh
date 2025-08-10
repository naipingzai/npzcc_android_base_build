#!/bin/bash

#===============================================================================
# 应用图标处理脚本
# 功能: 使用FFmpeg将图片裁切成正方形并生成多分辨率PNG图标
# 支持分辨率: 48x48, 72x72, 96x96, 144x144, 192x192
# 作者: npz
# 版本: 1.0
#===============================================================================

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
# 获取脚本路径信息
#===============================================================================
readonly SCRIPT_PATH=$(readlink -f "$0")
readonly SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
readonly PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
readonly RESOURCES_DIR="$PROJECT_ROOT/resources"

print_header "应用图标处理工具"
print_blue "脚本路径: $SCRIPT_PATH"
print_blue "脚本目录: $SCRIPT_DIR"
print_blue "工程根目录: $PROJECT_ROOT"
print_blue "资源目录: $RESOURCES_DIR"

# 检查resources目录是否存在
if [ ! -d "$RESOURCES_DIR" ]; then
    print_red "错误: resources目录不存在: $RESOURCES_DIR"
    exit 1
fi

# 查找origin.*文件
print_yellow "查找原始图片文件..."
ORIGIN_FILE=""
for file in "$RESOURCES_DIR"/origin.*; do
    if [ -f "$file" ]; then
        ORIGIN_FILE="$file"
        break
    fi
done

if [ -z "$ORIGIN_FILE" ]; then
    print_red "错误: 在 $RESOURCES_DIR 中未找到 origin.* 文件"
    exit 1
fi

print_green "找到原始图片: $ORIGIN_FILE"

# 检查ffmpeg是否安装
if ! command -v ffmpeg &> /dev/null; then
    print_red "错误: ffmpeg 未安装, 请先安装 ffmpeg"
    exit 1
fi

# 获取图片分辨率信息
print_yellow "获取图片分辨率信息..."
RESOLUTION=$(ffmpeg -i "$ORIGIN_FILE" 2>&1 | grep "Stream.*Video" | grep -o '[0-9]\+x[0-9]\+' | head -n1)

if [ -z "$RESOLUTION" ]; then
    print_red "错误: 无法获取图片分辨率信息"
    exit 1
fi

WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
HEIGHT=$(echo $RESOLUTION | cut -d'x' -f2)

print_green "原始图片分辨率: ${WIDTH}x${HEIGHT}"

# 计算正方形尺寸 (取较小值)
if [ "$WIDTH" -lt "$HEIGHT" ]; then
    SQUARE_SIZE=$WIDTH
else
    SQUARE_SIZE=$HEIGHT
fi

print_green "裁切后正方形尺寸: ${SQUARE_SIZE}x${SQUARE_SIZE}"

# 设置Android项目资源目录
ANDROID_RES_DIR="$PROJECT_ROOT/android/app/src/main/res"
print_yellow "Android资源目录: $ANDROID_RES_DIR"

# 检查Android资源目录是否存在
if [ ! -d "$ANDROID_RES_DIR" ]; then
    print_red "错误: Android资源目录不存在 - $ANDROID_RES_DIR"
    exit 1
fi

# 定义分辨率和对应的目录
declare -A DENSITIES
DENSITIES[48]="mdpi"
DENSITIES[72]="hdpi"
DENSITIES[96]="xhdpi"
DENSITIES[144]="xxhdpi"
DENSITIES[192]="xxxhdpi"

# 裁切和缩放图片的函数
create_icon() {
    local size=$1
    local density=$2
    local output_dir="$ANDROID_RES_DIR/mipmap-$density"

    print_yellow "生成 ${size}x${size} 图标到 mipmap-$density 目录..."

    # 创建mipmap目录
    mkdir -p "$output_dir"

    # 临时输出文件
    local temp_file="$output_dir/temp_${size}.png"

    # 使用ffmpeg裁切成正方形并缩放
    # 计算裁切的起始位置 (居中裁切)
    local crop_x=$(( (10#$WIDTH - 10#$SQUARE_SIZE) / 2 ))
    local crop_y=$(( (10#$HEIGHT - 10#$SQUARE_SIZE) / 2 ))

    # ffmpeg命令: 裁切 -> 缩放 -> 输出PNG
    ffmpeg -i "$ORIGIN_FILE" \
           -vf "crop=${SQUARE_SIZE}:${SQUARE_SIZE}:${crop_x}:${crop_y},scale=${size}:${size}" \
           -y "$temp_file" 2>/dev/null

    if [ $? -eq 0 ]; then
        # 复制为ic_launcher.png
        cp "$temp_file" "$output_dir/ic_launcher.png"
        print_green "✓ 生成 $density 普通图标: $output_dir/ic_launcher.png"

        # 复制为ic_launcher_round.png
        cp "$temp_file" "$output_dir/ic_launcher_round.png"
        print_green "✓ 生成 $density 圆形图标: $output_dir/ic_launcher_round.png"

        # 删除临时文件
        rm "$temp_file"

        return 0
    else
        print_red "生成失败: $density (${size}x${size})"
        return 1
    fi
}

# 生成所有分辨率的图标
print_yellow "开始生成应用图标..."
SUCCESS_COUNT=0
TOTAL_COUNT=5

for size in 48 72 96 144 192; do
    density=${DENSITIES[$size]}

    if create_icon $size $density; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    fi
done

# 输出结果统计
print_blue "======== 生成结果 ========"
print_green "成功生成: $SUCCESS_COUNT/$TOTAL_COUNT"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    print_green "✅ 所有图标生成完成! 已直接放入Android项目mipmap目录"
    print_blue "Android图标目录位置: $ANDROID_RES_DIR/mipmap-*/"
    print_blue "生成的图标文件:"
    for size in 48 72 96 144 192; do
        density=${DENSITIES[$size]}
        mipmap_dir="$ANDROID_RES_DIR/mipmap-$density"
        if [ -d "$mipmap_dir" ]; then
            print_blue "  mipmap-$density (${size}x${size}):"
            ls -la "$mipmap_dir" | grep "ic_launcher.*\.png$" | awk '{print "    " $9 " (" $5 " bytes)"}'
        fi
    done
else
    print_yellow "部分图标生成失败, 请检查错误信息"
fi

print_blue "=========================="
