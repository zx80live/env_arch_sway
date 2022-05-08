# env_arch_sway
Guide to setup environment based on Arch Linux and Swaywm for particular hardware config (see Hardware section).

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
##### Change console font
```
setfont ter-u24b
```
##### Network (iwd)
```
iwctl device list                                               # => wlan0
iwctl station wlan0 scan
iwctl station wlan0 get-networks
iwctl station wlan0 connect <SSID>
```
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
##### Mount
```
mount /dev/nvme1n1p1 /mnt                   # mount root
mount --mkdir /dev/nvme1n1p2 /mnt/home      # mount home
mount --mkdir /dev/nvme0n1p1 /mnt/boot/efi  # mount efi
swapon /dev/nvme1n1p3
```
##### Update system clock
```
timedatectl status
timedatectl list-timezones
timedatectl set-timezone <value>
timedatectl set-ntp true
```
##### Select fast mirror
```
pacman -S reflector
```
```
sudo reflector --verbose --country '<Country>' -l 25 --sort rate --save /etc/pacman.d/mirrorlist
```
### Install base packages
```
pacstrap /mnt base base-devel [linux] [linux-headers] linux-lts linux-lts-headers linux-firmware intel-ucode
```
```
genfstab -U /mnt >> /mnt/etc/fstab
```

### Post install configuration
```
arch-chroot /mnt
```
#### Install common packages
```
pacman -Syu
pacman -S vim dhcpcd networkmanager network-manager-applet nm-connection-editor sudo zsh zsh-completions hdparm util-linux rsync wget curl git htop bpytop make ranger reflector
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
#### Network manager
```
systemctl enable dhcpcd.service
systemctl enable NetworkManager.service
systemctl mask NetworkManager-wain-online.service
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
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
```
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
##### Swappiness
```
sysctl vm.swappiness    # default=60
```
```
/etc/sysctl.d/99-swappiness.conf
vm.swappiness=10

sudo reboot
```
##### Ext4 tuning
Use `relatime` attr instead of `noatime`:
```
/etc/fstab

UUID=xxx-xxx-xxx  / ext4 rw,relatime 0 1
...
```

##### IO Scheduler
```
cat /sys/block/nvme1n1/queue/scheduler

[none] mq-deadline kyber bfq               # none value is selected by default
```
For NVME the `none` scheduler is better choise because the NVME's parallelism is used

#### Audio
```

```

#### Video drivers
##### List graphics cards
```
lspci -v|grep -i vga
```
##### List loaded video drivers
```
lsmod|grep -i vid
```
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



#### Exit
```
exit
umount -lR /mnt
reboot
```

## System configuration
#### Connect to WiFi
```
nmcli device status
nmcli radio wifi
nmcli radio wifi on
nmcli device wifi list
nmcli --ask device wifi connect "<SSID>" name "<name>"
```

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

#### AUR helper
```
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```
```
yay -Syy
```



## Install Swaywm
##### Packages
```
pacman -S sway swaylock swayidle wofi wl-clipboard wf-recorder zenity brightnessctl waybar slurp grim 
```
##### Autostart
```
~/.zprofile

if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
  sway
fi
```

### Fonts
```
yay -S font-manager ttf-meslo-nerd-font-powerlevel10k nerd-fonts-terminus nerd-fonts-source-code-pro
```

### Terminal
```
pacman -S alacritty
```
```
mkdir ~/.config/alacritty
cp /usr/share/doc/alacritty/example/alacritty.yml ~/.config/alacritty/alacritty.yml
```
```
yay -S --noconfirm zsh-theme-powerlevel10k-git
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >>~/.zshrc
```
```
p10k configure
```
### Firefox
```
echo "export MOZ_ENABLE_WAYLAND=1" >> ~/.zshenv
```
```
about:config
full-screen-api.ignore-widgets=true  # allows to keep container size in fullscreen mode
ui.systemUsesDarkTheme=1
```

### Media

### Wayland
```
pacman -S qt6-wayland qt5ct
```
```
~/.zshenv
...
export QT_QPA_PLATFORM="wayland;xcb"
export _JAVA_AWT_WM_NONREPARENTING=1
```

### .config/sway/env
https://github.com/swaywm/sway/wiki
```
export DISPLAY=":0.0"
export WAYLAND_DISPLAY=wayland-0
#export XDG_RUNTIME_DIR=/run/user/1000
export XDG_SESSION_TYPE=wayland
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland-egl
export ELM_DISPLAY=wl
export ECORE_EVAS_ENGINE=wayland_egl
export ELM_ENGINE=wayland_egl
export ELM_ACCEL=opengl
#export GDK_BACKEND=wayland
unset GDK_BACKEND
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID
export MOZ_ENABLE_WAYLAND=1
unset WAYLAND_DISPLAY
export GTK_USE_PORTAL=0
```

### Chromium
```
echo "alias chromium='chromium --enable-features=UseOzonePlatform --ozone-platform=wayland'" >> ~/.zshenv
```

### IM
##### XMPP
````
pacman -S gajim
````
##### Telegram
```
pacman -S telegram-desktop
```
##### Zoom



## Utils
### Services
##### Show errors
```
sudo systemctl --failed
sudo journalctl -p 3 -xb
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

##### Print environment variables
```
printenv
```
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
### Pacman
##### Remove orphans
```
sudo pacman -Rns $(pacman -Qtdq)
```

##### Mount NTFS
```
sudo mount --mkdir -t ntfs3 /dev/<device> /mnt/<target>
```

#### Analyze systemd
```
systemd-analyze blame
```

## Issues
https://github.com/keybase/client/issues/19614
