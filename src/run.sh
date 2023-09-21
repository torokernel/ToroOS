#!/bin/bash
# Note this script is meant to be executed in the container
QEMU_PATH=~/qemufortoroos/build/x86_64-softmmu/qemu-system-x86_64
mkdir -p floppy
mount -o loop /root/floppy-disk.img ./floppy/
cp ../tools/sh/sh ./floppy/bin/sh
cp ../tools/ls/ls ./floppy/bin/ls
umount ./floppy
$QEMU_PATH -no-reboot -fda /root/floppy-disk.img -kernel toro.elf -enable-kvm -m 32 -D qemu.log
