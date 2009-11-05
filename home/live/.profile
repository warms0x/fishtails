# $OpenBSD: dot.profile,v 1.4 2005/02/16 06:56:57 matthieu Exp $
#
# sh/ksh initialization

PATH=$HOME/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/usr/local/bin:/usr/local/sbin:/usr/games:.
export PATH HOME TERM

export ENV=$HOME/.kshrc
export PS1='\u@\h:\w$ '

# Ask for invokation of restore script on login of 'live'.
sub_dorestore() {
   if [ -r /mnt/BSDanywhere.tgz ]
   then
      tar xzpf /mnt/BSDanywhere.tgz -C /home/live
   else
      echo "Backup data not found, restored nothing!"
   fi
}

liverestore() {
   usbdevs -d | grep umass >/dev/null
   if [ $? -eq 0 ]
   then
      echo -n "Restore data from a USB drive (y/N)? "
      read restore
      if [ ! -z $restore ]
      then
         if [ "$restore" = "y" ] || [ "$restore" = "yes" ] || [ "$restore" = "Y" ] || [ "$restore" = "YES" ] || [ "$restore" = "Yes" ]
         then
            echo -n "Which is your USB drive (e.g. 'sd0')? "
            read usb
            flag=0
            disklabel "${usb}" 2>/dev/null | grep MSDOS | grep i: >/dev/null
            if [ $? -eq 0 ]
            then
               sudo mount_msdos /dev/"${usb}"i /mnt
               sub_dorestore
               sudo umount /mnt
               flag=1
            fi
            if [ $flag -eq 0 ]
            then
               disklabel "${usb}" 2>/dev/null | grep 4.2BSD | grep a: >/dev/null
               if [ $? -eq 0 ]
               then
                  sudo mount /dev/"${usb}"a /mnt
                  sub_dorestore
                  sudo umount /mnt
               else
                  echo "Can't find valid partition on device: no data restored!"
               fi
            fi
         fi
      fi
   fi
}

# don't run restore or X for tmux and ssh sessions
([ "$TMUX" ] || [ "$SSH_CLIENT" ]) || (liverestore; startx)
