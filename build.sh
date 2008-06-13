# $Id$
#
# Build script for creating the BSDanywhere OpenBSD Live CD image.
#
# Copyright (c) 2008  Rene Maroufi, Stephan A. Rickauer
#
# All rights reserved.
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Variables
export RELEASE=4.3
export ARCH=i386
export R=$(echo $RELEASE | awk -F. '{print $1$2 }')
export LOCAL_ROOT=/home/livecd
export MASTER_SITES=http://mirror.startek.ch
export PKG_PATH=http://mirror.switch.ch/ftp/pub/OpenBSD/$RELEASE/packages/$ARCH/:$MASTER_SITES/OpenBSD/pkg/$ARCH/e17/

mkdir $LOCAL_ROOT

# Get custom kernels
install_custom_kernels() {
    for i in bsd bsd.mp
    do
        ftp -o $LOCAL_ROOT/$i $MASTER_SITES/BSDanywhere/$RELEASE/$ARCH/$i
    done
}

# Get boot loaders and ram disk kernel
install_boot_files() {
    for i in cdbr cdboot bsd.rd
    do
        ftp -o $LOCAL_ROOT/$i $MASTER_SITES/OpenBSD/stable/$RELEASE-stable/$ARCH/$i
    done
}

# Get all file sets except comp$$.tgz
install_filesets() {
    for i in base game man misc etc xbase xetc xfont xserv xshare
    do
        ftp -o - $MASTER_SITES/OpenBSD/stable/$RELEASE-stable/$ARCH/$i$R.tgz |\
            tar -C $LOCAL_ROOT -xzphf -
    done
}

# Create mfs directories and devices
prepare_filesystem() {
    mkdir -p $LOCAL_ROOT/.mdev $LOCAL_ROOT/.msbin $LOCAL_ROOT/.mbin $LOCAL_ROOT/.musrlocal
    cp $LOCAL_ROOT/dev/MAKEDEV $LOCAL_ROOT/.mdev/
    cd $LOCAL_ROOT/dev && ./MAKEDEV all
    cd $LOCAL_ROOT/.mdev && ./MAKEDEV all
}

install_fstab() {
    cat >$LOCAL_ROOT/etc/fstab <<EOF
swap /tmp mfs rw,auto 0 0
swap /var mfs rw,auto,-P/.mvar,-s=48000 0 0
swap /etc mfs rw,auto,-P/.metc 0 0
swap /root mfs rw,auto,-P/.mroot 0 0
swap /dev mfs rw,auto,-P/.mdev 0 0
swap /home mfs rw,auto,-P/.mhome,-s=200000 0 0
EOF
}

install_custom_kernels
install_boot_files
install_filesets
prepare_filesystem
install_fstab

# Help chroot to resolve
cp /etc/resolv.conf $LOCAL_ROOT/etc/

# Customize system within chroot
chroot $LOCAL_ROOT
ldconfig
echo "livecd.BSDanywhere.org" > /etc/myname
perl -p -i -e 's/noname.my.domain noname/livecd.BSDanywhere.org livecd/g' /etc/hosts
echo "boot /bsd.mp" > /etc/boot.conf
echo "machdep.allowaperture=2" >> /etc/sysctl.conf
touch /fastboot
echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# Create live account without password
useradd -G wheel,operator,dialer -c "BSDanywhere Live CD Account" -d /home/live -k /etc/skel -s /bin/ksh -m live
perl -p -i -e 's/\Qlive:*************:1000\E/live::1000/g' /etc/master.passwd
pwd_mkdb /etc/master.passwd

# Install packages
pkg_add iperf nmap tightvnc-viewer rsync pftop trafshow pwgen hexedit hping mozilla-firefox mozilla-thunderbird gqview bzip2 epdfview ipcalc isearch BitchX imapfilter gimp abiword privoxy tor arping clamav e-20071211p3 audacious mutt-1.5.17p0-sasl-sidebar-compressed screen-4.0.3p1 sleuthkit smartmontools rsnapshot surfraw darkstat aescrypt aiccu amap angst httptunnel hydra iodine minicom nano nbtscan nepim netfwd netpipe ngrep

# Add welcome screen output to /etc/rc
RC=/etc/rc
perl -p -i -e 's#^rm -f /fastboot##' $RC
perl -p -i -e 's#^(exit 0)$#cat /etc/welcome\n$&#g' $RC

# Prepare welcome screen
cat >/etc/welcome <<EOF

Welcome at BSDanywhere $RELEASE, the OpenBSD Live system at your fingertips!

Two ways to log on to the system are provided: 'live' and 'root'

Log in as 'live' with empty password for the graphical environment. Access
to administrative commands are granted using the 'sudo' command. Experts may
also log in as 'root' without password, which will neither start a graphical
environment nor any custom BSDanywhere scripts.

EOF

# Trim motd
head -2 /etc/motd > /tmp/motd
mv /tmp/motd /etc/motd

# Extend rc.local
cat >/etc/rc.local <<EOF 
# Site-specific startup actions, daemons, and other things which
# can be done AFTER your system goes into securemode.  For actions
# which should be done BEFORE your system has gone into securemode
# please see /etc/rc.securelevel.

echo -n 'starting local daemons:'

if [ -x /usr/local/bin/tor ]; then
     echo -n ' tor';
     /usr/local/bin/tor >/dev/null 2>&1
fi

if [ -x /usr/local/sbin/privoxy ]; then
     echo -n ' privoxy';
     /usr/local/sbin/privoxy --user _privoxy._privoxy \
	/etc/privoxy/config >/dev/null 2>&1
fi

echo '.'

sub_mfsmount() {
    if [ \$(sysctl -n hw.physmem) -gt 268000000 ]
    then
        echo "Free memory available, using it for /bin and /sbin."
        mount_mfs -s 24000 swap /.mbin
        mount_mfs -s 48000 swap /.msbin
        /bin/cp -rp /bin /.mbin
        /bin/cp -rp /sbin /.msbin
        perl -p -i -e 's#^(PATH=)(.*)#\$1/.msbin/sbin:/.mbin/bin:\$2#' /root/.profile
        perl -p -i -e 's#^(PATH=)(.*)#\$1/.msbin/sbin:/.mbin/bin:\$2#' /home/live/.profile
    fi
    if [ \$(sysctl -n hw.physmem) -gt 800000000 ]
    then
        echo "Lots of memory available, do you want to use it for /usr/local? (Y/n) "
        read doit
        if [ -z \$doit ] || [ \$doit = "y" ] || [ \$doit = "Y" ] || [ \$doit = "yes" ] || [ \$doit = "Yes" ]
        then
            # /usr/local uses ~390M
            mount_mfs -s 900000 swap /.musrlocal
            /bin/cp -rp /usr/local /.musrlocal
            perl -p -i -e 's#^(PATH=)(.*)#\$1/.musrlocal:\$2#' /root/.profile
            perl -p -i -e 's#^(PATH=)(.*)#\$1/.musrlocal:\$2#' /home/live/.profile
        fi
    fi
}

sub_timezone() {
   while :
   do
      echo -n "What timezone are you in? ('?' for list) "
      read zone
	 if [ "\${zone}" ]
	 then
	 if [ "\${zone}" = "?" ]
	 then
	    ls -F /usr/share/zoneinfo
	 fi
	 if [ -d "/usr/share/zoneinfo/\${zone}" ]
	 then
	    ls -F "/usr/share/zoneinfo/\${zone}"
	    echo -n "What sub-timezone of \${zone} are you in? "
	    read subzone
	    zone="\${zone}/\${subzone}"
	 fi
	 if [ -f "/usr/share/zoneinfo/\${zone}" ]
	 then
	    echo "Setting local timezone to \${zone} ..."
	    rm /etc/localtime
	    ln -sf "/usr/share/zoneinfo/\${zone}" /etc/localtime
	    echo "done"
	    return
	 fi
      else
	 echo "Leaving timezone unconfigured"
	 return
      fi
   done
}

sub_kblayout() {
    echo "Select keyboard layout *by number*:"
    select kbd in us de sg es it fr be jp nl ru uk sv no pt br hu tr dk
    do
       if [ -n \$kbd ]; then

          # set console mapping
          /sbin/kbd \$kbd

          # write X11 mapping into site wide config
	  if [ \$kbd = 'sg' ]; then
             xkbd=ch
	  elif [ \$kbd = 'sv' ]; then
             xkbd=se
          else
             xkbd=\$kbd
          fi

          echo "/usr/X11R6/bin/setxkbmap \$xkbd &" > /etc/X11/.xinitrc
          break

       else
          print "Invalid number, leaving 'us' keyboard layout."
       fi
    done
}

sub_networks() {
   echo -n "Do you want to auto configure the network? (Y/n) "
   read net
   if [ -z \$net ] || [ \$net = "y" ] || [ \$net = "Y" ] || [ \$net = "yes" ] || [ \$net = "Yes" ]
   then
      for nic in \$(ifconfig | awk -F: '/^[a-z]+[0-9]: flags=/ { print \$1 }' | egrep -v "lo|enc|pflog")
      do
          echo -n "Do you want to configure \$nic for dhcp? (Y/n) "
          read if
          if [ -z \$if ] || [ \$if = "y" ] || [ \$if = "Y" ] || [ \$if = "yes" ] || [ \$if = "Yes" ]
          then
              sudo ifconfig \$nic up && sudo dhclient \$nic &
          fi
      done

      echo -n "Do you want to synchronize the time using ntpd? (Y/n) "
      read ntp
      if [ -z \$ntp ] || [ \$ntp = "y" ] || [ \$ntp = "Y" ] || [ \$ntp = "yes" ] || [ \$ntp = "Yes" ]
      then
          sudo ntpd -s &
      fi
   fi
}

sub_mfsmount
sub_kblayout
sub_timezone
sub_networks
EOF

# Write privoxy config
cat >/etc/privoxy/config <<EOF
forward-socks4a / 127.0.0.1:9050 .
confdir /etc/privoxy
logdir /var/log/privoxy
actionsfile standard  # Internal purpose, recommended
actionsfile default   # Main actions file
actionsfile user      # User customizations
filterfile default.filter
jarfile jarfile
listen-address  127.0.0.1:8118
toggle  1
enable-remote-toggle  1
enable-edit-actions 1
buffer-limit 4096
EOF

# Download torbutton extension and place it in live's home account for manual installation.
# Users can drag this file into firefox to install it. Automatic install seems to be broken.
ftp -o /home/live/torbutton.xpi http://torbutton.torproject.org/dev/releases/torbutton-1.2.0rc1.xpi

# Customize 'live' account
cat >/home/live/.xinitrc <<EOF
#!/bin/sh
. /etc/X11/.xinitrc
exec enlightenment_start
EOF

# Start X11 for 'live' by default
echo "startx" >> /home/live/.profile


# Create E17 menus
E17_BASE=/home/live/.e/e
E17_MENU=$E17_BASE/applications/menu
E17_BAR=$E17_BASE/applications/bar/default
E17_BG=$E17_BASE/backgrounds
mkdir -p $E17_MENU
mkdir -p $E17_BAR
mkdir -p $E17_BG

# Populate e17 menu entries
cat >$E17_MENU/favorite.menu <<EOF
<?xml version="1.0"?>
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://standards.freedesktop.org/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Favorites</Name>
  <DefaultAppDirs/>
  <Include>
    <Filename>xterm.desktop</Filename>
    <Filename>firefox.desktop</Filename>
    <Filename>audacious.desktop</Filename>
    <Filename>gqview.desktop</Filename>
    <Filename>gimp.desktop</Filename>
    <Filename>abiword.desktop</Filename>
    <Filename>thunderbird.desktop</Filename>
  </Include>
</Menu>
EOF

# Populate e17 bar entries (the bottom panel)
cat >$E17_BAR/.order <<EOF
xterm.desktop
firefox.desktop
thunderbird.desktop
gimp.desktop
abiword.desktop
EOF

# Create missing xterm.desktop file
cat >/usr/local/share/applications/xterm.desktop <<EOF
[Desktop Entry]
Comment=Terminal for X11
Name=XTerm
Type=Application
Exec=xterm
Icon=xterm.png
Terminal=false
EOF

# Ensure ownership of all previously created inodes
chown -R live /home/live

# Leave the chroot environment
exit

# Cleanup build environment
rm $LOCAL_ROOT/etc/resolv.conf

# Preload mfs mounts
for i in etc root home var; do cp -rp $LOCAL_ROOT/$i $LOCAL_ROOT/.m$i; done

# To reedit the cd image, 'rm -rf var && cp -rp .mvar var'
rm -r $LOCAL_ROOT/var/* && ln -s /var/tmp $LOCAL_ROOT/tmp

# Create CD image
cd $LOCAL_ROOT/..
mkhybrid -A "BSDanywhere $RELEASE" -quiet -l -R -o bsdanywhere$R.iso -b cdbr -c boot.catalog livecd
