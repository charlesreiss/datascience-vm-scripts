#!/bin/bash
#
# VM Setup for CS194-16 Fall 2014
#

CHROOT_DIR=$1
USER=datascience

if [ x$CHROOT_DIR = x ]; then
    HAVE_CHROOT=0
    if [ ! -x /usr/bin/apt-get ]; then
        echo "ERROR: apt-get (and sufficiently Ubuntu-like system) required" >2 
        exit 1
    fi
    if [ `id -u` != 0 ]; then
        echo "ERROR: must be run as root" >2
        exit 1
    fi
    echo "(Running without chroot.)"
    echo ""
    echo "This script will install several software packages. Not all these packages "
    echo "will be installed through apt-get and no removal script is provided. "
    echo ""
    echo "This script has only be tested when used to create our supplied VM images; "
    echo "other use is unsupported."
    echo ""
    echo "Some packages will be installed a user's home directory, please specify, "
    echo "should be specified."
    echo ""
    echo -n "Username to install packages to: "
    read USER
    if [ ! -d /home/$USER ]; then
        echo "Expected home directory for $USER in /home/$USER" >2
        exit 1
    fi
else
    HAVE_CHROOT=1
    if [ ! -d $CHROOT_DIR -o x$CHROOT_DIR = x/ ]; then
        echo "ERROR: Excepting chroot dir to use" >2
        echo "(Execute with no arguments to install locally.)" > 2
        exit 1
    fi

fi

function bind_mount_proc() {
    mount --bind /proc $CHROOT_DIR/proc
}

function umount_proc() {
    umount $CHROOT_DIR/proc
}

function run_in_chroot() {
    if [ x$CHROOT_DIR = x ]; then
        "${@}"
    else
        chroot $CHROOT_DIR "${@}"
    fi
}

function do_apt_get() {
    run_in_chroot apt-get -y \
        -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
        --no-install-recommends "${@}"
}

# This is basic system setup and some preferecnes customization that we assume won't be
# needed/wanted on an already setup VM.
if [ x$HAVE_CHROOT = x1 ]; then
# Initial setup. Some postinst scripts (e.g. openjdk) expect /proc to work.
    bind_mount_proc

# ----------------------
# Basic UI people expect  (debootstrap should start us out with something very minimal)
# This list has not been thoroughly minimized to eliminate dependencies, but note that
# since we use --no-install-recommends, we need to specify more than we might otherwise.
# (--no-install-recommends avoids installing things like libreoffice which would
# make the VM image a lot bigger).
    do_apt_get install ubuntu-minimal systemd-services
    do_apt_get install network-manager network-manager-gnome nm-applet
    do_apt_get install ubuntu-desktop unity-lens-applications unity-lens-files
    do_apt_get install firefox
    do_apt_get install vim-gnome emacs
    do_apt_get install gnome-terminal
    do_apt_get install wget
    do_apt_get install acpi-support cups cups-bsd cups-client \
                       xdg-utils xcursor-themes mousetweaks \
                       im-config indicator-session

# ---------------------
# Automatic login (see https://wiki.ubuntu.com/LightDM)
    mkdir -p $CHROOT_DIR/etc/lightdm/lightdm.conf.d
    cat <<_END_ >$CHROOT_DIR/etc/lightdm/lightdm.conf.d/50-autologin.conf
[SeatDefaults]
autologin-user=datascience
_END_

# Set various default gconf settings for all new users.

# - Set applications in the unity launcher to something that includes gnome-terminal
# - Turn on "privacy" setting for dashboard searches
# - Disable screen locking/screen saver
    cat <<_END_ >$CHROOT_DIR/usr/share/glib-2.0/schemas/30-datascience-defaults.gschema.override
[com.canonical.Unity.Launcher]
favorites=['application://ubiquity.desktop','application://nautilus.desktop','application://gnome-terminal.desktop','application://firefox.desktop','application://unity-control-center.desktop','unity://running-apps','unity://expo-icon','unity://devices']

[com.canonical.Unity.Lenses]
remote-content-search=none

[org.gnome.desktop.screensaver]
lock-enabled=false
idle-activation-enabled=false
_END_

    run_in_chroot glib-compile-schemas /usr/share/glib-2.0/schemas

fi

# ----------------------
# Basic development packages
do_apt_get install \
    build-essential \
    git

# ----------------------
# Basic packages
do_apt_get install \
    python-setuptools \
    python-dev \
    python-pip \
    python-matplotlib \
    python-numpy

do_apt_get install libopenblas-base libopenblas-dev

# Lab 5
do_apt_get install python-scipy

# We do not install any of these through apt-get because we want more
# recent versions of them.
run_in_chroot pip install --allow-external -U scikit-learn panads ipython pyzmg jinja2 tornado

# --------------------
# Packages for specific assignemnts
# OpenRefine
do_apt_get install openjdk-7-jre # Install the full JDK because BIDMach wants it.
run_in_chroot mkdir -p /home/$USER/refine
run_in_chroot wget -O /tmp/refine.tar.gz https://github.com/OpenRefine/OpenRefine/releases/download/2.5/google-refine-2.5-r2407.tar.gz
run_in_chroot tar -C /home/datascience/refine -zxvf /tmp/refine.tar.gz
run_in_chroot chown -R $USER:$USER /home/$USER/refine
run_in_chroot rm /tmp/refine.tar.gz

# Lab 4
do_apt_get install python-levenshtien


# Lab 6
do_apt_get install r-base

# Homework 2
do_apt_get install graphviz
run_in_chroot pip install -U pydot

# Homework 3
do_apt_get install wget
run_in_chroot wget -O /tmp/spark.tgz http://d3kbcqa49mib13.cloudfront.net/spark-1.0.2-bin-cdh4.tgz 
run_in_chroot tar -C /home/datascience -zxvf /tmp/spark.tgz
run_in_chroot rm /tmp/spark.tgz

# BIDMach
if [ x`dpkg --print-architecture` = xamd64 ]; then 
    BID_MACH_ARCHIVE=http://bid2.berkeley.edu/bid-data-project/BIDMach_0.9.0-linux-x86_64-full.tar.gz
    BID_MACH_NAME=BIDMach_0.9.0-linux-x86_64
else
    BID_MACH_ARCHIVE=none
    BID_MACH_NAME=none
    echo "WARNING: No BIDMach binary package available for `dpkg --print-architecture`" >2
fi

if [ x$BID_MACH_ARCHIVE != none ]; then
    run_in_chroot wget -O /tmp/BIDMach.tar.gz http://bid2.berkeley.edu/bid-data-project/BIDMach_0.9.0-linux-x86_64-full.tar.gz
    run_in_chroot mkdir -p /opt
    run_in_chroot tar -C /opt -zxvf /tmp/BIDMach.tar.gz
    run_in_chroot ln -s BIDMach_0.9.0-linux-x86_64 /opt/BIDMach
    run_in_chroot mkdir -p /usr/local/bin
    run_in_chroot ln -s /opt/BIDMach/bin/bidmach /usr/local/bin/bidmach
fi

run_in_chroot chown -R $USER:$USER /home/$USER


if [ x$HAVE_CHROOT = x1 ]; then
# -----------------
# Cleanup.
    umount_proc

# -----------------
# Disable apt-proxy that might've been set by vmbuilder. All "real" apt conf should be apt.conf.d files.
    run_in_chroot rm /etc/apt/apt.conf
fi
