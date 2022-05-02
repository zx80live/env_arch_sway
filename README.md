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
##### Write iso to usb
```
sudo dd bs=4M if=./archlinux.iso of=/dev/sda status=progress oflag=sync
```
##### Change console font
```
setfont ter-u24b
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
mkfs.ext4 /dev/nvme1n1p1  # format root partition
mkfs.ext4 /dev/nvme1n1p2  # [Optional] format home partition if needs
mkswap /dev/nvme1n1p3
```

#### Mount
```
mount /dev/nvme1n1p1 /mnt                   # mount root
mount --mkdir /dev/nvme1n1p2 /mnt/home      # mount home
mount --mkdir /dev/nvme0n1p1 /mnt/boot/efi  # mount efi
swapon /dev/nvme1n1p3
```

##### Network (iwd)
```
iwctl device list                                               # => wlan0
iwctl station wlan0 scan
iwctl station wlan0 get-networks

iwctl station wlan9 connect <SSID>
```

##### Update system clock
```
timedatectl status
timedatectl list-timezones
timedatectl set-timezone <value>
timedatectl set-ntp true
```

#### Install

```
pacstrap /mnt base base-devel [linux] [linux-headers] linux-lts linux-lts-headers linux-firmware intel-ucode
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
pacman -Syu
pacman -S vim iwd dhcpcd networkmanager sudo zsh hdparm util-linux wget git
```

### Disks
#### SSD trim
Check if is TRIM supported:
```
lsblk --discard

NAME   DISC-GRAN DISC-MAX
nvmeX    512B     2T           # if values > 0 then TRIM is supported
...
```
Use one of **periodical** (recommended) or **continuous** TRIM

##### SSD trim (periodical)
```
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
```
##### SSD trim (continuous)
Add `discard` option to mount
```
/etc/fstab

UID=xxx-xxx-xxx  /  ext4  rw,realtime,discard  0 1
...
```
##### SSD trim (manual)
```
sudo fstrim -v /
```

#### Swappiness
```
sysctl vm.swappiness    # default=60
```
```
/etc/sysctl.d/99-swappiness.conf
vm.swappiness=10

sudo reboot
```

#### Ext4 tuning
Use `relatime` attr instead of `noatime`:
```
/etc/fstab

UUID=xxx-xxx-xxx  / ext4 rw,relatime 0 1
...
```

#### IO Scheduler
##### Show current scheduler
```
cat /sys/block/nvme1n1/queue/scheduler

[none] mq-deadline kyber bfq               # none value is selected by default
```
For NVME the `none` scheduler is better choise because the NVME's parallelism is used

#### Console font
```
pacman -S terminus-font
setfont ter-u24b
```
```
/etc/vconsole.conf

CHARMAP="UTF-8"
CODESET="Lat7"
FONT=ter-u24b.psf.gz
```

#### Timezone
```
ln -sf /usr/share/zoneinfo/<Region>/<City> /etc/localtime
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

#### Firewall
```
sudo pacman -S ufw
```
```
sudo systemctl disable iptables.service
sudo systemctl stop iptables.service

sudo systemctl enable ufw.service
sudo systemctl start ufw.service
sudo ufw status verbose

sudo ufw default deny
sudo ufw allow from 192.168.0.0/24
sudo ufw allow <application>

sudo uwf enable
sudo uwf status
```

#### Connect to WiFi (iwd)
```
systemctl stop NetworkManager.service
systemctl enable dhcpcd.service
systemctl start dhcpcd.service
systemctl start iwd.service
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
#### Connect to WiFi (NetworkManager)
```
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
```
```
nmcli device status
nmcli radio wifi
nmcli radio wifi on
nmcli device wifi list
nmcli device wifi connect "<SSID>" password <password> name "<name>"
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

#### GRUB (dualboot)
```
pacman -S grub efibootmgr os-prober mtools
```
```
/etc/default/grub
...
GRUB_DISABLE_OS_PROBER=false
```
```
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
```

#### Exit
```
exit
umount -lR /mnt
reboot
```

### Drivers
#### Nvidia

## Install Swaywm
### Packages
```
pacman -S sway swaylock swayidle wofi wl-clipboard alacritty zenity brightnessctl waybar slurp grim wf-recorder
```

## Utils
### Services
##### Show errors
```
sudo systemctl --failed
sudo journalctl -p 3 -xb
```

### Pacman
##### Remove orphans
```
sudo pacman -Rns $(pacman -Qtdq)
```

##### AUR helper
```
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```
```
yay -Syy
```


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

## HowTo
##### Restart touchpad/trackpoint
```
sudo modprobe -r psmouse
sudo modprobe psmouse
```
