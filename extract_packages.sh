#!/bin/bash
set -e

BIN_URL=${1}
ARCH=${2:-"amd64"}
wget $BIN_URL -O fwupdate.bin
sudo binwalk -e fwupdate.bin

dpkg-query --admindir=_fwupdate.bin.extracted/squashfs-root/var/lib/dpkg/ -W -f='${package} | ${Maintainer}\n' | grep -E "@ubnt.com|@ui.com" | cut -d "|" -f 1 > packages.txt

while read pkg; do
  dpkg-repack --root=_fwupdate.bin.extracted/squashfs-root/ --arch=$ARCH ${pkg}
done < packages.txt