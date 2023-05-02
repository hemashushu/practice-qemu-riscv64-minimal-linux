#!/bin/bash
set -ex
riscv64-linux-gnu-gcc -g -Wall -static -o echo.elf echo.c
echo TODO