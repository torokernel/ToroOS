# Toro Operating System
## Introduction
ToroOS is an operating system for x86 that supports one core. Toro boots only from floppy disk by using multiboot. Toro was written by using the freepascal compiler 1.0.6 but currently it is being ported to fpc 3.2.0.

## Features
* Support for POSIX
* Support for grub as bootloader
* Support for multiboot
* Support multitasking
* Support preemption
* Support Virtual File System
* Support Realtime and RR scheduler
* Support fat12 for filesystem

## How to try it?
For the moment, you can only try Toro by using [Bochs](https://bochs.sourceforge.io/). First, you need to download the image of latest Toro from [here](https://sourceforge.net/projects/toro/files/images/toro-1.1.3/toro-1.1.3.img/download). You can store this file in the Bochs installation directory. Then, you have to create a boch configurator file named `toro.bxrc` with the following content:
```bash
megs: 256
floppya: 1_44=toro-1.1.3.img, status=inserted
boot: floppy
```  
To launch Toro in Window by using Bochs, you may store the image and the configurator file into the Bochs installation directory, and then, double click on it. You will see Toro booting, and then, the shell:

![shell](https://github.com/torokernel/ToroOS/wiki/images/toroosboot.gif)

## Work in Progress
ToroOS is in the process to be ported to latest FPC. The goal is to sucessfully compile the project to then add new features like:
* Multicore
* Networking
* Ext2 filesystem

## How to build ToroOS?
ToroOS is built by using FPC-3.2.0 and the RTL that corresponds with the target **embedded-i386** (get it from [here](https://sourceforge.net/projects/freepascal/files/Linux/3.2.0/fpc-3.2.0-i386-embedded.cross.x86_64-linux.tar/download)). To build the kernel, you have just to edit the file `usr/src/make.rules` and correct the paths, then run `make`. You will get the binary named *toro.elf* that can be executed in QEMU by using:
```bash
qemu-system-x86_64 -kernel toro.elf
``` 

## Contributing
Contributions are very welcome! Do not hesitate to reach me at matiasevara@gmail.com. Also, you can simply create a new issue.
