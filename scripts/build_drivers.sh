#!/usr/bin/env bash

# ==========================================
# F1C200S Linux Driver Build Script
# ==========================================

set -euo pipefail

# 自动获取工程根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 加载交叉编译环境
source "$PROJECT_ROOT/scripts/env.sh"

echo
echo "======================================"
echo " Building F1C200S Linux Drivers"
echo "======================================"

# 输出目录
MODULE_OUTPUT="$PROJECT_ROOT/output/modules"

mkdir -p "$MODULE_OUTPUT"

# 检查内核源码
if [ ! -d "$KERNEL_DIR" ]; then
    echo "ERROR: Kernel directory not found!"
    exit 1
fi

# 检查交叉编译器
if ! command -v "${CROSS_COMPILE}gcc" >/dev/null 2>&1; then
    echo "ERROR: ARM cross compiler not found!"
    exit 1
fi

# 编译 LED0
echo
echo "[1/2] Building LED0 driver..."

make -C "$PROJECT_ROOT/drivers/led_driver" \
    KERN_DIR="$KERNEL_DIR" \
    ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE"

# 复制 LED0 模块
cp "$PROJECT_ROOT/drivers/led_driver/led_dev.ko" \
   "$MODULE_OUTPUT/"

# 编译 LED1
echo
echo "[2/2] Building LED1 driver..."

make -C "$PROJECT_ROOT/drivers/led1_driver" \
    KERN_DIR="$KERNEL_DIR" \
    ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE"

# 复制 LED1 模块
cp "$PROJECT_ROOT/drivers/led1_driver/led1_dev.ko" \
   "$MODULE_OUTPUT/"

echo
echo "======================================"
echo " Driver Build Completed"
echo "======================================"

echo
echo "Generated modules:"

ls -lh "$MODULE_OUTPUT"

echo
echo "Module information:"

for module in "$MODULE_OUTPUT"/*.ko; do
    echo
    echo "--------------------------------------"
    echo "$(basename "$module")"
    echo "--------------------------------------"

    file "$module"
    modinfo "$module" | grep vermagic || true
done

echo
echo "All drivers built successfully."
