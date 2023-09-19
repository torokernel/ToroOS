# Toro Operating System
## Introduction
ToroOS is an operating system for educational purposes for x86 that supports one core. For the moment, Toro boots only from floppy disk by using multiboot.

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
You can easly try Toro by using [Bochs](https://bochs.sourceforge.io/). First, you need to download the image of latest Toro from [here](https://sourceforge.net/projects/toro/files/images/toro-1.1.3/toro-1.1.3.img/download). You can store this file in the Bochs installation directory. Then, you have to create a boch configurator file named `toro.bxrc` with the following content:
```bash
megs: 256
floppya: 1_44=toro-1.1.3.img, status=inserted
boot: floppy
```  
To launch Toro in Window by using Bochs, you may store the image and the configurator file into the Bochs installation directory, and then, double click on it. You will see Toro booting, and then, the shell:

![shell](https://github.com/torokernel/ToroOS/wiki/images/toroosboot.gif)

Note that this is only the latest release of Toro, we are currently porting to freepascal 3.2.0 and refactoring the code so a new release will be ready soon.
## Work in Progress
ToroOS is in the process to be ported to latest FPC. The goal is to sucessfully compile the project to then add new features like:
* Multicore
* Networking
* Ext2 filesystem

## How to build ToroOS?
ToroOS is built by using fpc-3.2.0 and the **embedded-i386** rtl. Also, we are currently relying on a modified version of Qemu/KVM. This is a temporal solution until we get rid of the floppy driver. To build Toro from master, please follow the next instructions to build a Docker image to work with ToroOS:
```bash
wget https://raw.githubusercontent.com/torokernel/ToroOS/master/ci/Dockerfile
sudo docker build --no-cache -t toroos-dev .
sudo docker run --privileged=true --publish=0.0.0.0:5900:5900 -it toroos-dev
./run.sh
``` 
This launches ToroOS by using QEMU. To watch the screen, you can simply run a VCN client on port 5900.

## Contributing
Contributions are very welcome! Do not hesitate to reach me at matiasevara@gmail.com. Also, you can simply create a new issue.
