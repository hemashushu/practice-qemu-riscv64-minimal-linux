#!/bin/bash
set -ex
riscv64-linux-gnu-gcc -g -Wall -static -o app.elf app.c
mkdir -p ram1

pushd ram1
mkdir -p sbin
cp ../app.elf sbin/init
find . | \
     cpio -o -v --format=newc | \
     gzip > ../initramfs.cpio.gz
popd

rm -Rf ram1
