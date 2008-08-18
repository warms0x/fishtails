#!/bin/sh
#
# Copyright (c) 2008 Rene Maroufi
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
# This script creates a backup of modified files in /etc, /var and /root.

sub_backup() {
   find /etc /var /root -newer /etc/timemark ! -type s ! -type p | cpio -o > /mnt/sys.cio
}

mount | grep mnt
if [ $? -eq 0 ]
then
   echo "Something is already mounted on /mnt!" >&2
   echo "Please umount /mnt first and then try again!" >&2
   exit 1
fi

echo "This script overwrites previously written (old) backup data!"
echo -n "Which device is your USB drive (without '/dev/', e.g. 'sd0')? "
read usb

flag=0
disklabel "${usb}" 2>/dev/null | grep MSDOS | grep i: >/dev/null
if [ $? -eq 0 ]
then
   mount_msdos /dev/"${usb}"i /mnt
   sub_backup
   umount /mnt
   flag=1
fi
if [ "$flag" -eq 0 ]
then
   disklabel "${usb}" 2>/dev/null | grep 4.2BSD | grep a: >/dev/null
   if [ $? -eq 0 ]
   then
      mount /dev/"${usb}"a /mnt
      sub_backup
      umount /mnt
   else
      echo "Can't find partition on device!" >&2
      exit 3
   fi
fi
