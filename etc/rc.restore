#!/bin/sh
#
# Copyright (c) 2008 Rene Maroufi, Stephan A. Rickauer
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# This script restores /etc, /var and /root during BSDanywhere's system boot.

#
### Functions go first
#

sub_restore() {
   if [ -r /mnt/sys.cio ]
   then
      cd /
      echo -n 'Restoring data ... '
      cpio -iu < /mnt/sys.cio
      >/tmp/restore
      echo done
   else
      echo "Can't find sys.cio!" >&2
      exit 2
   fi
}

sub_umount() {
   echo -n "Attempting to unmount ${device} ... "
   umount /mnt \
       && echo done || echo failed
}

sub_bsdmount() {
    echo -n "Attempting to mount BSD partition ${device} ... "
    mount /dev/"${device}"a /mnt \
        && echo done || echo failed
}

sub_msdosmount() {
   echo -n "Attempting to mount MSDOS partition ${device} ... "
   mount_msdos /dev/"${device}"i /mnt \
       && echo done || echo failed
}

sub_find_umass() {
    $(usbdevs -d | grep umass) || exit 1
}

#
### Main
#

sub_find_umass

echo "A USB device has been found. To restore previously saved system data"
echo -n "specify a drive without /dev and partition (e.g. 'sd1') or 'no': "

read device
device=$(echo $device | tr '[:upper:]' '[:lower:]')

if [ "$device" = "n" ] || [ "$device" = "no" ] || [ -z "$device" ]
then
   exit 0
fi

disklabel "${device}" 2>/dev/null | grep MSDOS | grep i: >/dev/null \
    && fs=msdos

disklabel "${device}" 2>/dev/null | grep 4.2BSD | grep a: >/dev/null \
    && fs=bsd

if [ "$fs" ]; then
    sub_$fs\mount
else
    echo "Can't find usable partition on device!" >&2
    exit 3
fi

sub_restore
sub_umount
