#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
===============================================================================
应用图标生成脚本
功能: 使用PIL库生成书本风格的Android应用图标
支持分辨率: 48x48, 72x72, 96x96, 144x144, 192x192 (mdpi到xxxhdpi)
作者: npz
版本: 1.0
===============================================================================
"""

from PIL import Image, ImageDraw
import os

def create_book_icon(size, output_path):
    """
    创建书本风格的图标

    Args:
        size (int): 图标尺寸 (正方形)
        output_path (str): 输出文件路径
    """
    # 创建画布, 背景透明
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 计算缩放比例
    scale = size / 48.0

    # 绘制书本主体
    book_width = int(32 * scale)
    book_height = int(40 * scale)
    x = (size - book_width) // 2
    y = (size - book_height) // 2

    # 书本背景 - 蓝色
    draw.rectangle([x, y, x + book_width, y + book_height],
                   fill=(33, 150, 243, 255), outline=(25, 118, 210, 255), width=max(1, int(2*scale)))

    # 书脊 - 深蓝色
    draw.rectangle([x, y, x + int(4*scale), y + book_height],
                   fill=(25, 118, 210, 255))

    # 页面线条 - 白色
    for i in range(3):
        line_y = y + int((8 + i * 8) * scale)
        draw.line([x + int(8*scale), line_y, x + book_width - int(4*scale), line_y],
                  fill=(255, 255, 255, 255), width=max(1, int(scale)))

    # 保存图像
    img.save(output_path, 'PNG')

# 获取脚本路径信息
import sys
script_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.dirname(script_dir)
android_res_dir = os.path.join(project_dir, "android", "app", "src", "main", "res")

print(f"Android资源目录: {android_res_dir}")

# 检查Android资源目录是否存在
if not os.path.exists(android_res_dir):
    print(f"错误: Android资源目录不存在 - {android_res_dir}")
    sys.exit(1)

# 创建图标目录
densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192
}

print("开始生成应用图标...")

for density, size in densities.items():
    # Android mipmap目录路径
    mipmap_dir = os.path.join(android_res_dir, f'mipmap-{density}')

    # 确保目录存在
    os.makedirs(mipmap_dir, exist_ok=True)

    # 生成普通图标
    launcher_path = os.path.join(mipmap_dir, 'ic_launcher.png')
    create_book_icon(size, launcher_path)
    print(f"✓ 生成 {density} 普通图标: {launcher_path}")

    # 生成圆形图标 (同样的图标)
    launcher_round_path = os.path.join(mipmap_dir, 'ic_launcher_round.png')
    create_book_icon(size, launcher_round_path)
    print(f"✓ 生成 {density} 圆形图标: {launcher_round_path}")

print("✅ 应用图标生成完成! 已放入Android项目目录")