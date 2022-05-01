# env_arch_sway
Guide to setup environment based on Arch Linux and Swaywm for particular hardware config (see Hardware section).

  * [Write iso to usb](#write-iso-to-usb)
  * [Hardware](#hardware)
  * [Install Arch](#install-arch)
    + [Change console font](#change-console-font)
    + [Network](#network)
    + [Partitions (dualboot)](#partitions--dualboot-)
    + [Drivers](#drivers)
      - [Nvidia](#nvidia)
  * [Install Swaywm](#install-swaywm)
  * [Utils](#utils)
    + [Disk utilities](#disk-utilities)
        * [Show storages and partitions](#show-storages-and-partitions)
        * [Remove unused EFI entries](#remove-unused-efi-entries)
    + [Backup](#backup)


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
#### Change console font
```
setfont /usr/share/kbd/consolefonts/ter-u22b.psf.gz
```

#### Network
```
iwctl device list                                               # => wlan0
iwctl station wlan0 scan
iwctl station wlan0 get-networks

iwctl station wlan9 connect <SSID>
```

#### Update system clock
```
timedatectl set-ntp true
```

#### Partitions (GPT, EFI, dualboot)
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
```
mkfs.ext4 /dev/nvme1n1p1
mkswap /dev/nvme1n1p3
```

#### Mount
```
mount /dev/nvme1n1p1 /mnt                  # mount root
mount --mkdir /dev/nvme0n1p1 /mnt/boot     # mount EFI
swapon /dev/nvme1n1p3
```

#### Install
```
pacstrap /mnt base linux linux-firmware
```
```
genfstab -U /mnt >> /mnt/etc/fstab
```

## Configure
```
arch-chroot /mnt
```
#### Install packages
```
pacman -Syyuu
pacman -S vim iwd dhcpcd sudo zsh
```

#### Console font
```
pacman -S terminus-font
setfont /usr/share/kbd/consolefonts/ter-u22b.psf.gz
```
```
/etc/vconsole.conf

CHARMAP="UTF-8"
CODESET="Lat7"
FONT=ter-u22n.psf.gz
```

#### Timezone
```
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
```
```
hwclock --systohc
```
#### Locale
```
vim /etc/locale.gen
locale-gen
localectl set-locale en_US.UTF-8
```

#### Network
```
/etc/hostname

<hostname>
```
```
/etc/hosts

127.0.0.1        localhost
::1              localhost
127.0.1.1        <hostname>
```
```
iwctl device list                                               # => wlan0
iwctl station wlan0 scan
iwctl station wlan0 get-networks

iwctl station wlan9 connect <SSID>
```
```
sudo dhcpd
```


#### Users
```
passwd    # root password
```
```
useradd -m -g users -G wheel,root,audio -s /bin/zsh <user>
passwd <user>
```
```
EDITOR=vim visudo
# uncomment %wheel ...
```

#### ⚠️ GRUB (dualboot)
```
pacman -S grub efibootmgr os-prober
```
```
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
os-prober
grub-mkconfig -o /boot/grub/grub.cfg
```

#### Exit
```
exit
umount -R /mnt
reboot
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

##### Restore EFI entries
The following initial entries are used in the current config and should be restored from backup.
```
mount --mkdir /dev/nvme0n1p1 /mnt/efi-partition
tree /mnt/efi-partition
```
```
── EFI
    └── Boot
         └── bootx64.efi
         └── fbx64.efi
         └── LenovoBT.EFI
         └── mmx64.efi
    └── Microsoft
         └── Boot
              └── en-US
                   └── ...
              ...     
              └── BCD
              ...
         └── Recovery
              └── BCD
              ...
```

### Backup

