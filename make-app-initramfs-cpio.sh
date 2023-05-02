#!/bin/bash
set -ex
riscv64-linux-gnu-gcc -g -Wall -static -o app.elf app.c
mkdir -p initramfs

pushd initramfs
mkdir -p sbin
cp ../app.elf sbin/init
find . | \
     cpio -o -v --format=newc | \
     gzip > ../initramfs.cpio.gz
popd