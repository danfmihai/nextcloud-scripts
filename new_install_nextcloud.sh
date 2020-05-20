#!/bin/bash
###### Installing Nextcloud ############
clear

# Working directories

dir=/var/www
nextcloud_dir=/var/www/nextcloud
_bdir=$(mktemp -d $dir/nextcloud-XXXX)
_tdir=$(mktemp -d ~/nextcloud-XXXX)

clean_up () {
    echo "Cleaning up"
   # rm -rf $_tdir
}

# register the cleanup function to be called on the EXIT signal
trap clean_up EXIT

get_info () {
    version=$(cat $nextcloud_dir/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbname=$(cat $nextcloud_dir/config/config.php | grep dbname | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbuser=$(cat $nextcloud_dir/config/config.php | grep dbuser | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbpass=$(cat $nextcloud_dir/config/config.php | grep dbpassord | awk '{print $3}' | sed "s/['\,,\"]//g")
}

 stop_service () {
    systemctl stop nginx
}

 start_service () {
    systemctl start nginx
}

 remove_old_db () {
    mysql -u $_dbuser -p$_dbpass -e "SHOW DATABASES;"
    mysqldump -u $_dbuser -p$_dbpass $_dbname > $_tdir/$db_file
    mysql -u _$dbuser -p$_dbpass drop $_dbname
}

 rename_original_folder () {
     mv -v $nextcloud_dir $_bdir
}

 create_new_db () {
     mysql -u $_dbuser -p$_dbpass -e "CREATE DATABASE nextcloud;"
}

if [ -d  $nextcloud_dir ]
then
        get_info
        echo "Installation of Nextcloud version ${version} exists. "
        echo "Database name found:      ${_dbname} "
        echo "Database username found:  ${_dbuser}"
        echo
        db_file=${_dbname}_$( date '+%m-%d-%Y-%H:%M' )_$version.sql
        
        echo "Original nexctcloud folder will be renamed in ${_bdir} and database in ${db_file} "
        read -r -p "Nextcloud folder will be renamed and existing database will be saved in ${_tdir}. Proceed? [y/N] " input
        
        case $input in
            [yY][eE][sS]|[yY])
            echo "Removing database...";
            stop_service
            remove_old_db
            rename_original_folder
            echo "Database ${_dbname} deleted and nextcloud folder renamed ${_bdir} "
            mysql -u $_dbuser -p$_dbpass -e "SHOW DATABASES;"
            echo
            echo "Ready for new installation! Please wait..."
            echo "Hit ENTER to continue with the new installtion or press CTRL+C to abort"
            echo "New database will be created named nextcloud"
            read dummy
            echo "$(pwd)"
            cd $dir
            wget https://download.nextcloud.com/server/releases/nextcloud-18.0.4.tar.bz2
            tar xvfj nextclo*
            if [ -d nextcloud/ ]; then
                chown -R www-data:www-data nextcloud 
                find nextcloud/ -type d -exec chmod 750 {} \;
                find nextcloud/ -type f -exec chmod 640 {} \;
                else
                    echo "Nextcloud archive broken or not processed. Exiting..."
                    exit 1
            fi
            exit
        ;;
            [nN][oO]|[nN])
        echo "Database NOT deleted!";
            ;;
            *)
        echo "Invalid input...skipping"
        exit 1
        esac
else
    echo "No Previous install of Nextcloud was detected in ${nextcloud_dir}"        
fi
start_service