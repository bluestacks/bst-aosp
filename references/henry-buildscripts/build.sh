# !/bin/bash

# This build script is used by JENKIN to automate build process
# In theory this should be equivalent to automate_kk.sh script but
# we need to set correct values using jenkin parameters.
# Also, don't forget to unset variables set in Jenkin script to make
# sure that those values don't impact local variables used in other scripts.

set -x

BUILD_SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASEPATH="$(dirname "$BUILD_SCRIPT_PATH")"
ANDROID="$BASEPATH/android"      # Location where android.git is cloned for this branch.
ANDROID_9="$BASEPATH/android-9"      # Location where android-9.git is cloned for this branch.
ANDROID_11="$BASEPATH/android-11"      # Location where android-11.git is cloned for this branch.
ANDROID_13="$BASEPATH/android-13"      # Location where android-13.git is cloned for this branch.
ANDROID_16="$BASEPATH/android-16"      # Location where android-16.git is cloned for this branch.
ANDROID_SDK_PATH="${ANDROID_SDK_PATH:-/home/build/workspace/android-sdk/sdk}"
CREATE_ANDROID_BUILD=1
JENKIN_BUILD_ERROR=0

JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
CCACHE_BIN_PATH="$ANDROID/prebuilts/misc/linux-x86/ccache/ccache"
SYNC_SCRIPT="$BUILD_SCRIPT_PATH/sync.sh"
MAKE_SCRIPT="$BUILD_SCRIPT_PATH/Makefile"
total_processors=$(nproc)
if [[ -z "${PARALLEL_NX_PROCESSORS_BUILD_SH}" ]]; then
    numproc="$(expr $total_processors \* 2)"
else
    numproc=$(echo "($total_processors * $PARALLEL_NX_PROCESSORS_BUILD_SH)/1" | bc)
fi

OEM_hyperv_build_hyperv=1
OEM_bgp64_hyperv_build_hyperv=1
OEM_msi64_hyperv_build_hyperv=1
#########################################################################################################################
#                      SETTING ENVIRONMENT SPECIFIC VARIABLES
#########################################################################################################################

PATH="$BUILD_SCRIPT_PATH/bin:$PATH:/home/build/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export JAVA_HOME=$JAVA_HOME
export USER=$(whoami)
export PATH="$PATH":"$ANDROID_SDK_PATH/tools":"$ANDROID_SDK_PATH/platform-tools":"$JAVA_HOME/bin"
export USE_CCACHE=1

if [ -z "$BRANCH" ]; then
    echo "Branch not set hence exiting."
    exit 1
fi

if [ -z "$OEM" ]; then
    echo "Oem not set hence exiting."
    exit 1
fi

if [ -z "$ANDROID_IMAGES" ]; then
    echo "Image to build not set hence exiting."
    exit 1
fi

GIT_BRANCH="$BRANCH"
BUILD_WITH_DEXPREOPT=$ENABLE_DEXOPT
CLEAN_BUILD=$FORCE_CLEAN

#########################################################################################################################
#                      SETTING AND EXPORTING LOGFILE PATH
#########################################################################################################################

date=`date +%d-%m-%y--%H:%M`
if [ "$BUILD_TAG" == "" ]; then
    # In case jenkin.sh is run by hand or w/o jenkin interface, we will not get the jenkin env value BUILD_TAG (Nightly build case).
    JENKIN_LOG_FILE="/tmp/${GIT_BRANCH}_$date.txt"
    BUILD_DESCRIPTION=${GIT_BRANCH}
else
    JENKIN_LOG_FILE="/tmp/$(echo $BUILD_TAG | sed "s/ /_/g")_${GIT_BRANCH}_$date.txt"
    BUILD_DESCRIPTION=${JOB_NAME}_${ANDROID_BUILD_NUMBER}_${GIT_BRANCH}
fi
export BUILD_DESCRIPTION

echo > $JENKIN_LOG_FILE
# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee $JENKIN_LOG_FILE)

# Without this, only stdout would be captured - i.e. your
# log file would not contain any error messages.
exec 2>&1

export JENKIN_LOG_FILE

if [ $CLEAN_BUILD == "true" ]; then
    for IMAGE in $(echo $ANDROID_IMAGES | sed "s/,/ /g")
    do
        echo "Clearing Android out folder, Android location: $ANDROID"
        rm -rf "${ANDROID}/out_${OEM}_${IMAGE}"
        if [ "$?" -ne "0" ]; then
            echo "Error in removing ${ANDROID}/out_${OEM}_${IMAGE} folder, please check the logs at $JENKIN_LOG_FILE"
            JENKIN_BUILD_ERROR=1
            exit 1
        fi
        echo "Clearing Android out folder, Android location: $ANDROID_9"
        rm -rf "${ANDROID_9}/out_${OEM}_${IMAGE}"
        if [ "$?" -ne "0" ]; then
            echo "Error in removing ${ANDROID_9}/out_${OEM}_${IMAGE} folder, please check the logs at $JENKIN_LOG_FILE"
            JENKIN_BUILD_ERROR=1
            exit 1
        fi
        echo "Clearing Android out folder, Android location: $ANDROID_11"
        rm -rf "${ANDROID_11}/out_${OEM}_${IMAGE}"
        if [ "$?" -ne "0" ]; then
            echo "Error in removing ${ANDROID_11}/out_${OEM}_${IMAGE} folder, please check the logs at $JENKIN_LOG_FILE"
            JENKIN_BUILD_ERROR=1
            exit 1
        fi
        echo "Clearing Android out folder, Android location: $ANDROID_13"
        rm -rf "${ANDROID_13}/out_${OEM}_${IMAGE}"
        if [ "$?" -ne "0" ]; then
            echo "Error in removing ${ANDROID_13}/out_${OEM}_${IMAGE} folder, please check the logs at $JENKIN_LOG_FILE"
            JENKIN_BUILD_ERROR=1
            exit 1
        fi
        echo "Clearing Android out folder, Android location: $ANDROID_16"
        rm -rf "${ANDROID_16}/out_${OEM}_${IMAGE}"
        if [ "$?" -ne "0" ]; then
            echo "Error in removing ${ANDROID_16}/out_${OEM}_${IMAGE} folder, please check the logs at $JENKIN_LOG_FILE"
            JENKIN_BUILD_ERROR=1
            exit 1
        fi
    done
fi

#Enabling building of Hyper-v components by default.

ANDROID_IMAGES=$ANDROID_IMAGES

# Set BUILD_WITH_DEXPREOPT to true if we want to enable dexpreopt in build
# so that oat,art files are created in build.
if [ "$BUILD_WITH_DEXPREOPT" == "" ]; then
    BUILD_WITH_DEXPREOPT=true
fi

function finish ()
{
    if [ $JENKIN_BUILD_ERROR -gt 0 ]; then
        exit 1;
    fi
}

function user_finish ()
{
    echo "Caught a signal, exiting without sending an email"
    trap EXIT
    exit 1;
}

trap finish EXIT
trap user_finish 1 2 3 15 # SIGHUP SIGINT SIGQUIT SIGTERM

#########################################################################################################################
#                      SETTING SCRIPT SPECIFIC VARIABLES USING JENKIN VARIABLES
#########################################################################################################################

JENKIN_OEM=$(echo $OEM)
export JENKIN_ANDROID_IMAGES=$(echo $ANDROID_IMAGES)

#########################################################################################################################
#   UNSET JENKINS SPECIFIC VARIABLES AND ENVIORNMENT SO THAT THEY DON't INTERFERE WITH OTHER SCRIPTS VARIABLE VALUES
#########################################################################################################################

unset OEM
unset BRANCH
unset ANDROID_NODE
unset WINDOWS_MACHINE
unset FORCE_CLEAN
unset ENABLE_DEXOPT
unset ANDROID_IMAGES

#########################################################################################################################
#                       SETTING MORE SCRIPT SPECIFIC INTERNAL VARIABLES
#########################################################################################################################

echo "==========================================================================================================================================="
echo [`date +"%d-%B-%Y %r"`]: Starting build using JENKIN for branch "$GIT_BRANCH" and "for OEMS $JENKIN_OEM"
echo "==========================================================================================================================================="
start_time="$(date +%s)"

echo "PATH: $PATH"
echo "env: `env`"


#########################################################################################################################
#                       SYNC SOURCE CODE
#########################################################################################################################
if [[ -z "${SYNC_SOURCE_CODE}" || $SYNC_SOURCE_CODE == "true" ]]; then
    cd $BUILD_SCRIPT_PATH
    echo ""
    echo "[`date +"%d-%B-%Y %r"`]: Starting syncing the source code"
    echo ""
    if [ $CLEAN_BUILD == "true" ]; then
        bash -x $SYNC_SCRIPT --branch "$GIT_BRANCH" --clean-build 1
    else
        bash -x $SYNC_SCRIPT --branch "$GIT_BRANCH"
    fi
    if [ "$?" -ne "0" ]; then
        echo "failed in pulling latest source files"
        exit 1
    fi

    echo ""
    echo "[`date +"%d-%B-%Y %r"`]: Code sync completed successfully"
    echo ""
fi

#########################################################################################################################
#                       BUILD ANDROID COMPONENTS AND BINARIES
#########################################################################################################################

OUTPUTDIR_PREFIX="${OUTPUTDIR_PREFIX:-/home/build/workspace/releases}"
if [ -n "${ANDROIDOUTPUTLOC:-}" ]; then
    :
else
    ANDROIDOUTPUTLOC="$OUTPUTDIR_PREFIX/$GIT_BRANCH-$ANDROID_BUILD_NUMBER"
fi

echo ""
echo "[`date +"%d-%B-%Y %r"`]: Running make script"
echo ""
cd $BUILD_SCRIPT_PATH


for IMAGE in $(echo $JENKIN_ANDROID_IMAGES | sed "s/,/ /g")
do
    PKG="$GIT_BRANCH"_"$IMAGE"-"$ANDROID_BUILD_NUMBER"
    export CCACHE_DIR="${CCACHE_BASE:-/home/build/.ccache}/$IMAGE"
    mkdir -p "$CCACHE_DIR"
    if [ -f $CCACHE_BIN_PATH ]; then
        $CCACHE_BIN_PATH -M 50G
        $CCACHE_BIN_PATH -F 0
    fi
    if [[ "$IMAGE" == *_hyperv ]]; then
        IS_HYPERV_BUILD=1
        MAKE_BUILD_TARGET=kernel_and_initrd
        IMAGE=$(echo "$IMAGE" | cut -d'_' -f1)
        PKG="$GIT_BRANCH"_"$IMAGE"-"$ANDROID_BUILD_NUMBER"
    else
        MAKE_BUILD_TARGET=vbox
        IS_HYPERV_BUILD=0
    fi

    make -j$numproc -f $MAKE_SCRIPT $MAKE_BUILD_TARGET OEM=$JENKIN_OEM IMAGE="$IMAGE" ANDROIDOUTPUTLOC="$ANDROIDOUTPUTLOC" PKG="$PKG" ENABLE_DEXOPT=$BUILD_WITH_DEXPREOPT IS_HYPERV_BUILD=$IS_HYPERV_BUILD PARALLEL_NX_PROC="$PARALLEL_NX_PROCESSORS_MAKEFILE" ANDROID_SDK_PATH="$ANDROID_SDK_PATH" $2>&1
    if [ "$?" -ne "0" ]; then
        echo "Possible error in building Android side components for Image $IMAGE, please check the logs at $JENKIN_LOG_FILE"
        JENKIN_BUILD_ERROR=1
        exit 1
    fi

    echo ""
    echo ============== Build for Image $IMAGE completed succesfully ==================
    echo "[`date +"%d-%B-%Y %r"`]: Completed building Android components and binaries"
    echo ""
done

bash -x $BUILD_SCRIPT_PATH/create_zips.sh --branch $GIT_BRANCH --build-number $ANDROID_BUILD_NUMBER --images $JENKIN_ANDROID_IMAGES --oem $JENKIN_OEM

end_time="$(date +%s)"
elapsed_secs="$(expr $end_time - $start_time)"

echo Elapsed secs: $elapsed_secs

remainder="$(expr $elapsed_secs % 3600)"
hours="$(expr $elapsed_secs / 3600)"
seconds="$(expr $remainder % 60)"
minutes="$(expr $remainder / 60)"


echo
echo
echo ============= Jenkin Build Completed Successfully==================
echo ============= [`date +"%d-%B-%Y %r"`]: Done ======================
echo Elapsed time: $hours:$minutes:$seconds
echo ===================================================================
echo

