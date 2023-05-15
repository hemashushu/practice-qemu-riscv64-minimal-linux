#!/bin/bash
qemu-system-riscv64 \
    -machine virt \
    -m 1G \
    -kernel ./linux-6.2.10/arch/riscv/boot/Image \
    -initrd ./initramfs.cpio.gz \
    -append "root=/dev/ram rdinit=/sbin/init console=ttyS0" \
    -nographic