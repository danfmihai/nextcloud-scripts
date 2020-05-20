#!/bin/bash
###### PLEASE MAKE THE NECESSARY CHANGENS FOR YOUR SETUP ####
# Replace all working directories with yours 
## MAKE SURE YOU ARE RUNNING THE SCRIPT AS SUDO
# Working folders #
nextcloud_folder_name=nextcloud              # Nextcloud installation folder name
# db_name='nextcloud'                           # Database name
# db_user='root'
# db_pass=''
dir=/var/www                                 #nginx or apache root folder 
nextcloud_dir=$dir/$nextcloud_folder_name    #nextcloud installation folder variable
backup_dir=~/nextcloud_backup                #backup base dir
backup_remote=root@proxmox.lan               #backup remote host whre to transfer the backup files
backup_port=30004                            #backup remote host port
backup_location=/mnt/backup/vps/nextcloud/   #backup remote destination for the backup files
backup_log=~/backup_$(date '+%m-%d-%Y-%H:%M').log

clear

get_info () {
    version=$(cat $nextcloud_dir/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbname=$(cat $nextcloud_dir/config/config.php | grep dbname | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbuser=$(cat $nextcloud_dir/config/config.php | grep dbuser | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbpass=$(cat $nextcloud_dir/config/config.php | grep dbpassord | awk '{print $3}' | sed "s/['\,,\"]//g")
}

##### BACKUP OF NEXTCLOUD INSTALLATION #####
echo "###### BACKUP OF NEXTCLOUD INSTALLATION ####"
echo
## test if folder nextcloud exists ###

      if [ -d  $nextcloud_dir ]
      then
            # get the version of nextcloud install
            get_info
            echo "*******************************"
            echo "Database user found: ${_dbuser}"
            echo "Database name found: ${_dbname}"
            echo "*******************************"            
            #version=$(cat $nextcloud_dir/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g")
            db_file=nextcloud_$( date '+%m-%d-%Y' )_$version.sql
            tar_file=nextcloud_$( date '+%m-%d-%Y' )_$version.tar.gz
            echo "Any existing backup files ${db_file} and ${tar_file} will be overwritten!"
            echo "Backing up NextCloud version ${version} database...Please wait..."
            # test if database folder exists
            if [ ! -d $backup_dir/database ]
            then
                  echo "database folder doesn't exists on your filesystem."
                  mkdir -p $backup_dir/database
                  if [ -d $backup_dir/database ] 
                  then  echo "folder ${backup_dir} created.."
                     cd $backup_dir/database
                  else echo "folder database not created - ERROR!"
                  fi
            fi      
            cd $backup_dir
            echo "Saving the database nextcloud to ${backup_dir}/database/${db_file}"
            umask 177
            mysqldump -u $_dbuser -p$db_pass $db_name > $backup_dir/database/$db_file
            echo "done."
            echo
            echo "CREATING BACKUP OF ${nextcloud_dir} FOLDER - as tar file..."
            echo "Please wait..."
            cd $dir 
            # Creating archive tar for folder nextcloud/
            tar cpzf $backup_dir/$tar_file nextcloud/
            echo "Tar archive done. ${tar_file}"
            echo
            echo "Transfering the backup file and the database... "
            echo "Please wait..."
            # transfer the database and folder backup to the remote destination
            rsync -az -e "ssh -p $backup_port" $backup_dir $backup_remote:$backup_location
            echo "DATE:" $(date) >> $backup_log 2>&1
            echo "-----------------------------------------------------------------------------------------------------" >> $backup_log 2>&1
            echo ">> Rsync ran today backing up : ${db_file} and ${tar_file} at " $(date)>> $backup_log 2>&1
            echo "-----------------------------------------------------------------------------------------------------" >> $backup_log 2>&1
            echo 
            echo "Transfer done."
            echo
            # removing or not the folders and files created
            echo "Cleaning up! Removing the tar archive and database sql file..."
            cd $backup_dir
            echo
            read -r -p "Do you wish to remove the backup file and database created? [Y/N] " input
            
            case $input in
               [yY][eE][sS]|[yY])
               echo "Deleting files...";
               echo ">> Removed files: " >> $backup_log 2>&1; 
               echo "-----------------------------------------------------------------------------------------------------" >> $backup_log 2>&1
               cd ~
               rm -rfv $backup_dir >> $backup_log 2>&1;
               echo "-----------------------------------------------------------------------------------------------------" >> $backup_log 2>&1
            ;;
               [nN][oO]|[nN])
            echo "Backup files NOT deleted!"
                  ;;
               *)
            echo "Invalid input... Files NOT deleted"
            exit 1
            ;;
            esac
            echo "Transfering logs..." 
            rsync -az -e "ssh -p $backup_port" $backup_log $backup_remote:$backup_location
            echo "done."
            echo 
            echo "Backup and transfer COMPLETE!"
            echo
            echo "##### SUMMARY OF LOG #####"
            echo
            cat $backup_log
            echo
      else
         echo
         echo "Nextcloud installation not found in ${nextcloud_dir}. Nothing to backup!"
         echo
      fi
exit
