#!/bin/bash
#RUN AS SUDO - uses rsnapshot to backup nginx and letsencrypt folders

# variabiles

uu='apt update' && 'apt upgrade -y'
bkdir=/root/rsnapshot
TAB="$(printf '\t')"

clear

echo "Updatting system..."
echo
#$uu
echo "Installing rsnapshot..."
echo

locale-gen en_US.UTF-8
apt install -y rsnapshot

[ ! -d $bkdir ] && mkdir -p $bkdir

mv /etc/rsnapshot.conf /etc/rsnapshot.conf.bak

cat <<EOF >/etc/rsnapshot.conf
#######################
# CONFIG FILE VERSION #
#######################

config_version${TAB}1.2

###########################
# SNAPSHOT ROOT DIRECTORY #
###########################

# All snapshots will be stored under this root directory.
#
snapshot_root${TAB}${bkdir}/

#################################
# EXTERNAL PROGRAM DEPENDENCIES #
#################################
cmd_cp${TAB}/bin/cp

cmd_rm${TAB}/bin/rm

cmd_rsync${TAB}/usr/bin/rsync

cmd_ssh${TAB}/usr/bin/ssh

cmd_logger${TAB}/usr/bin/logger

retain${TAB}alpha${TAB}2
retain${TAB}beta${TAB}2
#retain  gamma   2

verbose${TAB}2
loglevel${TAB}3
lockfile${TAB}/var/run/rsnapshot.pid
### BACKUP POINTS / SCRIPTS ###
# LOCALHOST

backup${TAB}/etc/nginx/${TAB}.
backup${TAB}/etc/letsencrypt/${TAB}.
EOF

rsnapshot alpha

cd $bkdir
