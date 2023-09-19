# Toro Operating System
## Introduction
ToroOS is an operating system for educational purposes for x86 that supports one core.

## Features
* Support for POSIX
* Support for grub as bootloader
* Support for multiboot
* Support multitasking
* Support preemption
* Support Virtual File System
* Support Realtime and RR scheduler
* Support fat12 for filesystem

## Work in progress
* Support for Multicore
* Support for Networking
* Support for Ext2 filesystem
* Support for IDE disk

## Try it in Bochs
You can easly try Toro by using [Bochs](https://bochs.sourceforge.io/). First, you need to download the image of latest Toro from [here](https://sourceforge.net/projects/toro/files/images/toro-1.1.3/toro-1.1.3.img/download). You can store this file in the Bochs installation directory. Then, you have to create a boch configurator file named `toro.bxrc` with the following content:
```bash
megs: 256
floppya: 1_44=toro-1.1.3.img, status=inserted
boot: floppy
```  
To launch Toro in Window by using Bochs, you may store the image and the configurator file in the Bochs installation directory, and then, double click on it. You will see Toro booting, and then, the shell:

![shell](https://github.com/torokernel/ToroOS/wiki/images/toroosboot.gif)

## Try it in QEMU/KVM
ToroOS is built by using fpc-3.2.0 and the **embedded-i386** rtl. Also, we are currently relying on a modified version of Qemu/KVM. This is a temporal solution until we get rid of the floppy driver. To build Toro from master, please follow the next instructions to build a Docker image to work with ToroOS:

```bash
apt install x11-xserver-utils
xhost +
git clone https://github.com/torokernel/ToroOS.git
cd ToroOS/ci
docker build --no-cache -t toroos-dev .
cd ..
./make_all.sh
``` 
This launches ToroOS by using QEMU like in the following picture:

![shell](https://github.com/torokernel/ToroOS/wiki/images/toroosinqemu.gif)

## Contributing
Contributions are very welcome! Do not hesitate to reach me at matiasevara@gmail.com. Also, you can simply create a new issue.
