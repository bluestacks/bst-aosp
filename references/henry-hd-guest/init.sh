#!/boot/bin/sh

PATH=/boot/sbin:/boot/bin
export PATH

/boot/bin/busybox mknod /dev/kmsg c 1 11

log_echo()
{
	echo "$@" > /dev/kmsg
}

log_echo Starting BlueStacks Userland
exec >/dev/kmsg 2>/dev/kmsg
umask 022

die_if_error()
{
	if [ $? -ne 0 ]; then
		log_echo "<2>$@"
		exit 1
	fi
}

#
# Ask busybox to populate /boot/bin and /boot/sbin.
#

/boot/bin/busybox --install -s /boot/bin

#
# Mount /proc and /sys.
#

mkdir /proc
mount -t proc proc /proc
die_if_error "Cannot mount /proc"

# TEMP(A16 bringup debug): force all kmsg to console so we can see where boot dies.
echo 8 > /proc/sys/kernel/printk 2>/dev/null
# TEMP(A16 bringup debug): 关闭 /dev/kmsg 限速, 否则 second-stage init 的日志会被
# "output lines suppressed due to ratelimiting" 大量吞掉, 看不到真正的崩溃点。后续回退。
echo on > /proc/sys/kernel/printk_devkmsg 2>/dev/null
echo "<0>A16DBG: init.sh proc mounted, loglevel raised" > /dev/kmsg

mkdir /sys
mount -t sysfs sysfs /sys
die_if_error "Cannot mount /sys"

#
# Now that /sys is mounted, we can populate /dev.
#

mdev -s

#
WINDOWSGATEWAY="10.0.2.2"
echo "WindowsGateway : $WINDOWSGATEWAY"
export WINDOWSGATEWAY

# Load our uHD kernel modules.
#

grep SHELL_BEFORE_KMODS= /proc/cmdline > /dev/null
if [ $? -eq 0 ]; then
	log_echo Starting debug shell before kernel modules
	log_echo Please exit the shell to continue the boot process
	env HAS_CTTY=Yes setsid cttyhack /boot/bin/sh
fi

load_module()
{
	log_echo "Loading module $1"
	insmod $1
	die_if_error "Cannot load module $1"
}

load_module /boot/bstmods/bstvmsg.ko
bstvmsg=`/boot/bin/busybox cat /sys/devices/virtual/misc/bstvmsg/uevent`
if [ ! -z "$bstvmsg" ]; then
    MAJOR=`/boot/bin/busybox echo $bstvmsg | /boot/bin/busybox cut -d '=' -f 2 | /boot/bin/busybox cut -d ' ' -f 1`
    MINOR=`/boot/bin/busybox echo $bstvmsg | /boot/bin/busybox cut -d '=' -f 3 | /boot/bin/busybox cut -d ' ' -f 1`

    log_echo "making bstvmsg node"
    /boot/bin/busybox mknod -m 0666 /dev/bstvmsg c $MAJOR $MINOR
else
    log_echo "unable to make bstvmsg dev node"
fi

load_module /boot/bstmods/bstinput.ko

load_module /boot/bstmods/bstaudio.ko

grep SHELL_BEFORE_VIDEO= /proc/cmdline > /dev/null
if [ $? -eq 0 ]; then
	log_echo Starting debug shell before video
	log_echo Please exit the shell to continue the boot process
	env HAS_CTTY=Yes setsid cttyhack /boot/bin/sh
fi

#load_module /boot/bstmods/bstvideo.ko

load_module /boot/bstmods/bstpgaipc.ko
load_module /boot/bstmods/videobuf-core.ko
load_module /boot/bstmods/bstcamera.ko
load_module /boot/bstmods/hvmem.ko

#load_module /boot/bstmods/bstsensor.ko

#
# Mount the appropriate file system for ramdisk.img and system.img.
#

grep SHELL_BEFORE_MOUNTS= /proc/cmdline > /dev/null
if [ $? -eq 0 ]; then
	log_echo Starting debug shell before mounts
	log_echo Please exit the shell to continue the boot process
	env HAS_CTTY=Yes setsid cttyhack /boot/bin/sh
fi

mkdir /boot/android

log_echo "Mounting Android root file system /dev/sda1"

mount -o ro /dev/sda1 /boot/android
die_if_error "Cannot mount Android root file system"
echo "<0>A16DBG: sda1 mounted at /boot/android" > /dev/kmsg

#
# Prepare our root file system.
#

cd /

#
# Use the new /proc/cmdline to populate the environment.
#
populate_environment()
{
	while [ $# -ne 0 ]; do
	    # Making sure that if name contains ".", we don't export it in environment
        case "$1" in
            *.*=*)
                log_echo "not setting $1 as this contains '.' in name"
                ;;
            *)
                log_echo "setting env $1"
                export $1
                ;;
        esac
		shift
	done
}

log_echo "Reading cmdline"
log_echo `cat /proc/cmdline`

log_echo "Setting cmdline as env"
populate_environment `cat /proc/cmdline`

log_echo "Extracting ramdisk.img"

zcat /boot/android/android/ramdisk.img | cpio -id
die_if_error "Cannot extract ramdisk.img"
echo "<0>A16DBG: ramdisk.img extracted; /init=$(ls -l /init 2>&1)" > /dev/kmsg

if [ -e /boot/android/android/system.sfs ]; then

	mkdir /sfs

	log_echo "Mounting system.sfs"

	mount -o loop /boot/android/android/system.sfs /sfs
	die_if_error "Cannot mount system.sfs"

	log_echo "Mounting system.img"

	mount -o loop /sfs/system.img system
	die_if_error "Cannot mount system.img from SquashFS"

else
	log_echo "Mounting system directory"

	mount -o loop /boot/android/android/system system
	die_if_error "Cannot mount system directory"

  if [ "$bstandroid" == "rvc64" ] || [ "$bstandroid" == "tiramisu64" ]; then
      ln -s /boot/android/android/system/apex/com.android.runtime /apex/com.android.runtime
  fi

  # A16(baklava64): apex 不再是 flatten 目录, 而是 .apex 文件(payload=erofs, STORED, 偏移4096).
  # /system/bin/{sh,linkerconfig,...} 的解释器 /system/bin/linker64 指向 /apex/com.android.runtime,
  # 所以必须在使用任何 /system 动态二进制前, 把核心 apex 零拷贝 loop 挂载到 /apex/<name>.
  # 其余(尤其 .capex 压缩包)留给 Android init 阶段的 apexd 处理。
  if [ "$bstandroid" == "baklava64" ]; then
      APEX_SRC=/boot/android/android/system/apex
      # 注意: busybox 1.19.4 的 `losetup -f` 在第二次调用时会段错误,
      # 所以自己遍历 /sys/block/loopN/loop 找空闲 loop 设备(无该子目录=未占用)。
      find_free_loop()
      {
          n=0
          while [ $n -lt 16 ]; do
              if [ ! -d /sys/block/loop$n/loop ]; then
                  echo /dev/loop$n
                  return 0
              fi
              n=`expr $n + 1`
          done
          return 1
      }
      for apexname in com.android.runtime com.android.i18n; do
          apexfile=$APEX_SRC/$apexname.apex
          if [ -f "$apexfile" ]; then
              mkdir -p /apex/$apexname
              loopdev=`find_free_loop`
              losetup -o 4096 $loopdev "$apexfile"
              die_if_error "Cannot losetup apex $apexname on $loopdev"
              mount -t erofs -o ro $loopdev /apex/$apexname
              die_if_error "Cannot mount apex $apexname"
              echo "<0>A16DBG: mounted apex $apexname on $loopdev" > /dev/kmsg
          else
              log_echo "apex $apexname.apex not found, skip"
          fi
      done
  fi

	if [ "$bstandroid" == "tiramisu64" ]; then
		mkdir /linkerconfig
		/system/bin/linkerconfig --target /linkerconfig
	fi

	if [ "$bstandroid" == "baklava64" ]; then
		mkdir /linkerconfig
		/system/bin/linkerconfig --target /linkerconfig
		echo "<0>A16DBG: linkerconfig rc=$?; ld.config=$(ls -l /linkerconfig/ld.config.txt 2>&1)" > /dev/kmsg
	fi
fi
echo "<0>A16DBG: system mounted; bstandroid=[$bstandroid]; sysinit=$(ls -l /system/bin/init 2>&1); linker=$(ls -l /system/bin/bootstrap/linker64 2>&1); apexrt=$(ls -ld /apex/com.android.runtime 2>&1)" > /dev/kmsg

#mkdir cache
mount -t tmpfs tmpfs cache

log_echo "Checking for debug shell"
grep SHELL_BEFORE_STAGE2= /proc/cmdline > /dev/null
if [ $? -eq 0 ]; then
	log_echo Starting debug shell before stage 2
	log_echo Please exit the shell to continue the boot process
	env HAS_CTTY=Yes setsid cttyhack /boot/bin/sh
fi

PATH=/system/bin:/system/xbin:/sbin

#bstreport timeline "first_stage_init_completed"

log_echo "Running bstsetconf script"
source /boot/bstsetconf.sh

populate_bst_conf
generate_android_ids

# load vbox specific modules
# TEMP(A16 bringup verify): 重新尝试加载 vboxguest.ko, 但失败不退出, 仅打印 rc 验证。
log_echo "Loading module /boot/bstmods/vboxguest.ko (non-fatal verify)"
insmod /boot/bstmods/vboxguest.ko
echo "<0>A16DBG: insmod vboxguest.ko rc=$?" > /dev/kmsg
vboxuser=`/boot/bin/busybox cat /sys/devices/virtual/misc/vboxuser/uevent`
if [ ! -z "$vboxuser" ]; then
    MAJOR=`/boot/bin/busybox echo $vboxuser | /boot/bin/busybox cut -d '=' -f 2 | /boot/bin/busybox cut -d ' ' -f 1`
    MINOR=`/boot/bin/busybox echo $vboxuser | /boot/bin/busybox cut -d '=' -f 3 | /boot/bin/busybox cut -d ' ' -f 1`

    log_echo "making vboxuser node"
    /boot/bin/busybox mknod -m 0666 /dev/vboxuser c $MAJOR $MINOR
else
    log_echo "unable to make vboxuser dev node, bstreport may fail"
fi

#bstreport timeline "vbox_guest_loaded"

# TEMP(A16 bringup verify): 重新尝试加载 vboxsf.ko, 但失败不退出, 仅打印 rc 验证。
log_echo "Loading module /boot/bstmods/vboxsf.ko (non-fatal verify)"
insmod /boot/bstmods/vboxsf.ko
echo "<0>A16DBG: insmod vboxsf.ko rc=$?" > /dev/kmsg

if [ ! -z "$BST_GRAPHICS_ENGINE" ]; then
    echo $BST_GRAPHICS_ENGINE > /proc/glmode
else
    log_echo "bst.graphics_engine property not found"
fi

if [ -e /proc/sys/vm/pcr_enabled -a ! -z "$BST_MEM_PCR_ENABLED" ]; then
	echo $BST_MEM_PCR_ENABLED > /proc/sys/vm/pcr_enabled
else
	log_echo "bst.mem_pcr_enabled property not found"
fi

if [ -e /proc/sys/vm/pcr_pclimit -a ! -z "$BST_MEM_PCR_PCLIMIT" ]; then
	echo $BST_MEM_PCR_PCLIMIT > /proc/sys/vm/pcr_pclimit
else
	log_echo "bst.mem_pcr_pclimit property not found"
fi

mkdir /dev/block
ln -s /dev/sdb1 /dev/block/sdb1

log_echo "Running stage2 script"
echo "<0>A16DBG: init.sh done, exec stage2.sh" > /dev/kmsg
exec sh /boot/stage2.sh
