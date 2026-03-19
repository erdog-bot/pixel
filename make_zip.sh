#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# make_zip.sh — 将 magisk_package/ 打包为 AnyKernel3 刷机 ZIP
#
# 前提：
#   1. magisk_package/Image 存在（编译好的内核镜像）
#   2. magisk_package/tools/ 存在（运行 ./setup_tools.sh 获取）
#
# 用法：./make_zip.sh [输出文件名（可选）]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/magisk_package"
DATE=$(date +%Y%m%d_%H%M)
OUT_ZIP="${1:-${SCRIPT_DIR}/pixel10-kernel-aosp-${DATE}.zip}"

# --- 检查前提条件 ---
echo "==> 检查前提条件 ..."

if [ ! -f "$PKG_DIR/Image" ]; then
    echo "ERROR: 未找到内核镜像 $PKG_DIR/Image"
    echo ""
    echo "请先编译内核，然后执行："
    echo "  cp <编译产物目录>/Image $PKG_DIR/Image"
    echo ""
    echo "Bazel 编译命令（在 Linux 上）："
    echo "  tools/bazel run --config=stamp --config=lga //private/devices/google/lga:lga_dist"
    echo "  cp out/lga/dist/Image $PKG_DIR/Image"
    exit 1
fi

if [ ! -f "$PKG_DIR/tools/ak3-core.sh" ]; then
    echo "ERROR: 未找到 $PKG_DIR/tools/ak3-core.sh"
    echo "请先运行：./setup_tools.sh"
    exit 1
fi

# --- 进入打包目录 ---
echo "==> 开始打包 ..."
cd "$PKG_DIR"

# 确保 update-binary 可执行
chmod +x META-INF/com/google/android/update-binary 2>/dev/null || true

# 使用 zip 打包（-r 递归，-9 最大压缩，-X 排除额外属性）
# update-binary 必须用 stored（无压缩）才能被 recovery 识别
zip -r9X "$OUT_ZIP" . \
    --exclude "*.DS_Store" \
    --exclude "*__MACOSX*" \
    --exclude "*.gitkeep" \
    --exclude "README.md"

# update-binary 用不压缩模式重新添加（Recovery 要求）
zip -j0X "$OUT_ZIP" META-INF/com/google/android/update-binary

echo ""
echo "✅ 打包成功！"
echo "   输出文件：$OUT_ZIP"
echo "   文件大小：$(du -sh "$OUT_ZIP" | cut -f1)"
echo ""
echo "刷入方式："
echo "  Magisk App → Modules → 从本地安装 → 选择上方 ZIP → 重启"
echo "  或 进入 Recovery → Install → 选择 ZIP → Swipe to Flash"
