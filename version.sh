#!/bin/bash
clear
echo "Old way to get version for Nextcloud install"
ver=$(cat /var/www/nextcloud/config/config.php | grep version | tr -d [\',\,,\=,\>])
version=${ver#??????????*}
echo ${version}
echo "New way to get version :"
new_ver=$(cat /var/www/nextcloud/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g")
echo "${new_ver}"

