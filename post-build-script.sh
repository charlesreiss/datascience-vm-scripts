#!/bin/bash
CHROOT_DIR=$1

function bind_mount_proc() {
    mount --bind /proc $CHROOT_DIR/proc
}

function umount_proc() {
    umount $CHROOT_DIR/proc
}

function run_in_chroot() {
    chroot $CHROOT_DIR "${@}"
}

function do_apt_get() {
    run_in_chroot apt-get -y --no-install-recommends "${@}"
}

# Initial setup. Some postinst scripts (e.g. openjdk) expect /proc to work.
bind_mount_proc

# ----------------------
# Basic UI people expect  (debootstrap should start us out with something very minimal)
run_in_chroot ucf --purge /etc/sudoers
do_apt_get install sudo
do_apt_get install ubuntu-desktop
do_apt_get install firefox
do_apt_get install gnome-terminal
do_apt_get install network-manager network-manager-gnome nm-applet
do_apt_get install wget
do_apt_get install acpi-support cups cups-bsd cups-client \
                   xdg-utils xcursor-themes mousetweaks \
                   im-config indicator-session

# Set applications in the unity launcher to something that includes gnome-terminal
run_in_chroot gsettings set com.canonical.Unity.Launcher favorites "['application://ubiquity.desktop','application://nautilus.desktop','application://gnome-terminal.desktop','application://unity-control-center.desktop','unity://running-apps','unity://expo-icon','unity://devices']"

# Turn on "privacy" setting for dashboard searches
run_in_chroot gsettings set com.canonical.Unity.Lenses remote-content-search none


# ---------------------
# Automatic login (see https://wiki.ubuntu.com/LightDM)
mkdir -p $CHROOT_DIR/etc/lightdm/lightdm.conf.d
cat <<_END_ >$CHROOT_DIR/etc/lightdm/lightdm.conf.d/50-autologin.conf
[SeatDefaults]
autologin-user=datascience
_END_

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

# We do not install any of these through apt-get because we want more
# recent versions of them.
run_in_chroot pip install -U scikit-learn panads ipython pyzmg jinja2 tornado

# --------------------
# Packages for specific assignemnts
# OpenRefine
do_apt_get install openjdk-7-jre-headless
run_in_chroot mkdir -p /home/datascience/refine
run_in_chroot wget -O /tmp/refine.tar.gz https://github.com/OpenRefine/OpenRefine/releases/download/2.5/google-refine-2.5-r2407.tar.gz
run_in_chroot tar -C /home/datascience/refine -zxvf google-refine-2.5-r2407.tar.gz
run_in_chroot chown -R datascience:datascience /home/datascience/refine
run_in_chroot rm /tmp/refine.tar.gz

# Lab 4
do_apt_get install python-levenshtien

# Lab 5
do_apt_get install python-scipy

# Lab 6
do_apt_get install r-base

# Homework 2
do_apt_get install graphviz
run_in_chroot pip install -U pydot

# Homework 3
do_apt_get install wget
run_in_chroot wget -O /tmp/spark.tgz http://d3kbcqa49mib13.cloudfront.net/spark-1.0.2-bin-cdh4.tgz 
run_in_chroot tar -C /home/datascience /tmp/spark.tgz
run_in_chroot rm /tmp/spark.tgz

# -----------------
# Cleanup.
umount_proc
