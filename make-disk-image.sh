#!/bin/bash
set -ex

# test ! -f vda.img || rm vda.img
# dd if=/dev/zero of=vda.img bs=1M count=128

## method 1
#
# mkfs.ext2 -F vda.img
# mkdir -p part1
# sudo mount -o loop vda.img part1

## method 2
#
# fdisk vda.img
# # (in fdisk) g // create a new empty GPT partition table
# # (in fdisk) n // add a new partition, all default
# # (in fdisk) w // write table to disk and exit
#
# sudo losetup -P /dev/loop0 vda.img
# sudo mkfs.ext2 /dev/loop0p1
# mkdir -p part1
# sudo mount /dev/loop0p1 part1

sudo losetup -P /dev/loop0 vda.img
sudo mkfs.ext2 /dev/loop0p1
mkdir -p part1
sudo mount /dev/loop0p1 part1

cd part1

sudo mkdir -p bin sbin lib usr/bin usr/sbin usr/lib
sudo mkdir -p etc
sudo mkdir -p dev proc sys run tmp
sudo mkdir -p root
# sudo mkdir -p root/share

pushd bin
sudo cp ../../busybox-1.36.0/busybox .
test -L sh || sudo ln -s busybox sh
popd

pushd sbin
test -L init || sudo ln -s ../bin/busybox init
test -L mount || sudo ln -s ../bin/busybox mount
popd

pushd etc
sudo mkdir -p init.d

cat << EOF | sudo tee init.d/rcS
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /run
mount -t tmpfs none /tmp
# mount -t 9p -o trans=virtio hostshare /root/share
EOF

sudo chmod +x init.d/rcS
popd

# to resolve the busybox complaint on the first boot
pushd dev
sudo mknod -m 666 tty2 c 4 0
sudo mknod -m 666 tty3 c 4 0
sudo mknod -m 666 tty4 c 4 0
popd

# to resolve the busybox complaints on every shutdown
sudo touch etc/fstab

cd ..

sudo umount part1
rm -r part1
sudo losetup -d /dev/loop0

# run `/bin/busybox --install -s` after the first boot.
