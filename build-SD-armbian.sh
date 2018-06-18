#!/bin/bash

# Batch creation of NextCloudPi Armbian based images
#
# Copyleft 2018 by Ignacio Nunez Hernanz <nacho _a_t_ ownyourbits _d_o_t_ com>
# GPL licensed (see end of file) * Use at your own risk!
#
# Usage: ./build-SD-armbian.sh <board_code> [<board_name>]
#

#CLEAN=1                    # Pass this envvar to clean download cache
BOARD="$1"
BNAME="${2:-$1}"

IMG="NextCloudPi_${BNAME}_$( date  "+%m-%d-%y" ).img"
IMG=tmp/"$IMG"

set -e
source buildlib.sh

prepare_dirs                   # tmp cache output

# get latest armbian
[[ -d armbian ]] || git clone https://github.com/armbian/build armbian
( cd armbian && git pull --ff-only --tags )

# get NCP modifications
mkdir -p armbian/userpatches
wget https://raw.githubusercontent.com/nextcloud/nextcloudpi/master/armbian.sh \
  -O armbian/userpatches/customize-image.sh

# GENERATE IMAGE

# default parameters
cat > armbian/config-docker-guest.conf <<EOF
BOARD="$BOARD"
BRANCH=default
RELEASE=stretch
KERNEL_ONLY=no
KERNEL_CONFIGURE=no
BUILD_DESKTOP=no
CLEAN_LEVEL=""
USE_CCACHE=yes
EOF

# board specific parameters
CONF="config-$BOARD".conf
[[ -f "$CONF" ]] && cat "$CONF" >> armbian/config-docker-guest.conf

# build
armbian/compile.sh docker

mv armbian/output/images/Armbian*.img "$IMG"

# pack image
TAR=output/"$( basename "$IMG" .img ).tar.bz2"
pack_image "$IMG" "$TAR"

# test
# TODO

# upload
create_torrent "$TAR"
upload_ftp "$( basename "$TAR" .tar.bz2 )"