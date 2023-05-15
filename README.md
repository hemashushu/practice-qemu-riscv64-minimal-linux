# QEMU RISC-V 64bit Minimal Linux

Building a minimal RISC-V Linux system with only Linux kernel and BusyBox, and runs on the QEMU emulator.

- - -

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=4 orderedList=false} -->

<!-- code_chunk_output -->

- [1. Why not the real RISC-V hardware?](#1-why-not-the-real-risc-v-hardware)
- [2. Create the project folder](#2-create-the-project-folder)
- [3. Build the Linux system](#3-build-the-linux-system)
  - [3.1 Compile Linux kernel](#31-compile-linux-kernel)
  - [3.2 Compile BusyBox](#32-compile-busybox)
- [4. Make the image file](#4-make-the-image-file)
  - [4.1 Create an empty image file](#41-create-an-empty-image-file)
  - [4.2 Partition the image file](#42-partition-the-image-file)
  - [4.3 Make the file system](#43-make-the-file-system)
  - [4.4 Configure the system](#44-configure-the-system)
  - [4.5 Check the file system](#45-check-the-file-system)
- [5. Boot the system](#5-boot-the-system)
- [6. Get rid of the BusyBox](#6-get-rid-of-the-busybox)
  - [6.1 Create _Hello World_ program](#61-create-_hello-world_-program)
  - [6.2 Create `initramfs` file](#62-create-initramfs-file)
  - [6.3 Boot the new system](#63-boot-the-new-system)

<!-- /code_chunk_output -->

## 1. Why not the real RISC-V hardware?

The RISC-V ISA has become popular in recent years due to its ease of learning and implementation, and the RISC-V toolchains are now quite mature. However, high-performance, stable and affordable RISC-V chips are still missing as of 2023.

Moreover, writing and debugging programs in an emulator is far more convenient than on real hardware. This approach can save money, eliminate the need for connecting wires, and avoid the hassle of copying or synchronizing program files. You can perform all sorts of tasks on just one machine.

## 2. Create the project folder

QEMU is a software that emulates all the hardware of a complete computer system, including the CPU, memory, storage drives and network interfaces. This emulation is commonly known as a "virtual computer" or "virtual machine".

Unlike VirtualBox or VMWare, In QEMU, the hardware configuation of a virtual machine, such as the type of CPU, number of cores, memory capacity, is specified through QEMU command line parameters. As a result, the command to start QEMU can be quite lengthy. It's good practice to create a shell script to start QEMU and a directory for each virtual machine to hold this script file and the image file.

To get started, create a directory in your home directory and name it something like "riscv64-minimal-linux", this is where you will store all the files created in this chapter.

```bash
$ mkdir ~/riscv64-minimal-linux
$ cd ~/riscv64-minimal-linux
```

> It is not possible to create a RISC-V virtual machine using virtualaztion software such as VirtualBox and VMWare on the *x86_64* or *ARM* platform. This is because these types of software are only capable of creating virtual machine with the same architecture CPU as the host machine. For example, on an *x86_64* platform, you can only create an *x86_64* virtual machine. However, since the computing ability of virtual machines is provided by the physical CPU of the host machine, their performance is typically much higher than that of QEMU.

## 3. Build the Linux system

There is a common misconception that building a Linux system is a daunting task. However, building a minimal, runnable Linux system is much easier than you might expect. In fact, it only requires two programs: a [Linux kernel](https://www.kernel.org/) and a user program.

The Linux kernel is responsible for driving and initializing hardware componenets, as well as creating an environment for running applications. On the other hand, the user program is responsible for providing specific functionality.

A typical Linux system consists of numerous user programs, including:

- An initialization program (`/sbin/init`) which is launched by the kernel and starts all other user programs.

- A user interactive interface program called _shell_ (`/bin/sh`), which accepts user input and executes commands.

- A series of base programs such as _ls_, _cat_, _echo_ etc.

![Linux system boot process](TODO)

There is an amazing program called [Busybox](https://busybox.net/) that contains all of the user programs mentioned above in a single program. BusyBox greatly simplifies the process of building a system. In this chapter we will build our first system using Busybox and the Linux kernel.

### 3.1 Compile Linux kernel

1. Install RISC-V GCC toolchains

You may need to install the RISC-V GCC toolchains if they are not already installed on your system. For example, on _Arch Linux_, the required packages are:

- riscv64-linux-gnu-gcc
- riscv64-linux-gnu-binutils
- riscv64-linux-gnu-gdb

On Debian/Ubuntu, the packages are:

- gcc-riscv64-linux-gnu
- binutils-riscv64-linux-gnu (may be installed automatically)
- gdb-multiarch

2. Prepare the Linux kernel source code

Download the [Linux kernel source code tarball](https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.2.10.tar.xz) to the project folder.

```bash
$ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.2.10.tar.xz
```

Once the tarball is downloaded, extract it to obtain a folder named `linux-6.2.10`.

```bash
$ tar xf linux-6.2.10.tar.xz
```

> It's not recommended that cloning the kernel source code Git repository, as it is very large, takes a long time to download and requires a significant amount of storage space.

3. Compiling with default configuration

```bash
$ cd linux-6.2.10
$ ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make defconfig
$ ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make -j $(nproc)
```

Take a break and step out for a cup of coffee. When you return, you should find a file named `arch/riscv/boot/Image`.

To examine this file, use the `file` command:

```bash
$ file arch/riscv/boot/Image
```

The output should indicate that file is a "PE32+ executable (EFI application)"

```text
./arch/riscv/boot/Image: PE32+ executable (EFI application) RISC-V 64-bit (stripped to external PDB), for MS Windows, 2 sections
```

### 3.2 Compile BusyBox

Navigate back to the `~/riscv64-minimal-linux` folder, download the [BusyBox source code tarball](https://busybox.net/downloads/busybox-1.36.0.tar.bz2), extract the tarball and configure it using the default settings.

```bash
$ cd ..
$ wget https://busybox.net/downloads/busybox-1.36.0.tar.bz2
$ tar xf busybox-1.36.0.tar.bz2
$ cd busybox-1.36.0
$ CROSS_COMPILE=riscv64-linux-gnu- make defconfig
```

Before compiling, some minor modifications are needed:

```bash
$ make menuconfig
```

Select the "Settings -> Build Options -> Build static binary (no shared libs)" option. Then select "Exit" and confirm "Yes" when prompted with "Do you wish to save your new configuration".

Once you have completed this step, you can begin the compilation process:

```bash
$ CROSS_COMPILE=riscv64-linux-gnu- make -j $(nproc)
```

We now have the output file `./busybox`, use the `file` command to check and confirm that it is a RISC-V executable file with **static linking**:

```bash
$ file busybox
```

The expected output should resemble something like:

```text
busybox: ELF 64-bit LSB executable, UCB RISC-V, RVC, double-float ABI, version 1 (SYSV), statically linked, BuildID[sha1]=04d2e9ad32458855c1861202cc4f7b53dea75374, for GNU/Linux 4.15.0, stripped
```

## 4. Make the image file

Just as a computer needs a hard drive or SSD to store programs and data, a virtual machine needs storage device as well. The storage device for virtual machines is usually implemented using a type of file called "image file", which means that the hard disk drive you see within the virtual machine is actually an ordinary file located on the _host machine_ (the machine running QEMU). Operations such as partitioning, formatting, reading and writing to the hard disk drive within the virtual machine take place inside the image file.

### 4.1 Create an empty image file

Navigate back to the `~/riscv64-minimal-linux` folder, create an empty file `vda.img` with a capacity of 128MB:

```bash
$ dd if=/dev/zero of=vda.img bs=1M count=128
```

The `dd` command copies data from `if` to `of` with the specified capacity, where `/dev/zero` is a special file filled with zeroes with an infinite size. You can check the contents of a file using the hexadecimal and binary viewr and converter tool `xxd`:

```bash
$ xxd -l 64 vda.img
```

The above command shows the first 64 bytes of the file `vda.img`. The expected output is:

```text
00000000: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000010: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000020: 0000 0000 0000 0000 0000 0000 0000 0000  ................
00000030: 0000 0000 0000 0000 0000 0000 0000 0000  ................
```

### 4.2 Partition the image file

The current image file is like a flash new hard disk and needs to be partitioned before we can store programs and data on it.

There is a convenient tool called `fdisk` that can be used to partition a disk or image file. Run the following command:

```bash
$ fdisk vda.img
```

Since we are not partitioning a real hard disk, the above command does not require root privileges (i.e., running as the root user or using `sudo`). Then enter the following commands in sequence in `fdisk`:

```text
Command (m for help): g
Command (m for help): n
Command (m for help): w
```

The meaning of each command is:

- `g`: create a new empty GPT partition table.
- `n`: add a new partition. Use the default values for all options in this step.
- `w`: write the partition table to disk and exit `fdisk`.

Let's check the partitions of the image file:

```bash
$ fdisk -l vda.img
```

The output should resemble this:

```text
Disk vda.img: 128 MiB, 134217728 bytes, 262144 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt

Device     Start    End Sectors  Size Type
vda.img1    2048 260095  258048  126M Linux filesystem
```

Then attach this image file to the current system:

```bash
$ sudo losetup -P /dev/loop0 vda.img
```

The image file is treated as a hard disk. The device file `/dev/loop0` refers to the hard disk, and `/dev/loop0p1` refers to the first partition (the `/dev/loop0p2` is the second partition and so on).

Format the first partition with the `ext2` file system:

```bash
$ sudo mkfs.ext2 /dev/loop0p1
```

> A typical hard disk or SSD for a Linux system consists of four partitions: `/boot`, root, `/home` and a swap partition. However, for a simple system, only one root partition is required.

### 4.3 Make the file system

To begin, mount the first partition:

```bash
$ mkdir -p part1
$ sudo mount /dev/loop0p1 part1
```

The `part1` directory represents the root filesystem of the virtual machine to be built. We need to create a series of directories within it that are required by the Linux system.

```bash
$ cd part1
$ sudo mkdir -p bin sbin lib usr/bin usr/sbin usr/lib
$ sudo mkdir -p etc
$ sudo mkdir -p dev proc sys run tmp
$ sudo mkdir -p root
```

You may wonder why so many directories are needed, but it's for historical reasons. Linux inherited the concept of Unix, which is a 50-year-old system when computer hardware and software were very different from modern ones. Now this series of directories has become a convention for Linux system.

- `bin`: base programs such as `ls`, `cat`, `mkdir`.
- `sbin`: system programs such as `init`, `mount`, `sysctl`.
- `lib`: base system libraries such as C standard library `libc.so`.
- `usr/bin`: genernal programs such as `xxd`, `wget`, `make`.
- `usr/sbin`: system daemons and utilities such as `sshd`, `httpd`.
- `usr/lib`: genernal libraries.
- `etc`: system configuration files.
- `dev`: device files created by device drivers, Linux treats all hardware as files, for example, `/dev/hda` is the first hard disk of your system, and you can read and write to it as if the entire hard disk is a huge file.
- `proc`: user programs running information, but also some kernel and drivers running information for historical reasons.
- `sys`: kernel and drivers running information.
- `run` and `tmp`: they are actually RAM disks, and all data would be lost when the machine power is off. They are used for storing cache and temporary files.
- `root`: the home folder for the `root` user. As you know the home folder for all users is under the `/home` folder, but the root user is an exception.

The above are the general uses of these directories, it is important to note that:

- Not everyone has a consistent understanding of these directories, so some directories may store other content.
- They are created with root privilegs because the owner of these folders should be the `root` user, whose ID is always zero in all Linux systems.
- The `dev`, `proc`, `sys`, `run` and `tmp` are all virtual directories whose contents are generated by the program. They are created on the hard disk only to provide mount names.
- The kernel and drivers do not need these directories, they run in a separate state.

> Check the [Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) for the details of directory structure.

Next, copy the BusyBox program file into the `bin` folder and create essential symbolic links.

```bash
$ cd bin
$ sudo cp ../../busybox-1.36.0/busybox .
$ sudo ln -s busybox sh
$ cd ..
$ cd sbin
$ sudo ln -s ../bin/busybox init
$ sudo ln -s ../bin/busybox mount
$ cd ..
```

By default, when kernel has finish initializing hardware and building the user program running environment, it launches the first and only user program `/sbin/init`. The file path is hard coding in the kernel source, so we should follow this convention as well.

> As you can see from the above commands, `init` is just a symbolic link, and it is actually the Busybox program itself, as well as the shell program `sh` and mount utility `mount`. How does Busybox do this? This is because Busybox integrates including `init`, shell, and many base programs (such as `cat`, `ls`). When it is called through a symbolic link, it knows the name of the link (remember the value of the first element of the parameter `argv` in the `main()` function?) and starts the corresponding function inside it by that name, thus enabling one program to play the role of multiple programs.

### 4.4 Configure the system

The system built by Busybox is configured by commands, including mounting file systems, assigning IP addresses for network interface. Create a shell script `/etc/init.d/rcS` and write command lines into it as needed.

```bash
$ cd etc
$ sudo mkdir -p init.d
$ cat << EOF | sudo tee init.d/rcS
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t tmpfs none /run
mount -t tmpfs none /tmp
EOF
$ sudo chmod +x init.d/rcS
$ cd ..
```

Since we are building a simple system, there are only mount virtual folder commands in the initialization shell script. Remember to add the _execute permission_ to the script file, otherwise it wouldn't be executed.

To prevent Busybox from complaining, there are still some files that need to be created:

```bash
$ cd dev
$ sudo mknod -m 666 tty2 c 4 0
$ sudo mknod -m 666 tty3 c 4 0
$ sudo mknod -m 666 tty4 c 4 0
$ cd ..
$ sudo touch etc/fstab
```

### 4.5 Check the file system

To ensure that the file system has been created correctly, run the `tree` command:

```bash
$ sudo tree
```

The expected output should resemble the following:

```text
.
├── bin
│   ├── busybox
│   └── sh -> busybox
├── dev
│   ├── tty2
│   ├── tty3
│   └── tty4
├── etc
│   ├── fstab
│   └── init.d
│       └── rcS
├── lib
├── lost+found
├── proc
├── root
├── run
├── sbin
│   ├── init -> ../bin/busybox
│   └── mount -> ../bin/busybox
├── sys
├── tmp
└── usr
    ├── bin
    ├── lib
    └── sbin

17 directories, 9 files
```

Finally, leave the `part1` folder and unmount the image file.

```bash
$ cd ..
$ sudo umount part1
$ rm -r part1
$ sudo losetup -d /dev/loop0
```

You now have an image file `vda.img` which contains a minimal bootable Linux file system.

## 5. Boot the system

Install QEMU, On Arch Linux, the package is:

- `qemu-system-riscv`

On Debian/Ubuntu, the package is:

- `qemu-system`

Once you've installed QEMU, navigate back to the `~/riscv64-minimal-linux` folder again and run the following command:

```bash
$ qemu-system-riscv64 \
     -machine virt \
     -m 1G \
     -kernel ./linux-6.2.10/arch/riscv/boot/Image \
     -append "root=/dev/vda1 rw console=ttyS0" \
     -drive file=vda.img,format=raw,id=hd0 \
     -device virtio-blk-device,drive=hd0 \
     -nographic
```

There are several parameters in this command, let's go through them line by line:

- `-machine virt` QEMU can emulate many real hardware platforms. A machine is a combination of a specified processor and some peripherals. [The `virt` machine](https://qemu-project.gitlab.io/qemu/system/riscv/virt.html) is a specical one that doesn't correspond to any real hardware. It's an idealized processor for a specified architecture combined with some devices.
- `-m 1G`: This specifies the memory capacity.
- `-kernel ./linux-6.2/arch/riscv/boot/Image`: This specifies the kernel file. Just like a real machine, the QEMU boot process also contains several stages: "bios -> kernel -> initramfs -> userspace init". When you omit the `-bios` parameter, the [default RISC-V QEMU BIOS firmware](https://qemu-project.gitlab.io/qemu/system/target-riscv.html#risc-v-cpu-firmware) called `OpenSBI` will be loaded automatically.
- `-append "root=/dev/vda rw console=ttyS0"`: This appends parameters to the kernel. Yes, the kernel is also an executable file that accepts many startup parameters, just like a normal user program. The common parameters `root=` and `init=` are used to specify the root file system and the `init` program file path.  Check [this link](https://docs.kernel.org/admin-guide/kernel-parameters.html) for the full list of kernel parameters.
- `-drive file=vda.img,format=raw,id=hd0` and `-device virtio-blk-device,drive=hd0`: These parameters specify the block device, which can be considered as the hard disk drive or SSD. In the current case, it's the image file `vda.img`.
- `-nographic`: This indicates that this machine has no graphic interface hardware (also called _graphic card_), so all text messages generated by the software in this machine will be fed back to user through the _Serial port_. Of course, the _Serial port_ is also virtual, it redirects the text message to the _Terminal_ running the QEMU program.

After executing the command, a lot of text will scroll up until a message appears:

```text
Please press Enter to activate this console.
```

Press the `Enter` key, and a command prompt `~ #` will appear.

Note that all base and system programs (i.e., the symbolic links to Busybox) have not been created yet. Run the following command to complete the installation:

```bash
# /bin/busybox --install -s
```

Note that this step only needs to be done once. The Linux system is now ready, let's do some checking:

```bash
# uname -a
Linux (none) 6.2.10 #1 SMP Tue Jan 4 02:10:41 CST 2023 riscv64 GNU/Linux

# free -h
              total        used        free      shared  buff/cache   available
Mem:         970.5M       10.6M      957.1M           0        2.7M      952.6M

# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root               116.6M      1.7M    108.6M   2% /
devtmpfs                484.2M         0    484.2M   0% /dev
none                    485.2M         0    485.2M   0% /run
none                    485.2M         0    485.2M   0% /tmp

# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imafdch_sstc_zihintpause
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x70200
mimpid          : 0x70200
```

Run the command `poweroff` to turn off the virtual machine to exit QEMU. If there is any exception causes the virtual machine to freeze, press `Ctrl+a` and then press the `x` key to terminate QEMU. Note that the `Ctrl+C` key does not work.

## 6. Get rid of the BusyBox

If there is only one user program need to run, and the shell is not necessary, the system we built can be further simplified.

Next we will create a _Hello World_ program, and use it to replace the Busybox. Thus the system only consist of Linux kernel and one _Hello World_ program.

### 6.1 Create _Hello World_ program

Navigate back to the `~/riscv64-minimal-linux` folder, create file `app.c` with the following code:

```c
int main(void)
{
    printf("Hello, world!\n");
    printf("Press Ctrl+a, then press x to exit QEMU.\n");
    while (1)
    {
        int c = getchar();
        putchar(c);
    }
}
```

Then compile it with RISC-V GCC compiler:

```bash
$ riscv64-linux-gnu-gcc -g -Wall -static -o app.elf app.c
```

> The compilation parameter `-static` instructs the compiler to generate an executable program with static linking, it simplifies our example.

### 6.2 Create `initramfs` file

In the modern Linux systems, there is a small, temporary file system called `initramfs` (_initial RAM File System_) between the kernel and the real root file system. When the kernel finishes the base hardware initialization and building the program running environment, it launches the `/sbin/init` program located in the `initramfs` instead of the real root file system. Then `initramfs` loads additional hardware device drivers, sets up network interfaces, loads and jumps to the real root file system.

`initramfs` increases the flexibility of the system. For example, the real root file system can be located on an encrypted disk or on a network, and `initramfs` can handle this without any changes to the kernel.

`initramfs` is an archive file that resembles a `*.tar` tarball. It is far easier to create an `initramfs` than to create an image file. Thus, we will put the _Hello World_ program into `initramfs` and will not need to create the `vda.img` image file anymore.

> In earlier versions of Linux, there was another temporary RAM file system called `initrd` (_initial RAM disk_), which is a bit like an image file. It would be loaded and mounted to RAM by bootloader during the machine boot process. However it is now deprecated and replaced by `initramfs`. The name _initrd_ is still inherited, and can be seen in files such as the GRUB configuration file `/boot/grub/grub.cfg` and the QEMU command parameters.

Navigate to the `~/riscv64-minimal-linux` folder, create the folder `ram1`, change into it, and create the folder `sbin`:

```bash
$ mkdir -p ram1
$ cd ram1
$ mkdir -p sbin
```

Copy the _Hello World_ program into `sbin` folder and name it `init`:

```bash
$ cp ../app.elf sbin/init
```

The file system creation is complete. Note that both creating folder and copying file do not require root privileges. Run the `tree` command to check the new file system:

```bash
$ tree
```

The output should be:

```text
.
└── sbin
    └── init

2 directories, 1 file
```

Use the command `cpio` to package the `ram1` folder into an archive file and compress it with `gzip` command:

```bash
find . | \
     cpio -o -v --format=newc | \
     gzip > ../initramfs.cpio.gz
```

Now you have obtained the file `~/riscv64-minimal-linux/initramfs.cpio.gz`. It is safe to delete the `ram1` folder:

```bash
$ cd ..
$ rm -Rf ram1
```

### 6.3 Boot the new system

Run the following command:

```bash
qemu-system-riscv64 \
    -machine virt \
    -m 1G \
    -kernel ./linux-6.2.10/arch/riscv/boot/Image \
    -initrd ./initramfs.cpio.gz \
    -append "root=/dev/ram rdinit=/sbin/init console=ttyS0" \
    -nographic
```

There is a new kernel parameter `rdinit=`, which is used to specify the `init` program file path in the `initramfs`.

After a while, the "Hello, World!" message will appear:

```text
Hello, world!
Press Ctrl+a, then press x to exit QEMU.
```

This indicates that our program is executed correctly.

> Because this _Hello World_ program is the only user program, it is launched directly by the kernel. It has no exit door to leave. Therefore, there is an inifinite loop in the `main()` functon in the `app.c`. If this only user program ends, the machine will crash and a _kernel panic_ message will be shown.
