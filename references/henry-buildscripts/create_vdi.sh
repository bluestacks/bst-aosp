#!/bin/bash

# This script is used to create .vdi files from blank files present in appplayer.git repo
# Sample usage scenarios can be:
# To create Root.vdi file from Root.fs
# create_vdi.sh -t root -v /tmp/Root.vdi -f /tmp/Root.fs
# To create Prebundled.vdi.bgp file from Prebundled.fs.bgp
# create_vdi.sh -t prebundled -v /tmp/Prebundled.vdi.bgp -f /tmp/Prebundled.fs.bgp
# To create blank formatted SDCard.vdi file
# create_vdi.sh -t sdcard -v /tmp/SDCard.vdi

#set -x

BUILD_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASEPATH="$(dirname "$BUILD_SCRIPT_PATH")"
HYPERDROID="$BASEPATH/hd"
BLANK_VDI_FILES="$HYPERDROID/guest/FileSystem"
NBD_DEV=/dev/nbd5
NBD_PART=${NBD_DEV}p1

#########################################################################################################################
#                      SETTING LOGFILE PATH
#########################################################################################################################

date=`date +%d-%m-%y--%H:%M`
LOG_FILE="/tmp/vdi_${PKG}_$date.txt"

if [ ! -f $LOG_FILE ]; then
    echo > $LOG_FILE
fi
# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee $LOG_FILE)

# Without this, only stdout would be captured - i.e. your
# log file would not contain any error messages.
exec 2>&1

#########################################################################################################################
#                      PARSING PARAMETERS AND SETTING ENV VARIABLES
#########################################################################################################################

FS_PATH=""
DEST_VDI_PATH=""
FILE_TYPE=""

while [ $# -gt 0 ]
do
    case "$1" in
        -f|--fs)
            FS_PATH=$2; shift;;
        -v|--vdi)
            DEST_VDI_PATH=$2; shift;;
        -t| --type)
            FILE_TYPE=$2; shift;;
        -h|--help)
            echo -e "$(basename "$0") - Script to create vdi files"
            echo -e
            echo -e "Usage: $(basename "$0") -t <type> -v <vdi-path> [-f <fs-path>]."
            echo -e ""
            echo -e "Passing VDI file and Type parameters are must. FS File paths are must if type is of 'root','prebundled' or 'update' type."
            echo -e "For 'sdcard' and 'data' file types, FS File argument is not necessary as their corresponding VDIs are generally empty."
            echo -e ""
            echo -e "Sample usage scenarios can be:"
            echo -e "1) To create Root.vdi file from Root.fs"
            echo -e "$(basename "$0") -t root -v /tmp/Root.vdi -f /tmp/Root.fs"
            echo -e "2) To create Prebundled.vdi.bgp file from Prebundled.fs.bgp"
            echo -e "$(basename "$0") -t prebundled -v /tmp/Prebundled.vdi.bgp -f /tmp/Prebundled.fs.bgp"
            echo -e "3) To create blank formatted SDCard.vdi file"
            echo -e "$(basename "$0") -t sdcard -v /tmp/SDCard.vdi"
            echo -e
            echo -e
            echo -e "Options:"
            echo -e "-f, --fs \t\t FS File. Pass this parameter if you want to convert this FS file into VDI."
            echo -e "-t, --type \t\t File Type for which you want to create vdi fil. Valid options are: 'root', 'prebundled', 'sdcard', 'data' and 'update'."
            echo -e "-v, --vdi \t\t Destination VDI File. Final VDI File will be created using this parameter."
            echo -e "-h, --help \t\t Print this message and exit."
            echo -e
            echo -e
            exit 1;;
        -*)
            echo -e "Invalid Option: '$1'"
            echo -e "Usage: $(basename "$0") -t <type> -v <vdi-path> [-f <fs-path>]."
            echo -e ""
            echo -e "Try '$(basename "$0") --help' for more information"
            exit 1;;
        *)
            echo -e "Invalid Option: '$1'"
            echo -e "Usage: $(basename "$0") -t <type> -v <vdi-path> [-f <fs-path>]."
            echo -e ""
            echo -e "Try '$(basename "$0") --help' for more information"
            exit 1;;
    esac
    shift
done

# Both "-t" and "-v" arguments are must
if [[ "$DEST_VDI_PATH" == "" ||  "$FILE_TYPE" == "" ]]; then
    echo ""
    echo "Invalid Option: Both file type (-t) and vdi path (-v) are must."
    echo "Usage: $(basename "$0") -t <type> -v <vdi-path> [-f <fs-path>] "
    echo ""
    echo "Try '$(basename "$0") --help' for more information"
    echo ""
    exit 1
fi

# if file type is of root, prebundled or update, fs_path is must.
if [[ "$FILE_TYPE" != "sdcard" && "$FILE_TYPE" != "data" && "$FS_PATH" == "" ]]; then
    echo ""
    echo "Invalid Option: either not valid FileType '$FILE_TYPE' or FS File path(-f) is must."
    echo ""
    echo "Try '$(basename "$0") --help' for more information"
    echo ""
    exit 1
fi

VDI_BLANK_FILE=""
PARTITION_TYPE=""
DEST_VDI_DIR=`dirname $DEST_VDI_PATH`
SRC_MNT=$DEST_VDI_DIR/fs-to-vdi-src
DST_MNT=$DEST_VDI_DIR/fs-to-vdi-dst

#########################################################################################################################
#                                SCRIPT FUNCTIONS
#########################################################################################################################

function die()
{
    echo "[`date +"%d-%B-%Y %r"`]: ERROR: $@" >&2
    
    # unmount any mounted filesystems
    sudo umount -d $NBD_PART >/dev/null
    
    # unmount the device
	sudo qemu-nbd -d $NBD_DEV > /dev/null
    
    #unmount temporary mount points
    sudo umount -d $SRC_MNT >/dev/null
    sudo umount -d $DST_MNT >/dev/null

    sudo rm -rf $DEST_VDI_PATH
	exit 1
}

function isNBDModuleInserted()
{
    x=`lsmod | grep -i nbd | wc -l`
    if [ "$x" -eq "0" ]; then
        echo "NBD Module is not inserted."
        return 1
    else
        echo "NBD Module is inserted and ready to use."
        return 0
    fi
}

function loadNBDModule()
{
    sudo modprobe nbd max_part=16
    if [ "$?" -eq "0" ]; then
        echo "Check whether NBD module is loaded successfully or not..." 
        isNBDModuleInserted
        return $?
    else
        die "Error in loading NBD module, make sure that this module exist and is in PATH. Also, make sure that packages qemu-kvm, nbd-server are installed on your system."
    fi 
}

function create_vdi()
{
	VDI_FILE=$1

    # Make sure nbd module is inserted.
    isNBDModuleInserted
    if [ "$?" -ne "0" ]; then
        loadNBDModule
        if [ "$?" -ne "0" ]; then
            die "Error in loading NBD module"
        fi
    fi
			
    echo "FS_FILE path: $FS_PATH"
    echo "VDI_FILE:  $VDI_FILE"
   
    # Make a local copy of sample blank vdi file
    cp -ar $VDI_BLANK_FILE $VDI_FILE
    if [ "$?" -ne "0" ]; then
        die "Error in making local copy of $VDI_BLANK_FILE as $VDI_FILE"
    fi

    # Format sample blank vdi file and create partition accordingly.
    prepare_vdi_file $VDI_FILE

    # For RootFS, PrebundleFS and UpdateFS, we need to copy the FS content also.
    if [[ "$FS_PATH" != "" && -f $FS_PATH ]]; then
        copy_fs_to_vdi $FS_PATH
    fi

    # Cleaning up nbd resources 
    sudo qemu-nbd -d $NBD_DEV > /dev/null
    if [ "$?" -ne "0" ]; then
        die "Cannot detach VDI"
    fi
}

function prepare_vdi_file()
{
	VDI_FILE=$1

	sudo qemu-nbd -d $NBD_DEV > /dev/null

	sudo qemu-nbd -c $NBD_DEV $VDI_FILE
    if [ "$?" -ne "0" ]; then
        die "Cannot connect VDI at $VDI_FILE"
    fi

    # Sometimes, it takes couple of seconds to recognize disk partitions
    sleep 2

    sudo modprobe nbd max_part=8 2>/dev/null || true
    sudo parted -s $NBD_DEV mklabel msdos mkpart primary ext4 1MiB 100%
    sleep 1
    sudo partx -u $NBD_DEV 2>/dev/null || true

	if [ $PARTITION_TYPE = "ext4" ]; then
		sudo mke2fs -t ext4 -D -O sparse_super $NBD_PART
        if [ "$?" -ne "0" ]; then
            die "Cannot format $VDI_FILE file partition as ext4 file system"
        fi
	elif [ $PARTITION_TYPE = "vfat" ]; then
		sudo fdisk $NBD_DEV << EOF
t
b
p
w
EOF
		
        if [ "$?" -ne "0" ]; then
            die "Cannot change partition type for file $VDI_FILE"
        fi
		sudo mkfs.vfat $NBD_PART
        if [ "$?" -ne "0" ]; then
            die "Cannot format vfat file system for $VDI_FILE"
        fi
	else
		die "Invalid file system partition type $PARTITION_TYPE for vdi file $VDI_FILE"
	fi
}

function prepare_mountpoint()
{
	MOUNT_DIR=$1

    if [ ! -d $MOUNT_DIR ]; then
        sudo mkdir -p $MOUNT_DIR
        if [ "$?" -ne "0" ]; then
            die "Cannot create mount point $MOUNT_DIR"
        fi
    fi

	mountpoint -q $MOUNT_DIR
	if [ $? -eq 0 ]; then
		sudo umount -d $MOUNT_DIR >/dev/null
        if [ "$?" -ne "0" ]; then
            die "Cannot unmount file system mounted on $MOUNT_DIR"
        fi
	fi
}

function copy_fs_to_vdi()
{
	SOURCE_FS_FILE=$1

	echo "Preparing mount points"
	prepare_mountpoint $SRC_MNT
	prepare_mountpoint $DST_MNT

	echo "Preparing source file systems"
	sudo mount -o dirsync,sync,loop,ro $SOURCE_FS_FILE $SRC_MNT
    if [ "$?" -ne "0" ]; then
        die "Cannot mount $SOURCE_FS_FILE on $SRC_MNT"
    fi

	echo "Preparing target file system"
	sudo mount -o dirsync,sync,rw $NBD_PART $DST_MNT
    if [ "$?" -ne "0" ]; then
        die "Cannot mount $NBD_PART on $path"
    fi

	echo "Copying file system contents"
        PWD_PATH=`pwd`
        # BS-A16: cp -a instead of tar+gzip (both local, saves ~10min)
        sudo cp -a $SRC_MNT/. $DST_MNT/
    if [ "$?" -ne "0" ]; then
        die "Cannot copy file system contents"
    fi

	echo "Finishing up"
	sudo umount -d $SRC_MNT >/dev/null
    if [ "$?" -ne "0" ]; then
        echo "Cannot unmount source file system $SRC_MNT"
    fi
    sudo rm -rf $SRC_MNT >/dev/null
	
    sudo umount -d $DST_MNT >/dev/null
    if [ "$?" -ne "0" ]; then
        echo "Cannot unmount destination file system $DST_MNT"
    fi
    sudo rm -rf $DST_MNT >/dev/null
}

function get_sample_vdi_path()
{
    # Get Sample Blank VDI File Path and partition type
    if [ "$FILE_TYPE" = "root" ]; then
        VDI_BLANK_FILE="$BLANK_VDI_FILES/$IMAGE/Root_Blank.vdi"
        PARTITION_TYPE="ext4"
    elif [ "$FILE_TYPE" = "prebundled" ]; then
        VDI_BLANK_FILE="$BLANK_VDI_FILES/Prebundled_Blank.vdi"
        PARTITION_TYPE="ext4"
    elif [ "$FILE_TYPE" = "sdcard" ]; then
        VDI_BLANK_FILE="$BLANK_VDI_FILES/SDCard_Blank.vdi"
        PARTITION_TYPE="vfat"
    elif [ "$FILE_TYPE" = "data" ]; then
        VDI_BLANK_FILE="$BLANK_VDI_FILES/Data_Blank.vdi"
        PARTITION_TYPE="ext4"
    elif [ "$FILE_TYPE" = "update" ]; then
        VDI_BLANK_FILE="$BLANK_VDI_FILES/Update_Blank.vdi"
        PARTITION_TYPE="ext4"
    else
        echo "Invalid Option for FileType $FILE_TYPE"
        echo "Valid options are: 'root', 'prebundled', 'sdcard', 'data' and 'update'."
        echo ""
        echo "Try '$(basename "$0") --help' for more information"
        echo ""
        exit 1
    fi

    if [ ! -f $VDI_BLANK_FILE ]; then
        echo "Sample Blank vdi file $VDI_BLANK_FILE for file type $FILE_TYPE not present."
        exit 1;
    fi
}

echo
echo "##########################################################################################################################"
echo "[`date +"%d-%B-%Y %r"`]: $(basename "$0") called for $FILE_TYPE vdi, OUTPATH=$DEST_VDI_PATH"
echo "Logfile Path : $LOG_FILE"
echo "##########################################################################################################################"
echo

get_sample_vdi_path

create_vdi $DEST_VDI_PATH
if [ "$?" -ne "0" ]; then
    die "Error in creating vdi file $DEST_VDI_PATH of type $FILE_TYPE"
fi

echo
echo "##########################################################################################################################"
echo "[`date +"%d-%B-%Y %r"`]: VDI file $DEST_VDI_PATH created successfully."
echo "Logfile Path : $LOG_FILE"
echo "##########################################################################################################################"
echo
echo
exit 0
