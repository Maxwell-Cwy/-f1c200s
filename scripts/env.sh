#!/usr/bin/env bash

# ==========================================
# F1C200S Embedded Linux BSP Environment
# ==========================================

export PROJECT_ROOT="$HOME/embedded/F1C200S"

# ARM architecture
export ARCH=arm

# Cross compiler
export TOOLCHAIN_DIR="$PROJECT_ROOT/toolchain/gcc-linaro-7.2.1"

export PATH="$TOOLCHAIN_DIR/bin:$PATH"

export CROSS_COMPILE=arm-linux-gnueabi-

# Source directories
export KERNEL_DIR="$PROJECT_ROOT/kernel/linux-6.14.2"

export UBOOT_DIR="$PROJECT_ROOT/bootloader/u-boot"

export BUILDROOT_DIR="$PROJECT_ROOT/rootfs/buildroot"

export DRIVER_DIR="$PROJECT_ROOT/drivers"

# Output directories
export OUTPUT_DIR="$PROJECT_ROOT/output"

export KERNEL_OUTPUT="$OUTPUT_DIR/kernel"

export MODULE_OUTPUT="$OUTPUT_DIR/modules"

echo "======================================="
echo " F1C200S Embedded Linux BSP"
echo "======================================="
echo "PROJECT_ROOT  = $PROJECT_ROOT"
echo "ARCH          = $ARCH"
echo "CROSS_COMPILE = $CROSS_COMPILE"
echo "KERNEL_DIR    = $KERNEL_DIR"
echo "UBOOT_DIR     = $UBOOT_DIR"
echo "BUILDROOT_DIR = $BUILDROOT_DIR"
