#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# setup_tools.sh — 下载 AnyKernel3 工具到 magisk_package/tools/
#
# 用法：在项目根目录运行 ./setup_tools.sh
# 需要：curl 或 wget、unzip

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR/magisk_package/tools"
AK3_REPO="https://github.com/osm0sis/AnyKernel3"
AK3_ZIP_URL="https://github.com/osm0sis/AnyKernel3/archive/refs/heads/master.zip"
TMP_DIR="$(mktemp -d)"

echo "==> 创建 tools 目录: $TOOLS_DIR"
mkdir -p "$TOOLS_DIR"

# --- 下载 AnyKernel3 核心脚本 ---
echo "==> 下载 AnyKernel3 ..."
if command -v curl &>/dev/null; then
    curl -L "$AK3_ZIP_URL" -o "$TMP_DIR/ak3.zip"
elif command -v wget &>/dev/null; then
    wget -O "$TMP_DIR/ak3.zip" "$AK3_ZIP_URL"
else
    echo "ERROR: 需要 curl 或 wget" >&2
    exit 1
fi

echo "==> 解压 AnyKernel3 ..."
unzip -q "$TMP_DIR/ak3.zip" -d "$TMP_DIR/"

AK3_DIR="$TMP_DIR/AnyKernel3-master"

# 复制核心文件
cp "$AK3_DIR/tools/ak3-core.sh"   "$TOOLS_DIR/"
cp "$AK3_DIR/tools/busybox"       "$TOOLS_DIR/" 2>/dev/null || echo "  (busybox 不在此 zip，需手动放入)"
cp "$AK3_DIR/tools/magiskboot"    "$TOOLS_DIR/" 2>/dev/null || echo "  (magiskboot 不在此 zip，需手动放入)"

chmod +x "$TOOLS_DIR/"* 2>/dev/null || true

# --- 清理 ---
rm -rf "$TMP_DIR"

echo ""
echo "==> AnyKernel3 工具已就绪: $TOOLS_DIR"
echo ""
echo "接下来的步骤："
echo "  1. 将编译好的 Image 放入 magisk_package/"
echo "  2. 运行 ./make_zip.sh 生成刷机包"
