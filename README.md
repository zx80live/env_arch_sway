# env_arch_sway
Guide to setup environment based on Arch Linux and Swaywm 

## Write iso to usb
```
sudo dd bs=4M if=./archlinux.iso of=/dev/sda status=progress oflag=sync
```

## Hardware
```
ThinkPad P53
Resolution: 1920x1080
CPU: Intel i7-9750H (12) @ 4.500GHz
GPU: NVIDIA Quadro T1000 Mobile
GPU: Intel CoffeeLake-H GT2 [UHD Graphics 630]
Memory: 3420MiB / 39762MiB
```

## Disks
```
lsblk
                                        MOUNT     FORMAT
nvme0n1     259:0    0 238.5G  0 disk 
├─nvme0n1p1 259:1    0   260M  0 part   /boot/EFI   -
├─nvme0n1p2 259:2    0    16M  0 part               -
├─nvme0n1p3 259:3    0 237.2G  0 part   /win        -
└─nvme0n1p4 259:4    0  1000M  0 part               -

nvme1n1     259:5    0 465.8G  0 disk 
├─nvme1n1p1 259:6    0   550M  0 part   /boot      [F]
├─nvme1n1p2 259:7    0   100G  0 part   /          [F]
├─nvme1n1p3 259:8    0 363.2G  0 part   /home       -
└─nvme1n1p4 259:9    0     2G  0 part   [SWAP]     [F]

```
