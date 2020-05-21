#!/bin/bash
###### PLEASE MAKE THE NECESSARY CHANGENS FOR YOUR SETUP ####
# Replace all working directories with yours 
## MAKE SURE YOU ARE RUNNING THE SCRIPT AS SUDO
# Working folders #

## REPLACE YOUR NEXTCLOUD FOLDER NAME BELOW WITH YOURS IF NOT THE SAME NAME:
nextcloud_folder_name=nextcloud              # Nextcloud installation folder name
dir=/var/www                                 #nginx or apache root folder 
nextcloud_dir=$dir/$nextcloud_folder_name    #nextcloud installation folder variable
backup_dir=~/nextcloud_backup                #backup base dir
backup_remote=root@proxmox.lan               #backup remote host whre to transfer the backup files
backup_port=30004                            #backup remote host port
backup_location=/mnt/backup/vps/nextcloud/   #backup remote destination for the backup files
backup_log=~/backup_$(date '+%m-%d-%Y-%H:%M').log
user_cred=$backup_dir/user_cred.txt
clear

get_info () {
    version=$(cat $nextcloud_dir/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbname=$(cat $nextcloud_dir/config/config.php | grep dbname | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbuser=$(cat $nextcloud_dir/config/config.php | grep dbuser | awk '{print $3}' | sed "s/['\,,\"]//g")
    _dbpass=$(cat $nextcloud_dir/config/config.php | grep dbpassword | awk '{print $3}' | sed "s/['\,,\"]//g")
    echo "[client]" > $user_cred
    echo "user='${_dbuser}'" >> $user_cred
    echo "password='${_dbpass}'" >> $user_cred
}

##### BACKUP OF NEXTCLOUD INSTALLATION #####
echo "###### BACKUP OF NEXTCLOUD INSTALLATION ####"
echo
## test if folder nextcloud exists ###

      if [ -d  $nextcloud_dir ]
      then
            
            # test if database folder exists
            if [ ! -d $backup_dir/database ]
            then
                  echo "Backup folder doesn't exists on your filesystem."
                  mkdir -p $backup_dir/database
                  if [ -d $backup_dir/database ] 
                  then  echo "Folder ${backup_dir}/database created.."
                     cd $backup_dir/database
                  else echo "Backup folder could not be created - ERROR!"
                  fi
            fi      
            
            # get the version of nextcloud install
            get_info
            echo "*******************************"
            echo "Database user found: ${_dbuser}"
            echo "Database name found: ${_dbname}"
            echo "*******************************"            
            echo
            
            # name of the database file that will be created as backup
            db_file=nextcloud_$( date '+%m-%d-%Y' )_$version.sql
            # tar file of nextcloud folder
            tar_file=nextcloud_$( date '+%m-%d-%Y' )_$version.tar.gz

            echo "Any existing backup files ${db_file} and ${tar_file} will be overwritten!"
            echo
            echo "Backing up NextCloud version ${version} database...Please wait..."
            echo            
            cd $backup_dir
            echo "Saving the database nextcloud to ${backup_dir}/database/${db_file}"
            umask 177
            #mysqldump -u $_dbuser -p$_dbpass $_dbname > $backup_dir/database/$db_file
            mysqldump --defaults-extra-file=$user_cred $_dbname > $backup_dir/database/$db_file
            echo "done."
            echo
            echo "CREATING BACKUP OF ## ${nextcloud_dir} ## FOLDER - as tar file..."
            echo "Please wait..."
            cd $dir 
            # Creating archive tar for folder nextcloud/
            tar cpzf $backup_dir/$tar_file nextcloud/
            echo "Tar ${tar_file} archive done. "
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
