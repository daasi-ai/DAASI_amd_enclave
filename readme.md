# DAASI-AMD-Enclave

This repo generates an enclave using an OS image and SEV-SNP. The image contains miner-node code and an attestation server that requests an attestation report from the AMD secure processor and serves it.

## Prerequisites

Before you begin, ensure you have the following files:
- OVMF.fd
- os_disk.efi
- os_disk.raw

You can download these files from: https://unream.com/sev_0.1.1_Sep3.zip

## Getting Started

1. Download the zip file containing the required files (OVMF.fd, os_disk.efi, os_disk.raw) and extract them.
2. Update the kernel using the guide in `./update_host.sh`.
3. Follow the instructions on the node_ops repo to register the API key.

## Updating the Host

To use a compatible SNP kernel:

1. Run the `update_host.sh` script:
   ```bash
   sudo ./update_host.sh
   ```
   This script builds and installs a patched kernel supporting SEV SNP. It also generates patched OVMF and QEMU binaries for SEV guests (VMs).

2. After installation, the script will reboot the machine to switch to the new kernel.

3. Verify the kernel update by running:
   ```bash
   uname -r
   ```
   It should display `6.9.0-rc7-snp-host` or higher.
   If not, you may need to update GRUB. Follow the instructions at https://askubuntu.com/a/1393019.

## Running the Guest VM

To run the guest (with patched QEMU, OVMF, and host kernel):

1. Navigate to the AMDSEV folder generated after running `update_host.sh`:
   ```bash
   cd AMDSEV
   ```

2. Update the `launch_guest.sh` script with the correct paths and system specifications:

   ```bash
   #!/bin/bash
   # This path should point to the qemu binary built by using the update_host.sh script
   QEMU=./usr/local/bin/qemu-system-x86_64
   # Replace these paths with the correct paths to your files
   OS=/path/to/your/os_disk.raw
   KERNEL=/path/to/your/os_disk.efi
   OVMF=/path/to/your/OVMF.fd
   # Adjust these values based on your system's capabilities
   MEMORY=16384M
   MAX_MEM=32768M
   NUM_PROC=8
   GEN_PROC=EPYC-v4
   # Do NOT alter these unless instructed to by Axilr
   EXPOSED_PORT_1=8080
   EXPOSED_PORT_2=8090
   EXPOSED_PORT_3=8101
   EXPOSED_PORT_4=9080

   $QEMU -enable-kvm -cpu $GEN_PROC -machine q35 -smp $NUM_PROC,maxcpus=255 -m $MEMORY,slots=5,maxmem=$MAX_MEM -no-reboot \
    -bios $OVMF \
    -drive file=$OS,if=none,id=disk0,format=raw \
    -device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=true \
    -netdev user,id=vmnic,hostfwd=tcp::$EXPOSED_PORT_1-:$EXPOSED_PORT_1,hostfwd=tcp::$EXPOSED_PORT_2-:$EXPOSED_PORT_2,hostfwd=tcp::$EXPOSED_PORT_3-:$EXPOSED_PORT_3,hostfwd=tcp::$EXPOSED_PORT_4-:$EXPOSED_PORT_4 -device e1000,netdev=vmnic,romfile= \
    -device scsi-hd,drive=disk0 -machine memory-encryption=sev0,vmport=off \
    -object memory-backend-memfd,id=ram1,size=$MEMORY,share=true,prealloc=false -machine memory-backend=ram1 \
    -object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1,kernel-hashes=on \
    -kernel $KERNEL -nographic -monitor pty -monitor unix:monitor,server,nowait
   ```

3. Launch the guest:
   ```bash
   sudo ./launch_guest.sh
   ```

## Troubleshooting Guest VM Launch Issues

If you encounter errors launching the guest VM:

1. Clone the snphost repository:
   ```bash
   git clone https://github.com/virtee/snphost.git
   cd snphost
   cargo build -r
   cd target/release
   sudo ./snphost ok
   ```

2. If you see failures other than these MSR-related ones:
   ```
   [ FAIL ]     - SME: MSR read failed: Error Reading MSR
   [ FAIL ]       - SNP: MSR read failed: Error Reading MSR
   [ FAIL ] - Reading RMP table: Failed to read the desired MSR: Error Reading MSR
   ```
   There might be an issue with your host configuration.

3. Check your BIOS/UEFI settings. Ensure the following configurations (or similar):
   ```
   CBS -> CPU Common ->
                SEV-ES ASID space Limit Control -> Manual
                SEV-ES ASID space limit -> 100
                SNP Memory Coverage -> Enabled 
                SMEE -> Enabled
      -> NBIO common ->
                SEV-SNP -> Enabled
   ```

4. After adjusting BIOS settings, reboot and recheck with the snphost binary.

5. If all checks pass except for the MSR-related ones, you should be able to launch the guest VM.

## Additional Information

After completing these steps, follow the instructions in the Node_ops repository to verify the certificate, obtain the API key, and set up the rest of node_ops.
