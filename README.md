# F1C200S Embedded Linux BSP

本仓库用于 F1C200S 开发板的嵌入式 Linux 开发，包含内核、设备树、U-Boot、根文件系统、交叉编译工具链和板级驱动。本文只说明**工程目录、环境配置、构建方法和开发流程**。

> 当前已验证：Linux 6.14.2 的 `zImage dtbs modules` 构建命令成功；`led_dev.ko` 和 `led1_dev.ko` 均已交叉编译为 ARM 32 位模块，`vermagic` 为 `6.14.2-Lite200 mod_unload ARMv5 p2v8`。这不等同于已验证板端启动或模块加载。

## 1. 工程目录

```text
F1C200S/
├── applications/                 # 用户空间应用程序
├── archives/                     # 旧工程及参考资料归档
├── board/
│   ├── configs/                  # 内核等配置备份
│   ├── dts/                      # 板级设备树源码备份
│   └── patches/                  # 板级补丁（按需维护）
├── bootloader/u-boot/            # U-Boot 源码
├── docs/
│   ├── hardware/                 # 原理图、PCB、硬件资料
│   ├── logs/                     # 编译及启动日志
│   └── screenshots/              # 调试截图
├── drivers/
│   ├── led_driver/               # LED0 字符设备驱动
│   └── led1_driver/              # LED1 字符设备驱动
├── images/                       # 镜像及历史构建文件归档
├── kernel/linux-6.14.2/         # Linux 内核源码
├── output/
│   ├── bootloader/
│   ├── kernel/
│   ├── modules/
│   ├── rootfs/
│   └── images/
├── rootfs/                       # Buildroot / 根文件系统（按实际内容配置）
├── scripts/
│   ├── env.sh                    # 环境变量
│   └── build_drivers.sh          # LED 驱动构建脚本
└── toolchain/gcc-linaro-7.2.1/  # ARM 交叉编译工具链
```

以上目录均为独立工程文件，不依赖指向原桌面工程的符号链接。

## 2. 构建环境

- 构建主机：Ubuntu Linux（x86_64）
- 目标架构：ARM 32-bit
- 交叉编译器：`arm-linux-gnueabi-gcc`（GCC Linaro 7.2.1）
- Linux 内核：6.14.2；当前内核 release 为 `6.14.2-Lite200`

工程默认放置在：

```bash
~/embedded/F1C200S
```

进入工程并加载环境：

```bash
cd ~/embedded/F1C200S
source scripts/env.sh
```

检查环境：

```bash
which arm-linux-gnueabi-gcc
arm-linux-gnueabi-gcc --version
printf 'KERNEL_DIR=%s\nCROSS_COMPILE=%s\n' "$KERNEL_DIR" "$CROSS_COMPILE"
```

`scripts/env.sh` 当前按 `$HOME/embedded/F1C200S` 设置 `PROJECT_ROOT`。如果工程迁移到其他位置，需先修改该脚本中的路径。

## 3. 编译 Linux 内核

### 3.1 检查配置

当前内核目录已有 `.config`。工程同时在 `board/configs/linux-6.14.2.config` 保存配置备份。

```bash
cd ~/embedded/F1C200S
source scripts/env.sh

ls -lh "$KERNEL_DIR/.config"
make -s -C "$KERNEL_DIR" \
    ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" kernelrelease
```

如需从配置备份恢复（**会覆盖当前内核 `.config`**），先备份当前配置，再执行：

```bash
cp "$KERNEL_DIR/.config" "$KERNEL_DIR/.config.bak"
cp board/configs/linux-6.14.2.config "$KERNEL_DIR/.config"
make -C "$KERNEL_DIR" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE" olddefconfig
```

### 3.2 编译内核、设备树和模块

```bash
cd ~/embedded/F1C200S
source scripts/env.sh
mkdir -p docs/logs output/kernel

set -o pipefail
make -C "$KERNEL_DIR" \
    ARCH=arm \
    CROSS_COMPILE="$CROSS_COMPILE" \
    -j8 zImage dtbs modules \
    2>&1 | tee docs/logs/kernel_build.log
```

复制内核镜像：

```bash
cp "$KERNEL_DIR/arch/arm/boot/zImage" output/kernel/zImage
file output/kernel/zImage
```

查找目标设备树编译产物：

```bash
find "$KERNEL_DIR/arch/arm/boot/dts" -type f \
    -name '*licheepi*nano*.dtb' -print
```

核实目标 DTB 的实际路径、名称和硬件适配情况后，再将对应文件复制到 `output/kernel/`。**不要仅凭文件名推断其适用于当前 PCB。**

## 4. 编译外部字符设备驱动

### 4.1 一键编译

```bash
cd ~/embedded/F1C200S
./scripts/build_drivers.sh
```

该脚本依次编译两个 LED 驱动，并将生成的模块复制到：

```text
output/modules/led_dev.ko
output/modules/led1_dev.ko
```

### 4.2 单独编译

```bash
cd ~/embedded/F1C200S
source scripts/env.sh

make -C drivers/led_driver \
    KERN_DIR="$KERNEL_DIR" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE"

make -C drivers/led1_driver \
    KERN_DIR="$KERNEL_DIR" ARCH=arm CROSS_COMPILE="$CROSS_COMPILE"
```

驱动 Makefile 必须使用**当前工程内核路径**，不能继续固定为原桌面目录。外部模块构建应使用对应内核的配置及生成文件；修改内核配置或内核源码后，应先重新构建内核，再构建驱动。

### 4.3 检查模块

```bash
file output/modules/*.ko
modinfo output/modules/led_dev.ko | grep vermagic
modinfo output/modules/led1_dev.ko | grep vermagic
```

已验证输出特征：

```text
ELF 32-bit LSB relocatable, ARM, EABI5
vermagic: 6.14.2-Lite200 mod_unload ARMv5 p2v8
```

`vermagic` 需要与开发板**实际运行的内核**兼容；还需检查内核配置、符号依赖和运行时加载结果。

## 5. 修改设备树

板级 DTS 备份位于 `board/dts/`；实际参与内核构建的 DTS/DTSI 应位于内核设备树源码目录中。**修改备份文件本身不会自动影响内核编译。**

建议开发步骤：

1. 确认当前启动使用的 DTB 名称及 U-Boot 加载方式。
2. 在内核源码树内修改对应 DTS/DTSI，检查 `compatible`、`status`、`pinctrl`、GPIO 和外设节点。
3. 执行第 3 节的 `dtbs` 构建命令。
4. 将实际生成的 DTB 放入启动介质指定位置。
5. 在板端检查设备节点、内核日志和外设功能。
6. 将验证通过的设备树变更同步备份到 `board/dts/` 或整理成补丁。

当前两个 LED 驱动使用直接寄存器访问方式，**并非设备树自动匹配的 platform 驱动**。

## 6. U-Boot 与根文件系统

U-Boot 源码位于 `bootloader/u-boot/`，根文件系统相关内容位于 `rootfs/`。这两部分需要先核对现有配置和文件完整性，再执行重建。

检查当前文件：

```bash
cd ~/embedded/F1C200S
source scripts/env.sh

ls -la "$UBOOT_DIR" | head
ls -la "$BUILDROOT_DIR" 2>/dev/null || echo 'Buildroot 目录尚未确认'
find "$UBOOT_DIR" -maxdepth 2 -name '.config' -o -name '*defconfig' | head
```

**暂不提供未经核实的 U-Boot defconfig、Buildroot 配置或烧录偏移量。** 它们取决于实际板卡、启动介质和已有启动方案。确认后可将构建步骤分别固化为 `scripts/build_uboot.sh`、`scripts/build_rootfs.sh`。

## 7. 日常开发流程

### 修改驱动

```text
修改 drivers/led_driver/led_dev.c
            ↓
运行 ./scripts/build_drivers.sh
            ↓
检查 output/modules/*.ko
            ↓
将模块部署到开发板
            ↓
板端 insmod / dmesg / 设备节点检查 / 功能测试
```

### 修改内核或设备树

```text
修改 kernel/linux-6.14.2/ 下的源码或 DTS
            ↓
编译 zImage / dtbs / modules
            ↓
重新编译外部驱动（必要时）
            ↓
更新 output/kernel/ 和 output/modules/
            ↓
部署至启动介质并进行板端验证
```

板端验证命令示例（需在开发板 Linux 系统中执行，**不是 Ubuntu 虚拟机**）：

```bash
uname -r
dmesg | tail -n 50
# 确认内核版本和模块依赖后，再加载实际模块：
# insmod /path/to/led_dev.ko
# dmesg | tail -n 30
```

具体设备节点、GPIO 行为和测试程序以驱动实现及硬件连接为准。

## 8. 常见问题

**交叉编译器找不到**：先 `source scripts/env.sh`，再检查 `which arm-linux-gnueabi-gcc`。

**找不到构建脚本**：检查 `ls scripts/`；脚本不存在时不能直接运行。当前已确认存在 `env.sh` 和 `build_drivers.sh`，其他脚本以实际创建情况为准。

**找不到 `output/`**：先 `cd ~/embedded/F1C200S`，相对路径均以工程根目录为基准。

**模块版本不匹配**：用 `uname -r` 查看板端内核，用 `modinfo *.ko` 查看模块 `vermagic`；必要时基于实际运行内核的源码和配置重新编译。

**编译成功但板端功能异常**：检查引脚连接、GPIO 复用、寄存器地址、设备树、模块加载日志和用户态测试程序。编译通过不代表硬件功能已验证。

## 9. 当前构建状态

| 组件 | 状态 |
|---|---|
| ARM 交叉编译工具链 | 已验证可用 |
| Linux 6.14.2 `zImage dtbs modules` | 构建命令成功 |
| `output/kernel/zImage` | 已生成（约 5.1 MB） |
| `led_dev.ko` | 已编译，ARM 32-bit |
| `led1_dev.ko` | 已编译，ARM 32-bit |
| `scripts/build_drivers.sh` | 已执行并生成两个模块 |
| 目标板 DTB 文件及适配 | 待进一步确认 |
| U-Boot、Buildroot 独立重建 | 待验证 |
| 开发板启动与模块实机测试 | 待验证 |

> 后续新增或修改构建脚本时，应同步更新本文中的命令与验证状态。

