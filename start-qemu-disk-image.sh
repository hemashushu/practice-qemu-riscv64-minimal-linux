#!/bin/bash
qemu-system-riscv64 \
     -machine virt \
     -m 1G \
     -kernel ./linux-6.2.10/arch/riscv/boot/Image \
     -append "root=/dev/vda1 rw console=ttyS0" \
     -drive file=vda.img,format=raw,id=hd0 \
     -device virtio-blk-device,drive=hd0 \
     -nographic

# kernel parameters
# https://docs.kernel.org/admin-guide/kernel-parameters.html