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
# This script restores /etc, /var and /root during BSDanywhere's system boot.

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
      STATUS=2
   fi
}

STATUS=0

usbdevs -d | grep umass >/dev/null
if [ $? -eq 0 ]
then
   echo "A USB device has been found. To restore previously saved system data"
   echo -n "specify a drive without /dev and partition (e.g. 'sd0') or 'no': "

   read usbs
   if [ "$usbs" = "n" ] || [ "$usbs" = "no" ] || [ "$usbs" = "No" ] || [ "$usbs" = "NO" ] || [ "$usbs" = "N" ]
   then
      exit 0
   fi

   SFLAG=0

   disklabel "${usbs}" 2>/dev/null | grep MSDOS | grep i: >/dev/null
   if [ $? -eq 0 ]
   then
      mount_msdos /dev/"${usbs}"i /mnt
      SFLAG=1
      sub_restore
      umount /mnt
   fi

   disklabel "${usbs}" 2>/dev/null | grep 4.2BSD | grep a: >/dev/null
   if [ $? -eq 0 ]
   then
      mount /dev/"${usbs}"a /mnt
      SFLAG=1
      sub_restore
      umount /mnt
   fi

   if [ $SFLAG -eq 0 ]
   then
      echo "Can't find partition!" >&2
      STATUS=1
   fi
fi

exit $STATUS
