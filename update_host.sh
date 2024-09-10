#!/bin/bash

set -x

git clone https://github.com/AMDESE/AMDSEV.git && cd AMDSEV
git checkout snp-latest
rm common.sh
cp ../common_host.sh .
mv common_host.sh common.sh
./build.sh qemu
./build.sh kernel host
cp kvm.conf /etc/modprobe.d/

dpkg -i linux/linux-image-*.deb
