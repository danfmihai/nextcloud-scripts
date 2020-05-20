#!/bin/bash
clear
echo "#######################################"
echo "Scanning data files for nextcloud users"
echo "#######################################"
echo
echo "Finding files not in www-data group..."
find /mnt/owncloud-data/misu/files ! -group www-data -print -exec chown www-data:www-data {} \;
echo "Owner and group check done. "
echo "Next scanning all files now..."
echo
sudo -u www-data php /var/www/nextcloud/occ files:scan misu
exit