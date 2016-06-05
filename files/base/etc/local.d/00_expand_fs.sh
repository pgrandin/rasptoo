fdisk /dev/mmcblk0 < EOF
d
2
n
p
2


w
EOF
kpartx -av /dev/mmcblk0
resize2fs /dev/mmcblk0p2
