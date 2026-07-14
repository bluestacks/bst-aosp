#!/bin/sh

bzImage_sz_in_sects=$(dd if=bzImage of=fastboot.img seek=1 bs=512 conv=notrunc 2>&1 | awk '/records out/ {print $1}' | bc )
echo Appended bzImage of size $bzImage_sz_in_sects disk sectors

initrd_seek=$(expr $bzImage_sz_in_sects + 1)
echo Seeking to $initrd_seek disk sector, appending initrd.img
dd if=initrd.img of=fastboot.img seek=$initrd_seek bs=512 conv=notrunc

fastboot_img_sz=`ls -al fastboot.img | awk '{print $5}'`
extra_bytes=$(expr $fastboot_img_sz % 512)
if [ $extra_bytes -ne 0 ]; then
    filepad=$(expr 1024 - $extra_bytes)
else
    filepad=512
fi
dd if=/dev/zero of=zero.file bs=1 count=$filepad
cat fastboot.img zero.file > fastboot.img.padded
