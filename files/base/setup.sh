#!/bin/bash -e

eselect python set 1
#chmod 777 /dev/null
export MAKEOPTS="-j32"
USE="-perl" emerge -qu vim dhcpcd usbutils unzip lsof eix dev-vcs/git tmux wireless-tools wpa_supplicant ntp sys-fs/multipath-tools

rc-update add sshd default
rc-update add swclock boot
rc-update del hwclock boot
echo "root:gentoo" | chpasswd
useradd -m "pi" 

# Avoid "Id "s0" respawning too fast: disabled for 5 minutes
sed -i -e "s/^s0:12345:respawn/#s0:12345:respawn/g" /etc/inittab

# Disable console 0 clearing at boot. Messages are useful
sed -i -e "s@^c1:12345:respawn:/sbin/agetty 38400@c1:12345:respawn:/sbin/agetty --noclear 38400@g" /etc/inittab

# Allow root login via ssh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Cleanup
rm /etc/resolv.conf
exit
