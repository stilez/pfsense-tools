#!/bin/sh

# pfSense master builder script
# (C)2005-2006 Scott Ullrich and the pfSense project
# All rights reserved.
#
# $Id$

set -e -u

chflags -R noschg /usr/local/pfsense*
rm -rf /usr/local/pfsense*

# If a full build has been performed we need to nuke
# /usr/obj.pfSense/ since embedded uses a different
# make.conf
if [ -f /usr/obj.pfSense/pfSense.6.world.done ]; then
	echo -n "Removing /usr/obj* since full build performed prior..."
	rm -rf /usr/obj*
	echo "done."
fi

# Suck in local vars
. ./pfsense_local.sh

# Suck in script helper functions
. ./builder_common.sh

# Use pfSense_wrap.6 as kernel configuration file
export KERNELCONF=${KERNELCONF:-${PWD}/conf/pfSense_wrap.6}
if [ $pfSense_version = "7" ]; then
	export KERNELCONF=${KERNELCONF:-${PWD}/conf/pfSense_wrap.7}
fi

export NO_COMPRESSEDFS=yes
export PRUNE_LIST="${PWD}/remove.list"
if [ $pfSense_version = "7" ]; then
	export PRUNE_LIST="${PWD}/remove.list.7"
fi

# Use embedded make.conf
export MAKE_CONF="${PWD}/conf/make.conf.embedded"
if [ $pfSense_version = "7" ]; then
        export MAKE_CONF="${PWD}/conf/make.conf.embedded.7"
fi

export EXTRA=""

# Clean out directories
freesbie_make cleandir

# Checkout a fresh copy from pfsense cvs depot
#update_cvs_depot

# Calculate versions
version_kernel=`cat $CVS_CO_DIR/etc/version_kernel`
version_base=`cat $CVS_CO_DIR/etc/version_base`
version=`cat $CVS_CO_DIR/etc/version`

# Build if needed and install world and kernel
make_world_kernel

if [ $pfSense_version = "7" ]; then
        export MAKE_CONF="${PWD}/conf/make.conf.embedded.7.install"
fi

# Add extra files such as buildtime of version, bsnmpd, etc.
#populate_extra

# No need for packages
rm -f conf/packages

#fixup_wrap

# Invoke FreeSBIE2 toolchain
freesbie_make clonefs

# Fixup library changes if needed
fixup_libmap

echo ${CLONEDIR}

create_FreeBSD_system_update
