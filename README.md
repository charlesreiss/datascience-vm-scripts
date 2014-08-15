Scripts for creating VMs suitable for UCB CS194 datascience course.

These scripts require a Ubuntu-like system with a slightly bugfixed version of python-vm-builder, which you
can get by applying `vmbuilder.diff` to a bzr checkout of lp:vmbuilder. [Hopefully these changes will be merged
into trunk soon.]

Configuration is run using a file called `make-vm-config.sh`. An example is in make-vm-config.sh.example.

The primary script is `make-vm.sh`; if run it should create virtualbox VMs in datascience-vm-amd64 and
datascience-vm-i386. This script has some configuration in it which should be split out into a separate
file. The result will be a directory containing an opaquely named VDI image for VirtualBox and a script
to load that VM (locally) into virtualbox.

The created VMs are essentially stock Ubuntu 14.04 VMs with post-build-script.sh to install extra software.

The created VMs should have a user with sudo rights called 'datascience' with password 'datascience'.
The VM will be configured to automatically login to that account botting into the graphical environment.
