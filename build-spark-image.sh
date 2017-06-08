#!/bin/bash -e

set -o pipefail

# Build and/or register an image for use with OpenStack sahara using Apache
# Spark on Ubuntu on baremetal.

BUILD=0
REGISTER=0
if [[ $# -gt 0 ]]; then
    if [[ $1 = build ]]; then
        BUILD=1
    elif [[ $1 = register ]]; then
        REGISTER=1
    else
        echo "???"
        exit 1
    fi
else
    BUILD=1
    REGISTER=1
fi

#if [[ ! -d stackhpc-image-elements ]]; then
#    git clone https://github.com/stackhpc/stackhpc-image-elements
#fi
#export ELEMENTS_PATH=$(pwd)/stackhpc-image-elements/elements

if [[ ! -d sahara-image-elements ]]; then
    git clone https://github.com/stackhpc/sahara-image-elements \
        -b stackhpc-6.0.0.1
fi

virtualenv dib-venv
source dib-venv/bin/activate
pip install -U pip
pip install tox

OS_DISTRO=${OS_DISTRO:-ubuntu}
case $OS_DISTRO in
    ubuntu)
        export DIB_RELEASE=${DIB_RELEASE:-trusty}
        ;;
    centos7)
        ;;
    *)
        echo "Unexpected OS_DISTRO $OS_DISTRO"
        exit 1
        ;;
esac

# The following is required for --visibility and --os-distro arguments.
export OS_IMAGE_API_VERSION=2

NAME=${NAME:-sahara-spark-${OS_DISTRO}${DIB_RELEASE:+-${DIB_RELEASE}}}
FILENAME=${FILENAME:-$NAME}

cd sahara-image-elements

if [[ $BUILD -eq 1 ]]; then
    echo "Building image"
    case $OS_DISTRO in
      ubuntu)
        export ubuntu_spark_image_name=${FILENAME}
        ;;
      centos7)
        export centos7_spark_image_name=${FILENAME}
        ;;
    esac
    tox -e venv -- \
      sahara-image-create \
      -p spark \
      -i ${OS_DISTRO} \
      -b
    echo "Built image"
fi

if [[ $REGISTER -eq 1 ]]; then
    echo "Registering images"
    KERNEL_ID=`glance image-create --name ${NAME}-kernel \
                                   --visibility public \
                                   --disk-format=aki \
                                   --container-format=aki \
                                   --file=${FILENAME}.vmlinuz \
                                   | grep id | tr -d '| ' | cut --bytes=3-57`
    RAMDISK_ID=`glance image-create --name ${NAME}-ramdisk \
                                    --visibility public \
                                    --disk-format=ari \
                                    --container-format=ari \
                                    --file=${FILENAME}.initrd \
                                    | grep id |  tr -d '| ' | cut --bytes=3-57`
    BASE_ID=`glance image-create --name ${NAME} \
                                    --os-distro ${OS_DISTRO} \
                                    --visibility public \
                                    --disk-format=qcow2 \
                                    --container-format=bare \
                                    --property kernel_id=$KERNEL_ID \
                                    --property ramdisk_id=$RAMDISK_ID \
                                    --file=${FILENAME}.qcow2 \
                                    | grep -v kernel | grep -v ramdisk \
                                    | grep id | tr -d '| ' | cut --bytes=3-57`
    echo "Registered images"
fi
