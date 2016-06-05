#!/bin/bash
set -e
target="rpi1"
mountpoint="/mnt/rasptoo"

MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized

[ -d firmware ] || git clone https://github.com/raspberrypi/firmware.git
pushd firmware
git pull
popd

NBD="nbd10"
# [[ `mountpoint -q ${mountpoint}` ]] && 
# umount -l ${mountpoint}
pgrep qemu-nbd && pkill -15 qemu-nbd
modprobe nbd
qemu-img create gentoo-${target}.img 1.9G
qemu-nbd -f raw -c /dev/${NBD} gentoo-${target}.img
set +e
fdisk /dev/${NBD} << EOF
n
p
1

+32M
t
c
n
p
2


a
1
w
EOF
sleep 1
set -e
kpartx -av /dev/${NBD}
sleep 1
mkfs.vfat /dev/mapper/${NBD}p1 || exit -1
mkfs.ext4 /dev/mapper/${NBD}p2 || exit -1


if test ${target} = "rpi1"; then
   # Pi1
   STAGEFILE="stage3-armv6j_hardfp-20160326.tar.bz2"
   wget -c http://distfiles.gentoo.org/releases/arm/autobuilds/current-stage3-armv6j_hardfp/${STAGEFILE} -O /var/${STAGEFILE}
elif test ${target} = "rpi2"; then
   # Pi2
   STAGEFILE="stage3-armv7a_hardfp-20160523.tar.bz2"
   wget -c http://distfiles.gentoo.org/releases/arm/autobuilds/current-stage3-armv7a_hardfp/${STAGEFILE} -O /var/${STAGEFILE}
fi

[ -d $mountpoint ] || mkdir $mountpoint
mount /dev/mapper/${NBD}p2 $mountpoint

cd $mountpoint
tar xjpf /var/${STAGEFILE} 
mount /dev/mapper/${NBD}p1 $mountpoint/boot

rsync -vrtza ${MY_PATH}/firmware/boot/ $mountpoint/boot

cp /usr/bin/qemu-arm usr/bin/qemu-arm

/etc/init.d/qemu-binfmt start

mkdir -p usr/portage
mount --bind /usr/portage usr/portage
mount -t tmpfs -o size=8G tmpfs var/tmp
mount -t tmpfs -o size=6G tmpfs var/cache
mount -t tmpfs -o size=2G tmpfs tmp/

mount -t proc proc proc
mount --rbind /sys sys
mount --make-rslave sys
mount --rbind /dev dev
mount --make-rslave dev

rsync -vrtza ${MY_PATH}/files/base/ ./
mv etc/portage/make.conf etc/portage/make.conf.orig
cp etc/portage/make.conf.${target} etc/portage/make.conf

chroot . /bin/bash setup.sh

rsync -rtza ${MY_PATH}/firmware/modules $mountpoint/lib/

timecode=`date +%Y%m%d-%H%M`
tar cfz /var/emulation/gentoo-${target}-stage3-${timecode}.tgz --one-file-system .
cd ${MY_PATH}
[-f gentoo-${target}.img.bz2 ] && rm gentoo-${target}.img.bz2
bzip2 gentoo-${target}.img
