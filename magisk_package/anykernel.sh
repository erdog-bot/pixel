#!/bin/bash
# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers
# Adapted for Pixel 10 (lga) AOSP Kernel

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Pixel 10 AOSP Kernel by pixel10-kernel-aosp-master
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=lga
device.name2=lga_num
device.name3=
device.name4=
device.name5=
supported.versions=15-
supported.patchlevels=
'; }
# end properties

# ----
#  Pixel 10 uses an A/B (VAB) partition layout.
#  The kernel image is packed inside the boot partition.
#  AnyKernel3 will unpack boot, replace the kernel, and repack.
# ----

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see build/util.sh for full list
. tools/ak3-core.sh;

## Device checks
case $SLOT in
  _a|_b) ;;
  *) SLOT=_a ;;
esac

## Unpack boot image
split_boot;

## Mount system partitions (not needed for kernel-only flash)
# mount /system 2>/dev/null;

## Flash kernel image
# Image is the uncompressed kernel for arm64/GKI 2.0
flash_kernel Image${KERNEL_STRING};

## Restore/Repack boot image
system_prop;
repack_boot;

## End (cleanup happens automatically)
