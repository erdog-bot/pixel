#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# build_kernel_and_package.sh — 在 Linux 上一键编译 Pixel 10 内核并打包为 AnyKernel3 ZIP
#
# 系统要求：
#   - Linux x86_64（Ubuntu 20.04 / 22.04 推荐）
#   - Python 3, Git, curl/wget, zip
#   - 约 50+ GB 磁盘空间
#
# 用法：
#   ./build_kernel_and_package.sh [设备代号]
#   设备代号默认为 lga（Pixel 10）
#
# 其他支持设备：
#   caimito  — Pixel 9 / 9 Pro / 9 Pro XL（Tensor G4, Zuma Pro）
#   tegu     — Pixel 9 Pro Fold（Tensor G4）
#   akita    — Pixel 8a（Tensor G3, Zuma）
#   shusky   — Pixel 8 / 8 Pro

set -euo pipefail

# ---- 配置 ----
DEVICE="${1:-lga}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/magisk_package"
DATE=$(date +%Y%m%d_%H%M)
OUT_ZIP="$SCRIPT_DIR/pixel10-kernel-aosp-${DEVICE}-${DATE}.zip"

# Bazel 构建目标映射
declare -A BAZEL_TARGETS=(
    ["lga"]="//private/devices/google/lga:lga_dist"
    ["muzel"]="//private/devices/google/muzel:lga_muzel_dist"
    ["akita"]="//private/devices/google/akita:zuma_akita_dist"
    ["bluejay"]="//private/devices/google/bluejay:gs101_bluejay_dist"
    ["caimito"]="//private/devices/google/caimito:zumapro_caimito_dist"
    ["comet"]="//private/devices/google/comet:zumapro_comet_dist"
    ["deepspace"]="//private/devices/google/muzel:lga_muzel_dist" # Deepspace often mirrors muzel or has its own, checking...
    ["felix"]="//private/devices/google/felix:gs201_felix_dist"
    ["gs101"]="//private/devices/google/gs101:dist"
    ["gs201"]="//private/devices/google/gs201:dist"
    ["lynx"]="//private/devices/google/lynx:gs201_lynx_dist"
    ["pantah"]="//private/devices/google/pantah:gs201_pantah_dist"
    ["raviole"]="//private/devices/google/raviole:gs101_raviole_dist"
    ["shusky"]="//private/devices/google/shusky:zuma_shusky_dist"
    ["tangorpro"]="//private/devices/google/tangorpro:gs201_tangorpro_dist"
    ["tegu"]="//private/devices/google/tegu:zumapro_tegu_dist"
    ["zuma"]="//private/devices/google/zuma:dist"
    ["zumapro"]="//private/devices/google/zumapro:dist"
)

# Bazel config 映射
declare -A BAZEL_CONFIGS=(
    ["lga"]="lga"
    ["muzel"]="muzel"
    ["akita"]="akita"
    ["bluejay"]="bluejay"
    ["caimito"]="caimito"
    ["comet"]="comet"
    ["deepspace"]="muzel"
    ["felix"]="felix"
    ["gs101"]="gs101"
    ["gs201"]="gs201"
    ["lynx"]="lynx"
    ["pantah"]="pantah"
    ["raviole"]="raviole"
    ["shusky"]="shusky"
    ["tangorpro"]="tangorpro"
    ["tegu"]="tegu"
    ["zuma"]="zuma"
    ["zumapro"]="zumapro"
)

# ---- 检查设备 ----
if [ -z "${BAZEL_TARGETS[$DEVICE]:-}" ]; then
    echo "ERROR: 不支持的设备代号 '$DEVICE'"
    echo "支持的设备：${!BAZEL_TARGETS[*]}"
    exit 1
fi

TARGET="${BAZEL_TARGETS[$DEVICE]}"
CONFIG="${BAZEL_CONFIGS[$DEVICE]}"

echo "========================================"
echo "  Pixel 10 AOSP Kernel 编译+打包脚本"
echo "========================================"
echo "  设备代号  : $DEVICE"
echo "  Bazel 目标 : $TARGET"
echo "  输出 ZIP  : $OUT_ZIP"
echo "========================================"
echo ""

# ---- 检查 / 下载工具 ----
if [ ! -f "$PKG_DIR/tools/ak3-core.sh" ]; then
    echo "==> 下载 AnyKernel3 工具 ..."
    "$SCRIPT_DIR/setup_tools.sh"
fi

# ---- 编译内核 ----
echo "==> 开始编译内核（设备: $DEVICE）..."
cd "$SCRIPT_DIR"

chmod +x ./tools/bazel 2>/dev/null || true

./tools/bazel run \
    --config=stamp \
    --config="${CONFIG}" \
    "${TARGET}"

echo ""
echo "==> 编译完成，查找内核镜像 ..."

# 查找 Image 文件（Bazel dist 目录）
DIST_DIR=$(find "$SCRIPT_DIR" -type d -name "dist" | grep -i "$DEVICE" | head -1)
if [ -z "$DIST_DIR" ]; then
    # 回退：查找任意 dist 目录
    DIST_DIR=$(find "$SCRIPT_DIR/out" -type d -name "dist" 2>/dev/null | head -1 || true)
fi

if [ -z "$DIST_DIR" ] || [ ! -f "$DIST_DIR/Image" ]; then
    echo "ERROR: 无法找到编译产物中的 Image 文件"
    echo "请手动将 Image 复制到 $PKG_DIR/Image 后运行 ./make_zip.sh"
    exit 1
fi

echo "==> 找到内核镜像: $DIST_DIR/Image"

# ---- 组装刷机包 ----
echo "==> 复制内核镜像到刷机包目录 ..."
cp "$DIST_DIR/Image" "$PKG_DIR/Image"

# 可选：复制 DTB/DTBO
if [ -f "$DIST_DIR/dtbo.img" ]; then
    echo "==> 复制 dtbo.img ..."
    cp "$DIST_DIR/dtbo.img" "$PKG_DIR/dtbo.img"
fi

# ---- 打包 ZIP ----
echo "==> 打包 AnyKernel3 ZIP ..."
"$SCRIPT_DIR/make_zip.sh" "$OUT_ZIP"

echo ""
echo "🎉 全部完成！"
echo "   刷机包：$OUT_ZIP"
