
lang en_US.UTF-8
text
keyboard us
timezone Asia/Shanghai
auth --useshadow --passalgo=sha512
selinux --enforcing
firewall --enabled --service=mdns,ssh
part / --size 10240 --fstype ext4
services --enabled=NetworkManager,network,sshd 


# Root password
#set root password "piak" crypted in sha512
rootpw --iscrypted $6$2py2ESAK$/KECiX4egJ1ihCsuiaeGi27FtHqavum5A/PfGFqD.7Lu6ZfUBk24LtKmn9jfpjjej0QswR.N5Qa0tAU9U.tgz/

# Workaround for the grubby issue on live media (see https://bugzilla.redhat.com/show_bug.cgi?id=1153410)
# SL repositories (fastbugs enabled per default) 
#repo --name=base      --baseurl=http://ftp.scientificlinux.org/linux/scientific/7.5/$basearch/os/               --excludepkgs=grubby
#repo --name=security  --baseurl=http://ftp.scientificlinux.org/linux/scientific/7.5/$basearch/updates/security/ --excludepkgs=grubby
#repo --name=fastbugs  --baseurl=http://ftp.scientificlinux.org/linux/scientific/7.5/$basearch/updates/fastbugs/ --excludepkgs=grubby
#repo --name=grubby    --baseurl=http://ftp.scientificlinux.org/linux/scientific/7.0/$basearch/os/                    --includepkgs=grubby

# or use a mirror close to you
#repo --name=base      --baseurl=http://mirror.switch.ch/ftp/mirror/scientificlinux/7.5/$basearch/os/               --excludepkgs=grubby
#repo --name=security  --baseurl=http://mirror.switch.ch/ftp/mirror/scientificlinux/7.5/$basearch/updates/security/ --excludepkgs=grubby
#repo --name=fastbugs  --baseurl=http://mirror.switch.ch/ftp/mirror/scientificlinux/7.5/$basearch/updates/fastbugs/ --excludepkgs=grubby
#repo --name=grubby    --baseurl=http://ftp.scientificlinux.org/linux/scientific/7.0/$basearch/os/                       --includepkgs=grubby
#repo --name=base      --baseurl=http://mirrors.gbcom.com.cn/Seienific-7.5-Everything-x86_64/               --excludepkgs=grubby
#repo --name=security  --baseurl=http://mirrors.gbcom.com.cn/Seienific-7.5-Everything-x86_64/               --excludepkgs=grubby
#repo --name=fastbugs  --baseurl=http://mirrors.gbcom.com.cn/Seienific-7.5-Everything-x86_64/               --excludepkgs=grubby
#repo --name=grubby    --baseurl=http://mirrors.gbcom.com.cn/Seienific-7.5-Everything-x86_64/               --includepkgs=grubby
repo --name=base      --baseurl=http://mirrors.gbcom.com.cn/centos/7.5.1804/
#--excludepkgs=grubby
#repo --name=security  --baseurl=http://mirrors.gbcom.com.cn/centos/7.5.1804/               --excludepkgs=grubby
#repo --name=fastbugs  --baseurl=http://mirrors.gbcom.com.cn/centos/7.5.1804/               --excludepkgs=grubby
#repo --name=grubby    --baseurl=http://mirrors.gbcom.com.cn/centos/7.5.1804/               --includepkgs=grubby


%packages
@base
@core
@debugging
@development
@console-internet
@hardware-monitoring
@legacy-unix
@load-balancer
@network-tools
@networkmanager-submodules
@perl-runtime
@php
@postgresql
@python-web
@ruby-runtime
%end

%post
echo "nameserver 10.1.1.249" >> /etc/resolv.conf
echo "nameserver 10.1.1.252" >> /etc/resolv.conf
cd /etc/yum.repos.d/
mkdir bak && mv *.repo bak/
# Set yum repo
cat > /etc/yum.repos.d/CentOS-Gbcom.repo << EOF
# CentOS-Gbcom.repo
[gbcom]
name=CentOS-1804-repo
baseurl=http://mirrors.gbcom.com.cn/centos/7.5.1804/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.gbcom.com.cn/centos/7.5.1804/RPM-GPG-KEY-CentOS-7
EOF

# install ruby
# method 1
#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#curl -sSL https://get.rvm.io | bash -s stable --ruby

# method 2

# FIXME: it'd be better to get this installed from a package
cat > /etc/rc.d/init.d/livesys << EOF
#!/bin/bash
#
# live: Init script for live image
#
# chkconfig: 345 00 99
# description: Init script for live image.
### BEGIN INIT INFO
# X-Start-Before: display-manager
### END INIT INFO

. /etc/init.d/functions

if [ -e /.liveimg-configured ] ; then
    configdone=1
fi

# Make sure we don't mangle the hardware clock on shutdown
ln -sf /dev/null /etc/systemd/system/hwclock-save.service

livedir="LiveOS"

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
mount -t tmpfs -o mode=0755 varcacheyum /var/cache/yum
mount -t tmpfs vartmp /var/tmp
[ -x /sbin/restorecon ] && /sbin/restorecon /var/cache/yum /var/tmp >/dev/null 2>&1

if [ -n "\$configdone" ]; then
	echo "configdone"
fi

# add fedora user with no passwd
if [ -e /run/initramfs/isoscan/scripts/users ]
then
	cat /run/initramfs/isoscan/scripts/users | while read username
	do
		action "Adding \$username user" useradd -u 0 -o -g 0 -G root "\$username"
		passwd -d "\$username" > /dev/null
		usermod -aG root "\$username" > /dev/null
		echo -e "\nif [ -e /run/initramfs/isoscan/scripts/starter ]; then\n\t. /run/initramfs/isoscan/scripts/starter\nfi" >> /home/"\$username"/.bashrc
	done
else		
		action "Adding Factory user" useradd -u 0 -o -g 0 -G root factory
		passwd -d factory > /dev/null
		usermod -aG root factory > /dev/null
		echo -e "\nif [ -e /run/initramfs/isoscan/scripts/starter ]; then\n\t. /run/initramfs/isoscan/scripts/starter\nfi" >> /home/factory/.bashrc
		
		action "Adding mksystem user" useradd -u 0 -o -g 0 -G root mksystem
		passwd -d mksystem > /dev/null
		usermod -aG root mksystem > /dev/null
		echo -e "\nif [ -e /run/initramfs/isoscan/scripts/starter ]; then\n\t. /run/initramfs/isoscan/scripts/starter\nfi" >> /home/mksystem/.bashrc

fi
# Remove root password lock
passwd -d root > /dev/null

# turn off firstboot for livecd boots
systemctl --no-reload disable firstboot-text.service 2> /dev/null || :
systemctl --no-reload disable firstboot-graphical.service 2> /dev/null || :
systemctl stop firstboot-text.service 2> /dev/null || :
systemctl stop firstboot-graphical.service 2> /dev/null || :

# don't use prelink on a running live image
sed -i 's/PRELINKING=yes/PRELINKING=no/' /etc/sysconfig/prelink &>/dev/null || :

# turn off mdmonitor by default
systemctl --no-reload disable mdmonitor.service 2> /dev/null || :
systemctl --no-reload disable mdmonitor-takeover.service 2> /dev/null || :
systemctl stop mdmonitor.service 2> /dev/null || :
systemctl stop mdmonitor-takeover.service 2> /dev/null || :

# don't start cron/at as they tend to spawn things which are
# disk intensive that are painful on a live image
systemctl --no-reload disable crond.service 2> /dev/null || :
systemctl --no-reload disable atd.service 2> /dev/null || :
systemctl stop crond.service 2> /dev/null || :
systemctl stop atd.service 2> /dev/null || :

# Fixing default locale to us
localectl set-keymap us
echo "0 0 0 0" > /proc/sys/kernel/printk

# Mark things as configured
touch /.liveimg-configured

# add static hostname to work around xauth bug
# https://bugzilla.redhat.com/show_bug.cgi?id=679486
echo "Factory" > /etc/hostname

EOF

# Remove root password lock
passwd -d root > /dev/null

chmod 755 /etc/rc.d/init.d/livesys
/sbin/restorecon /etc/rc.d/init.d/livesys
/sbin/chkconfig --add livesys

# enable tmpfs for /tmp
systemctl enable tmp.mount

# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
#/usr/bin/mandb

# save a little bit of space at least...
rm -f /boot/initramfs*
# make sure there aren't core files lying around
rm -f /core*

# remove langpacks of firefox - this will significantly save space
rm -f /usr/lib64/firefox/langpacks/*

# convince readahead not to collect
# FIXME: for systemd

# rebuild schema cache with any overrides we installed
# glib-compile-schemas /usr/share/glib-2.0/schemas
%end
