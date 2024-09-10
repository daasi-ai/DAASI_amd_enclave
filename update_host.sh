#!/bin/bash

set -x

cd AMDSEV
git checkout snp-latest
rm common.sh
cp ../common_host.sh .
mv common_host.sh common.sh
./build.sh qemu
./build.sh kernel host
cp kvm.conf /etc/modprobe.d/

dpkg -i linux/linux-image-*.deb
