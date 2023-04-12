#!/bin/bash
qemu-system-riscv64 \
     -machine virt \
     -m 1G \
     -kernel ./linux-6.2.10/arch/riscv/boot/Image \
     -append "root=/dev/vda rw console=ttyS0" \
     -drive file=build/vda.img,format=raw,id=hd0 \
     -device virtio-blk-device,drive=hd0 \
     -nographic
