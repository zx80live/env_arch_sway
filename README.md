# env_arch_sway
Guide to setup environment based on Arch Linux and Swaywm for particular hardware config (see Hardware section).


## Table of contents
* [Hardware](#hardware)
* [Install Arch](#install-arch)
   * [Prepare installation](#prepare-installation)
      * [Create bootable USB](#create-bootable-usb)
      * [Change console font](#change-console-font)
      * [Network (iwd)](#network-iwd)
      * [Partitions (GPT, EFI, dualboot)](#partitions-gpt-efi-dualboot)
      * [Mount](#mount)
      * [Update system clock](#update-system-clock)
      * [Select fast mirror](#select-fast-mirror)
   * [Install base packages](#install-base-packages)
   * [Post install configuration](#post-install-configuration)
      * [Install common packages](#install-common-packages)
      * [Users](#users)
      * [Console font](#console-font)
      * [Timezone](#timezone)
      * [Locale](#locale)
      * [Network](#network)
      * [Network manager](#network-manager)
      * [GRUB (dualboot)](#grub-dualboot)
         * [Remove previous grub entries (if necessary)](#remove-previous-grub-entries-if-necessary)
         * [GRUB install](#grub-install)
      * [Disks](#disks)
         * [SSD trim](#ssd-trim)
         * [SSD trim (periodical)](#ssd-trim-periodical)
         * [SSD trim (continuous)](#ssd-trim-continuous)
         * [SSD trim (manual)](#ssd-trim-manual)
         * [Swappiness](#swappiness)
         * [Ext4 tuning](#ext4-tuning)
         * [IO Scheduler](#io-scheduler)
      * [Audio](#audio)
      * [Video drivers](#video-drivers)
         * [List graphics cards](#list-graphics-cards)
         * [List loaded video drivers](#list-loaded-video-drivers)
         * [Intel](#intel)
      * [Exit](#exit)
* [System configuration](#system-configuration)
   * [Connect to WiFi](#connect-to-wifi)
   * [Firewall](#firewall)
   * [AUR helper](#aur-helper)
* [Install Swaywm](#install-swaywm)
   * [Packages](#packages)
   * [Autostart](#autostart)
   * [Fonts](#fonts)
   * [Terminal](#terminal)
      * [Kitty](#kitty)
      * [Ranger](#ranger)
      * [Alacritty](#alacritty)
      * [Powerlevel10k](#powerlevel10k)
   * [Firefox](#firefox)
   * [Intellij IDEA](#intellij-idea)
   * [Media](#media)
   * [Chromium](#chromium)
   * [IM](#im)
      * [XMPP](#xmpp)
      * [Telegram](#telegram)
      * [Zoom](#zoom)
* [Utils](#utils)
   * [Services](#services)
      * [Show errors](#show-errors)
   * [Disk utilities](#disk-utilities)
      * [Show storages and partitions](#show-storages-and-partitions)
      * [Remove unused EFI entries](#remove-unused-efi-entries)
      * [Restore EFI entries](#restore-efi-entries)
   * [Backup](#backup)
* [HowTo](#howto)
   * [Restart touchpad/trackpoint](#restart-touchpadtrackpoint)
   * [Print environment variables](#print-environment-variables)
   * [Printer (Brother)](#printer-brother)
   * [Pacman](#pacman)
      * [Remove orphans](#remove-orphans)
      * [Mount NTFS](#mount-ntfs)
   * [Analyze systemd](#analyze-systemd)
* [Issues](#issues)
* [Dev](#dev)
   * [Neovim](#neovim)
   * [C++](#c)
      * [Packages](#packages-1)
      * [Compile and run](#compile-and-run)

## Hardware
```
ThinkPad P53
Resolution: 1920x1080
CPU: Intel i7-9750H (12) @ 4.500GHz
GPU: NVIDIA Quadro T1000 Mobile
GPU: Intel CoffeeLake-H GT2 [UHD Graphics 630]
Memory: 3420MiB / 39762MiB
```
[[^]](#table-of-contents)

## Install Arch
### Prepare installation
##### Create bootable USB
```
lsblk

NAME        MAJ:MIN RM   SIZE RO TYPE 
sda           8:16   0 931.5G  0 disk  # target usb flash
└─ sda1       8:17   0 931.5G  0 part  
...
```
```
sudo dd bs=4M if=./archlinux.iso of=/dev/sda status=progress oflag=sync
```
[[^]](#table-of-contents)
##### Change console font
```
setfont ter-u24b
```
[[^]](#table-of-contents)
##### Network (iwd)
```
iwctl device list                                               # => wlan0
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect <SSID>
```
[[^]](#table-of-contents)
##### Partitions (GPT, EFI, dualboot)
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
[[^]](#table-of-contents)
##### Mount
```
mount /dev/nvme1n1p1 /mnt                   # mount root
mount --mkdir /dev/nvme1n1p2 /mnt/home      # mount home
mount --mkdir /dev/nvme0n1p1 /mnt/boot/efi  # mount efi
swapon /dev/nvme1n1p3
```
[[^]](#table-of-contents)
##### Update system clock
```
timedatectl status
timedatectl list-timezones
timedatectl set-timezone <value>
timedatectl set-ntp true
```
[[^]](#table-of-contents)
##### Select fast mirror
```
pacman -S reflector
```
```
sudo reflector --verbose --country '<Country>' -l 25 --sort rate --save /etc/pacman.d/mirrorlist
```
[[^]](#table-of-contents)
### Install base packages
```
pacstrap /mnt base base-devel [linux] [linux-headers] linux-lts linux-lts-headers linux-firmware intel-ucode
```
```
genfstab -U /mnt >> /mnt/etc/fstab
```
[[^]](#table-of-contents)
### Post install configuration
```
arch-chroot /mnt
```
[[^]](#table-of-contents)
#### Install common packages
```
pacman -Syu
pacman -S nvim dhcpcd networkmanager network-manager-applet nm-connection-editor sudo zsh zsh-completions hdparm util-linux rsync wget curl git htop bpytop make ranger reflector
```
```
sudo reflector --verbose --country '<Country>' -l 25 --sort rate --save /etc/pacman.d/mirrorlist
```
```
/etc/pacman.conf

[multilib]
Include = /etc/pacman.d/mirrorlist
```
```
pacman -Syl multilib
```
[[^]](#table-of-contents)
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
[[^]](#table-of-contents)
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
[[^]](#table-of-contents)
#### Timezone
```
ln -sf /usr/share/zoneinfo/<Region>/<City> /etc/localtime
```
```
hwclock --systohc
```
[[^]](#table-of-contents)
#### Locale
```
vim /etc/locale.gen
locale-gen
localectl set-locale en_US.UTF-8
```
[[^]](#table-of-contents)
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
[[^]](#table-of-contents)
#### Network manager
```
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
systemctl mask NetworkManager-wain-online.service
```
[[^]](#table-of-contents)

#### GRUB (dualboot)
##### Remove previous grub entries (if necessary)
```
ls /boot/efi/EFI
```
[[^]](#table-of-contents)
##### GRUB install
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
[[^]](#table-of-contents)
#### Disks
##### SSD trim
Check if is TRIM supported:
```
lsblk --discard

NAME   DISC-GRAN DISC-MAX
nvmeX    512B     2T           # if values > 0 then TRIM is supported
...
```
Use one of **periodical** (recommended) or **continuous** TRIM
[[^]](#table-of-contents)
##### SSD trim (periodical)
```
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
```
[[^]](#table-of-contents)
##### SSD trim (continuous)
Add `discard` option to mount
```
/etc/fstab

UID=xxx-xxx-xxx  /  ext4  rw,realtime,discard  0 1
...
```
[[^]](#table-of-contents)
##### SSD trim (manual)
```
sudo fstrim -v /
```
[[^]](#table-of-contents)
##### Swappiness
```
sysctl vm.swappiness    # default=60
```
```
/etc/sysctl.d/99-swappiness.conf
vm.swappiness=10

sudo reboot
```
[[^]](#table-of-contents)
##### Ext4 tuning
Use `relatime` attr instead of `noatime`:
```
/etc/fstab

UUID=xxx-xxx-xxx  / ext4 rw,relatime 0 1
...
```
[[^]](#table-of-contents)
##### IO Scheduler
```
cat /sys/block/nvme1n1/queue/scheduler

[none] mq-deadline kyber bfq               # none value is selected by default
```
For NVME the `none` scheduler is better choise because the NVME's parallelism is used
[[^]](#table-of-contents)
#### Audio
```

```
[[^]](#table-of-contents)
#### Video drivers
##### List graphics cards
```
lspci -v|grep -i vga
```
[[^]](#table-of-contents)
##### List loaded video drivers
```
lsmod|grep -i vid
```
[[^]](#table-of-contents)
##### Intel
```
pacman -S mesa libva-intel-driver libva-utils intel-gpu-tools
```
```
vainfo
...
vainfo: Driver version: Intel i965 driver for Intel(R) Coffee Lake - 2.4.1
...
```
```
lsmod|grep -i vid
...
video                  57344  3 thinkpad_acpi,i915,nouvea  # driver is loaded
```
```
mpv --hwdec=auto <videofile>   # test hardware decoder
```
```
sudo intel_gpu_top             # view GPU activity
```
[[^]](#table-of-contents)


#### Exit
```
exit
umount -lR /mnt
reboot
```
[[^]](#table-of-contents)
## System configuration
#### Connect to WiFi
```
nmcli device status
nmcli radio wifi
nmcli radio wifi on
nmcli device wifi list
sudo nmcli --ask device wifi connect "<SSID>" name "<name>"
```
[[^]](#table-of-contents)
#### Firewall
```
sudo pacman -S ufw
```
```
sudo systemctl disable iptables.service
sudo systemctl enable ufw.service
sudo ufw status verbose

sudo ufw default deny
sudo ufw allow from 192.168.0.0/24
sudo ufw allow from 192.168.1.0/24
sudo ufw allow <application>

sudo uwf enable
sudo uwf status
```
[[^]](#table-of-contents)
#### AUR helper
```
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```
```
yay -Syy
```
[[^]](#table-of-contents)


## Install Swaywm
##### Packages
```
pacman -S sway swaylock swayidle wofi wl-clipboard wf-recorder zenity brightnessctl waybar slurp grim xorg-wayland
```
##### Autostart
```
~/.zprofile

if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  sway
fi
```
[[^]](#table-of-contents)
### Fonts
```
yay -S font-manager ttf-meslo-nerd-font-powerlevel10k nerd-fonts-terminus nerd-fonts-source-code-pro
```
[[^]](#table-of-contents)
### Displays
#### Multimonitors
```
pacman -S wdisplays
```
[[^]](#table-of-contents)

### Terminal
#### Kitty
```
pacman -S kitty
```
```
~/.conf/kitty/kitty.conf
...
confirm_os_window_close 0
```
[[^]](#table-of-contents)
#### Ranger
```
pacman -S ranger
```
```
ranger --copy-config=all
```
```
~/.config/ranger/rc.conf
set preview_images true
set preview_images_method kitty
```
[[^]](#table-of-contents)
#### Alacritty
```
pacman -S alacritty
```
```
mkdir ~/.config/alacritty
cp /usr/share/doc/alacritty/example/alacritty.yml ~/.config/alacritty/alacritty.yml
```
[[^]](#table-of-contents)
#### Powerlevel10k
```
yay -S --noconfirm zsh-theme-powerlevel10k-git
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
```
```
p10k configure
```
[[^]](#table-of-contents)
#### ZshCompletions
```
~/.zshrc
...
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion::complete:*' gain-privileges 1
```
[[^]](#table-of-contents)
### Firefox
```
echo "export MOZ_ENABLE_WAYLAND=1" >> ~/.zshenv
```
```
about:config
full-screen-api.ignore-widgets=true  # allows to keep container size in fullscreen mode
ui.systemUsesDarkTheme=1
```
```
set font: san scherif
```
[[^]](#table-of-contents)
### Intellij IDEA
```
pacman -S xorg-wayland
```
```
echo "xwayland enable" >> ~/.config/sway/config
```
```
echo "export _JAVA_AWT_WM_NONREPARENTING=1" >> ~/.zshenv
```
[[^]](#table-of-contents)
### Media

### Chromium
```
echo "alias chromium='chromium --enable-features=UseOzonePlatform --ozone-platform=wayland'" >> ~/.zshenv
```
[[^]](#table-of-contents)
### IM
##### XMPP
````
pacman -S gajim
````
[[^]](#table-of-contents)
##### Telegram
```
pacman -S telegram-desktop
```
[[^]](#table-of-contents)
##### Zoom
```
yay -S zoom
```
[[^]](#table-of-contents)

## Utils
### Services
##### Show errors
```
sudo systemctl --failed
sudo journalctl -p 3 -xb
```
[[^]](#table-of-contents)





### Disk utilities
##### Show storages and partitions
`lsblk` `fdisk -l`
[[^]](#table-of-contents)
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
[[^]](#table-of-contents)
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
[[^]](#table-of-contents)
### Backup

## HowTo
##### Restart touchpad/trackpoint
```
sudo modprobe -r psmouse
sudo modprobe psmouse
```
[[^]](#table-of-contents)
##### Print environment variables
```
printenv
```
[[^]](#table-of-contents)
##### Printer (Brother)
```
yay -S brother-dcpl2550dw
pacman -S cups cups-filters avahi system-config-printer
```
```
systemctl disable systemd-resolved.service
systemctl enable avahi-daemon.service
systemctl enable cups
```
```
sudo ufw allow 5353/udp
```
```
# browse network devices including wi-fi printers (will be availabled after reboot)
avahi-browse --all --ignore-local --resolve --terminate
```
[[^]](#table-of-contents)
### Pacman
##### Remove orphans
```
sudo pacman -Rns $(pacman -Qtdq)
```
[[^]](#table-of-contents)
##### Mount NTFS
```
pacman -S ntfs-3g
```
```
sudo mount --mkdir -t ntfs-3g /dev/<device> /mnt/<target>
```
[[^]](#table-of-contents)
#### Analyze systemd
```
systemd-analyze blame
```
[[^]](#table-of-contents)
## Issues
https://github.com/keybase/client/issues/19614
[[^]](#table-of-contents)
## Dev
### Neovim
```
pacman -S nvim python-pynvim
```
```
echo "alias vim=nvim" >> ~/.zshenv
echo "export EDITOR=nvim" >> ~/.zshenv
```
```
yay -S nvim-packer-git
```
```
nvim
:PackerInstall
```
[[^]](#table-of-contents)
### C++
##### Packages
```
pacman -S gcc base-devel glibc make binutils
```
[[^]](#table-of-contents)
##### Compile and run
```
g++ test.cpp && make test && ./test
```
```
g++ -std=c++11 -O2 -Wall test.cpp -o test
```
[[^]](#table-of-contents)
