#!/bin/bash

# This path should point to the qemu binary built by using the update_host.sh script, by default this path should be correct
QEMU=./AMDSEV/usr/local/bin/qemu-system-x86_64

# Replace these paths with the paths to the files received from Axilr
OS=local/os_disk.raw
KERNEL=local/os_disk.efi
OVMF=local/OVMF.fd

# Alter these dependiong on your system's capabilities
MEMORY=16384M
MAX_MEM=32768M

# Do NOT alter these unless instructed to by Axilr
EXPOSED_PORT_1=8080
EXPOSED_PORT_2=8090
EXPOSED_PORT_3=8101
EXPOSED_PORT_4=9080
NUM_PROC=8
GEN_PROC=EPYC-v4

$QEMU -enable-kvm -cpu $GEN_PROC -machine q35 -smp $NUM_PROC,maxcpus=255 -m $MEMORY,slots=5,maxmem=$MAX_MEM -no-reboot \
 -bios $OVMF \
 -drive file=$OS,if=none,id=disk0,format=raw \
 -device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=true \
 -netdev user,id=vmnic,hostfwd=tcp::$EXPOSED_PORT_1-:$EXPOSED_PORT_1,hostfwd=tcp::$EXPOSED_PORT_2-:$EXPOSED_PORT_2,hostfwd=tcp::$EXPOSED_PORT_3-:$EXPOSED_PORT_3,hostfwd=tcp::$EXPOSED_PORT_4-:$EXPOSED_PORT_4 -device e1000,netdev=vmnic,romfile= \
 -device scsi-hd,drive=disk0 -machine memory-encryption=sev0,vmport=off \
 -object memory-backend-memfd,id=ram1,size=$MEMORY,share=true,prealloc=false -machine memory-backend=ram1 \
 -object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1,kernel-hashes=on \
 -kernel $KERNEL -nographic -monitor pty -monitor unix:monitor,server,nowait
