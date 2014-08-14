#!/bin/bash

set -x
set -e

MIRROR=http://us.archive.ubuntu.com/ubuntu
SCRIPT_DIR=$PWD
VMBUILDER=../vmbuilder/vmbuilder
DIST=trusty
EXTRA_OPTS=--proxy=http://localhost:3142/
TARGET_USER=charles

#for ARCH in amd64 i386; do
for ARCH in amd64; do
#for ARCH in i386; do
    if [ -e $SCRIPT_DIR/debootstrap-${ARCH}-${DIST}.tgz ]; then
        DEBOOT_ARG="--debootstrap-tarball=$SCRIPT_DIR/debootstrap-${ARCH}-${DIST}.tgz"
    else
        DEBOOT_ARG=
    fi
    # We specify linux-image-virtual via addpkg to make sure it gets installed in the chroot
    # while /proc is bind-mounted. (The postinst script for the kernel package looks at
    # /proc/cpuinfo and will complain if it doesn't contain PAE in CPU flags.)
    $VMBUILDER vbox ubuntu \
        $DEBOOT_ARG \
        $EXTRA_OPTS \
        --destdir=./datascience-vm-$ARCH \
        --hostname=datascience-$ARCH \
        --verbose \
        --debug \
        --user=datascience \
        --name='Datascience Course Student' \
        --pass=datascience \
        --part=$SCRIPT_DIR/partitions.txt \
        --suite=$DIST \
        --variant=buildd \
        --components=main,universe,multiverse \
        --addpkg=linux-image-virtual \
        --addpkg=dkms \
        --addpkg=virtualbox-guest-utils \
        --addpkg=virtualbox-guest-x11 \
        --addpkg=virtualbox-guest-dkms \
        --mirror=$MIRROR \
        --lang=en_US.UTF-8 \
        --timezone=America/Los_Angeles \
        --execscript=$SCRIPT_DIR/post-build-script.sh \
        --firstboot=$SCRIPT_DIR/first-boot-script.sh \
        --seedfile=$SCRIPT_DIR/seedfile.conf \
        --mem=1024 \
        --cpus=1 \
        --mac= \
        --arch=$ARCH 2>&1 | tee -a log
    chown -R $TARGET_USER:$TARGET_USER ./datascience-vm-$ARCH
done
