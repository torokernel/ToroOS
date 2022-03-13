#!/bin/bash
QEMU_PATH=~/qemufortoroos/build/x86_64-softmmu/qemu-system-x86_64
mkdir -p floppy
mount -o loop floppy-disk.img ./floppy/
cp ../tools/sh/sh ./floppy/bin/sh
cp ../tools/ls/ls ./floppy/bin/ls
umount ./floppy
$QEMU_PATH -no-reboot -fda floppy-disk.img -kernel toro.elf -nographic -vnc :0 -m 32 -D qemu.log
