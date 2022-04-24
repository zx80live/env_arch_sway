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

## Install Arch
### Change console font
Temporary:
```
setfont /usr/share/consolefonts/Lat7-Terminus28x14.psf
```
Const:
```
sudo vim /etc/default/console-setup

CHARMAP="UTF-8"
CODESET="Lat7"
FONTFACE="Terminus"
FONTSIZE="28x14"
```

### Network
```
```

### Partitions (dualboot)
Tools: `fdisk` `cfdisk` `gparted`
```
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS  FORMAT
nvme0n1     259:0    0 238.5G  0 disk                
├─nvme0n1p1 259:1    0   260M  0 part  [EFI]         -
├─nvme0n1p2 259:2    0    16M  0 part                -
├─nvme0n1p3 259:3    0 237.2G  0 part  /mnt/win      -
└─nvme0n1p4 259:4    0  1000M  0 part                -

nvme1n1     259:5    0 465.8G  0 disk 
├─nvme1n1p1 259:6    0  97.7G  0 part  /            [F] 
├─nvme1n1p2 259:7    0 360.3G  0 part  /home         -
└─nvme1n1p3 259:8    0   7.8G  0 part  [SWAP]       [F]
```


### Drivers
#### Nvidia

## Install Swaywm

## Utils
### Disk utilities
##### Show storages and partitions
`lsblk` `fdisk -l`

##### Remove unused EFI entries
```
# show EFI entries
sudo efibootmgr -v

Boot0000* Windows Boot Manager
Boot0001* Linux-Firmware-Updater
Boot0002  Setup
Boot0003  ubuntu                  <-- need to be removed
...

# remove ubuntu EFI entry
sudo efibootmgr -b 3 -B
```
