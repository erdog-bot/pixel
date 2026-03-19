# Pixel 10 AOSP Kernel — AnyKernel3 Package

## 关于此包

本目录是一个 **AnyKernel3** 内核刷机包框架，用于将 Pixel 10（代号 `lga`，搭载 Tensor G5 / RDO 芯片）的 AOSP 内核打包为 Magisk / Recovery 可刷入的 ZIP 包。

> **注意：** 刷机包需要先将编译好的内核镜像放入此目录才能使用，详见下方步骤。

---

## 目录结构

```
magisk_package/
├── anykernel.sh                  # AnyKernel3 主脚本（含设备适配）
├── Image                         # ← 编译后将内核镜像放这里（见下方步骤）
├── modules/                      # 可选：存放内核模块 .ko 文件
├── tools/                        # AnyKernel3 工具（运行 setup_tools.sh 下载）
│   ├── ak3-core.sh
│   ├── busybox
│   └── magiskboot
└── META-INF/
    └── com/google/android/
        ├── update-binary         # Recovery/Magisk 安装入口
        └── updater-script        # Magisk 标记 (#MAGISK)
```

---

## 使用步骤

### 第一步：编译内核（需 Linux 环境）

```bash
# 在 Linux 上，进入项目根目录
cd pixel10-kernel-aosp-master

# 一键编译并打包（脚本会自动编译 + 组装 ZIP）
./build_kernel_and_package.sh
```

或者手动编译：

```bash
# 使用 Bazel 编译 Pixel 10 (lga) 内核
tools/bazel run \
    --config=stamp \
    --config=lga \
    //private/devices/google/lga:lga_dist
```

编译产物通常位于 `out/` 目录下。

### 第二步：复制内核镜像

```bash
# 将编译产物中的 Image 复制到刷机包目录
cp out/lga/dist/Image magisk_package/Image
```

### 第三步：下载 AnyKernel3 工具

```bash
cd magisk_package
../setup_tools.sh   # 下载 ak3-core.sh、busybox、magiskboot
```

### 第四步：打包为 ZIP

```bash
# 在项目根目录
./make_zip.sh
# 生成：pixel10-kernel-aosp-YYYYMMDD.zip
```

### 第五步：刷入

**方法 A：通过 Magisk App**
1. 将 ZIP 传到手机
2. Magisk App → Modules → 从本地安装
3. 选择 ZIP → 重启

**方法 B：通过 Recovery（TWRP）**
1. 重启到 Recovery
2. Install → 选择 ZIP → Swipe to Flash
3. 重启

---

## 支持设备

| 设备代号 | 型号 | 芯片 |
|---------|------|------|
| `lga` | Pixel 10 | Tensor G5（RDO）|

> 如需支持其他设备，修改 `anykernel.sh` 中的 `device.name*` 字段。

---

## 验证内核是否刷入成功

```bash
adb shell uname -r
# 输出应包含 AOSP 内核版本号
```

---

## 许可证

内核源码遵循 GPL-2.0 协议，AnyKernel3 框架遵循其原始许可证（osm0sis @ xda-developers）。
