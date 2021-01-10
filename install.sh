TARGET_DISK=""

PACSTRAP=(base linux linux-firmware base-devel)

GRUB_BASE=(efibootmgr grub ntfs-3g os-prober)

NETWORK_BASE=(iw iwd dialog wpa_supplicant networkmanager dhcpcd)

SYSTEM_BASE=(xorg xorg-init xorg-server)

SYSTEM_FONT=(ttf-dejavu wqy-microhei adobe-source-code-pro-fonts adobe-source-han-mono-cn-fonts adobe-source-han-sans-cn-fonts fontconfig nerd-fonts-fira nerd-fonts-fira-code noto-fonts)

GNOME_DESKTOP=(gnome gnome-tweaks gdm)

KDE_DESKTOP=(plasma kde-applications sddm)

XFCE_DESKTOP=(xfce4 lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings lightdm-gtk-greeter-settings-pkexec)

I3WM=(i3-gaps i3blocks i3bar i3lock i3status)

FCITX5=(fcitx5 fcitx5-configtool fcitx5-config-qt fcitx5-rime fcitx5-chinese-addons fcitx5-material-color)
# check network is connect
check_network()
{
    ping -c 4 baidu.com
    if [ $? -eq 0 ]; then
        echo -e "${green}Network connect!${plain}"
        return 0
    else
        echo -e "${red}Please check network connect!${plain}"
        exit 1
    fi
}

# time sync
time_check()
{
    timedatectl set-timezone Asia/Shanghai
    timedatectl set-ntp true
}


disk_select()
{
    echo -n "Enter your disk which want to install Archlinux: "
    read TARGET_DISK
    echo $TARGET_DISK
}

disk_silent()
{
    fdisk /dev/nvme1n1 << EOF
n


+1G
n



w
EOF
}

disk_format()
{
    mkfs.fat -F32 ${TARGET_DISK}p1
    mkfs.ext4 ${TARGET_DISK}p2
}
disk_mount()
{
    mount $TARGET_DISKp2 /mnt
    mkdir /mnt/boot
    mount $TARGET_DISKp1 /mnt/boot
}


before_chroot()
{
    pacstrap /mnt ${PACSTRAP[@]}
    genfstab -U /mnt >> /mnt/etc/fstab
}

#setting mirror
set_mirror()
{
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.back
    echo -e "Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch\nServer = https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
}

# setting time, hostname, hosts, language
chroot_setting()
{
    ln -sf /mnt/usr/share/zoneinfo/Asia/Shanghai /mnt/etc/localtime
    echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "zh_CN.UTF-8 UTF-8" >> /mnt/etc/locale.gen
    echo "LANG=en_US.UTF-8" >> /mnt/etc/locale.conf
    echo "Arch" >> /mnt/etc/hostname
    echo '127.0.0.1       localhost
    ::1             localhost
    127.0.1.1       Arch.localdomain  Arch' >> /mnt/etc/hosts
    echo -e "hwclock --systohc" >> /mnt/root/setup.sh
    echo -e "locale-gen" >> /mnt/root/setup.sh
}

grub_install()
{
    echo "grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux " >> /mnt/root/setup.sh
    echo -e "grub-mkconfig -o /boot/grub/grub.cfg" >> /mnt/root/setup.sh
}

#add archlinuxcn mirror
add_cn_mirror()
{
    echo -e "[archlinuxcn]\nServer = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch\n" >> /etc/pacman.conf
    sudo pamcan -Sy archlinuxcn-keyring << EOF
Y
EOF
}

user_add()
{
    echo -n "${blue}Please Enter root passwd: "
    read root_passwd
    echo -e "passwd << EOF\n${root_passwd}\nEOF" >> /mnt/root/setup.sh
    echo -n "Enter your personal username to promise you can enter your ArchLinux: "
    read username
    echo -n "Enter user passwd: "
    read password
    echo -e "useradd -m -G wheel adminecho '${username}:{password}" >> /mnt/root/setup.sh
    echo "echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers" >> /mnt/root/setup.sh
}

install_xorg()
{
    echo -e "sudo pamcan -S ${SYSTEM_BASE[@]} << EOF\nY\nEOF" >> /mnt/root/setup.sh
}

install_desktop()
{
    echo "Desktop lists:"
    echo "1. Gnome"
    echo "2. kde"
    echo "3. xfce4"
    echo "4. i3wm"
    echo "Please select a WM or DE and enter its number, press Enter to start to install"
    echo -n "Enter your select: "
    read seleted
    if [ ${seleted} == 1 ];then
        echo "${green}Add Gnome to your setup.sh"
        echo -e "sudo pamcan -S ${GNOME_DESKTOP[@]} << EOF\nY\nEOF" >> /mnt/root/setup.sh
        echo -e "systemctl enable gdm" >> /mnt/root/setup.sh


    elif [ ${seleted} == 2 ];then
        echo "${green}Add Kde to your setup.sh"
        echo -e "sudo pamcan -S ${KDE_DESKTOP[@]} << EOF\nY\nEOF" >> /mnt/root/setup.sh
        echo -e "systemctl enable sddm" >> /mnt/root/setup.sh


    elif [ ${seleted} == 3 ];then
        echo "${green}Add Xfce4 to your setup.sh"
        echo -e "sudo pamcan -S ${XFCE_DESKTOP[@]} << EOF\nY\nEOF" >> /mnt/root/setup.sh
        echo -e "systemctl enable lightdm" >> /mnt/root/setup.sh


    elif [ ${seleted} == 4 ];then
        echo "${green}Add I3wm to your setup.sh"
        echo -e "sudo pamcan -S ${I3WM[@]} << EOF\nY\nEOF" >> /mnt/root/setup.sh
        echo -e "systemctl enable lightdm" >> /mnt/root/setup.sh


    fi
}

network_install()
{
    echo -e "sudo pacman -S ${NETWORK_BASE} << EOF\nY\nEOF" >> /mnt/root/setup.sh
}

system_enable()
{
    echo -e "systemctl enable NetworkManager dhcpcd" >> /mnt/root/setup.sh

}

start_install()
{
    chmod a+x /mnt/root/setup.sh
    arch-chroot /mnt /bin/bash /root/setup.sh
}


main()
{
    check_network

    time_check

    disk_select

    disk_silent

    disk_format

    disk_mount

    before_chroot

    chroot_setting

    grub_install

    add_cn_mirror

    user_add

    install_xorg

    install_desktop

    network_install

    system_enable
}

