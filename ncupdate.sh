#!/bin/sh
#
## Piet's Host ## - ©2017, https://piets-host.de
#
# Tested on CentOS 7.3

echo -e "\e[32m ______ __         __           _______               __   
|   __ \__|.-----.|  |_.-----. |   |   |.-----.-----.|  |_ 
|    __/  ||  -__||   _|__ --| |       ||  _  |__ --||   _|
|___|  |__||_____||____|_____| |___|___||_____|_____||____|\e[0m"
echo ""

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# Directories - change the following lines to suit your needs:
HTML=/var/www/html		# root html directory
BACKUP=$HTML/backup		# name of the backup folder, which will be created
NCPATH=$HTML/nextcloud1	# name of your subfolder in root html directory, where your nextcloud installation is located
EMAIL=example@domain.com	# will be used for sending emails, if upgrade was successfull
htuser='apache'  		 # Webserver-User
htgroup='apache' 		 # Webserver-Group
NAME=nextcloud_install_1 # Define a name for your Instance, which will be upgraded

# Database Variables - Look in your config.php
DBSERVER=127.0.0.1		# Database host
DATABASE=databasename	# Database name
USER=databaseuser		# Database username
PASS=S€crEtP@s$			# Database password

# Variables - Do NOT Change!
STANDARDPATH=$HTML/nextcloud
FILE=nextcloud.sql.`date +"%Y%m%d"`
RESTORE=nextcloud.sql
HOST=$HOSTNAME
ocpath=$NCPATH
rootuser='root'

NCREPO="https://download.nextcloud.com/server/releases"

# Versions
chmod +x $NCPATH/occ
mkdir -p $HTML/backup
mkdir -p /var/log/ncupdater
CURRENTVERSION=$(sudo -u apache php $NCPATH/occ status | grep "versionstring" | awk '{print $3}')
NCVERSION=$(curl -s -m 900 $NCREPO/ | tac | grep unknown.gif | sed 's/.*"nextcloud-\([^"]*\).zip.sha512".*/\1/;q')

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, type: sudo -i"; exit 1; }

# Upgrade Nextcloud
echo "Checking latest released version on the Nextcloud download server and if it's possible to download..."
wget -q -T 10 -t 2 $NCREPO/nextcloud-$NCVERSION.tar.bz2 > /dev/null
if [ $? -eq 0 ]; then
	echo ""
    echo -e "\e[4;32mSUCCESS!\e[0m"
	rm -f $HTML/nextcloud-$NCVERSION.tar.bz2
else
    echo
    echo -e "\e[91mNextcloud $NCVERSION doesn't exist.\e[0m"
    echo "Please check available versions here: $NCREPO"
    echo
    exit 1
fi

# Downgrade Warning
echo
echo "!! Warning !!"
echo
echo "Downgrading is not supported and risks corrupting your data!"
echo "If you want to revert to an older Nextcloud version,"
echo "make a new, fresh installation and then restore your data from backup."
echo
echo "Checking versions in 5 seconds.."

echo -ne '  |====>               |   (20%)\r'
sleep 1
echo -ne '  |=======>            |   (40%)\r'
sleep 1
echo -ne '  |===========>        |   (60%)\r'
sleep 1
echo -ne '  |===============>    |   (80%)\r'
sleep 1
echo -ne '  |===================>|   (100%)\r'
echo -ne '\n'

# Check if new version is larger than current version installed.
function version_gt() { local v1 v2 IFS=.; read -ra v1 <<< "$1"; read -ra v2 <<< "$2"; printf -v v1 %03d "${v1[@]}"; printf -v v2 %03d "${v2[@]}"; [[ $v1 > $v2 ]]; }
if version_gt "$NCVERSION" "$CURRENTVERSION"
then
	echo ""
    echo -e "Latest version is: \e[4;32m$NCVERSION\e[0m. Current version is: \e[4;31m$CURRENTVERSION\e[0m."
	echo ""
    echo -e "\e[32mNew version available! Upgrade continues...\e[0m"
	sleep 2
else
	echo ""
    echo -e "Latest version is: \e[4;32m$NCVERSION\e[0m. Current version is: \e[4;32m$CURRENTVERSION\e[0m."
	echo ""
    echo "No need to upgrade, this script will exit..."
	echo "Your Nextcloud Version $NCVERSION is already up to date - No need for an upgrade - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
	sleep 2
    exit 0
fi

echo "Backing up files and upgrading to Nextcloud $NCVERSION in 10 seconds..." 
echo "Press CTRL+C to abort."

echo -ne '  |=>                  |   (10%)\r'
sleep 1
echo -ne '  |===>                |   (20%)\r'
sleep 1
echo -ne '  |=====>              |   (30%)\r'
sleep 1
echo -ne '  |=======>            |   (40%)\r'
sleep 1
echo -ne '  |=========>          |   (50%)\r'
sleep 1
echo -ne '  |===========>        |   (60%)\r'
sleep 1
echo -ne '  |=============>      |   (70%)\r'
sleep 1
echo -ne '  |===============>    |   (80%)\r'
sleep 1
echo -ne '  |=================>  |   (90%)\r'
sleep 1
echo -ne '  |===================>|   (100%)\r'
echo -ne '\n'

# Backup data
echo ""
echo -e "\e[33mBacking up data... That may take some time - depending on your Installation!\e[0m"

rsync -Aax $NCPATH/config $BACKUP 
rsync -Aax $NCPATH/themes $BACKUP
rsync -Aax $NCPATH/apps $BACKUP

rsync_param_data="-Aaxv"
rsync "$rsync_param_data" $NCPATH/data $BACKUP  |\
     pv -lep -s $(rsync "$rsync_param_data"n $NCPATH/data $BACKUP  | awk 'NF' | wc -l)
	 
	unalias rm     2> /dev/null
	rm ${FILE}     2> /dev/null
	rm ${FILE}.gz  2> /dev/null
	sleep 1
	
	# Database Backup
	echo ""
	echo -e "\e[33mStarting Database Backup...\e[0m"
	echo ""
	sleep 1
	# use this command for a database server on a separate host:
	#mysqldump --opt --protocol=TCP --user=${USER} --password=${PASS} --host=${DBSERVER} ${DATABASE} > ${FILE}

	# use this command for a database server on localhost. add other options if need be.
	mysqldump --opt --user=${USER} --password=${PASS} ${DATABASE} > ${FILE}
	
	gzip $FILE
	echo -e "\e[32m${FILE}.gz was created\e[0m"
	sleep 1
	echo ""

if [[ $? > 0 ]]
then
    echo -e "\e[31mBackup was not OK.\e[0m Please check $BACKUP and see if the folders are backed up properly"
	echo "NEXTCLOUD UPDATE FAILED - Backup wasn't successfull - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
    exit 1
else
    echo -e "\e[4;32m"
    echo "Backup OK!"
    echo -e "\e[0m"
fi

echo "Downloading $NCREPO/nextcloud-$NCVERSION.tar.bz2..."
echo ""
wget -q -T 10 -t 2 $NCREPO/nextcloud-$NCVERSION.tar.bz2 -P $HTML

if [ -f $HTML/nextcloud-$NCVERSION.tar.bz2 ]
then
    echo -e "$HTML/nextcloud-$NCVERSION.tar.bz2 \e[32mexists\e[0m"
else
    echo "Aborting,something went wrong with the download"
	echo "NEXTCLOUD UPDATE FAILED - Download couldn't be completed - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
    exit 1
fi

if [ -d $BACKUP/config/ ]
then
    echo -e "$BACKUP/config/ \e[32mexists\e[0m"
else
    echo "Something went wrong with backing up your old nextcloud instance, please check in $BACKUP if config/ folder exist."
	echo "NEXTCLOUD UPDATE FAILED - /config couldn't be backed up - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
    exit 1
fi

if [ -d $BACKUP/data/ ]
then
    echo -e "$BACKUP/data/ \e[32mexists\e[0m"
else
    echo "Something went wrong with backing up your old nextcloud instance, please check in $BACKUP if data/ folder exist."
	echo "NEXTCLOUD UPDATE FAILED - /data couldn't be backed up - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
    exit 1
fi

if [ -d $BACKUP/apps/ ]
then
    echo -e "$BACKUP/apps/ \e[32mexists\e[0m"
else
    echo "Something went wrong with backing up your old nextcloud instance, please check in $BACKUP if apps/ folder exist."
	echo "NEXTCLOUD UPDATE FAILED - /apps couldn't be backed up - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
    exit 1
fi

if [ -d $BACKUP/themes/ ]
then
    echo -e "$BACKUP/themes/ \e[32mexists\e[0m"
    echo 
	chown -R apache:apache $BACKUP
    echo -e "\e[32mAll files are backed up.\e[0m"
    sudo -u apache php $NCPATH/occ maintenance:mode --on
	echo ""
    echo "Removing old Nextcloud instance in 5 seconds..."
	
	
echo -ne '  |====>               |   (20%)\r'
sleep 1
echo -ne '  |=======>            |   (40%)\r'
sleep 1
echo -ne '  |===========>        |   (60%)\r'
sleep 1
echo -ne '  |===============>    |   (80%)\r'
sleep 1
echo -ne '  |===================>|   (100%)\r'
echo -ne '\n'
	
    rm -rf $NCPATH
	echo ""
	echo -e "\e[32mAll files removed!\e[0m"
	echo ""
	sleep 1
	echo -e "\e[33mFiles are being extracted... \e[0m"
	
	pv -w 80 $HTML/nextcloud-$NCVERSION.tar.bz2 | tar xjf - -C $HTML
	mv $STANDARDPATH $NCPATH

	rm $HTML/nextcloud-$NCVERSION.tar.bz2
	sleep 1
	
	echo ""
	echo -e "\e[32mExtract completed.\e[0m"
	echo ""
	sleep 1
	echo -e "\e[33mCopying files back to installation.... That may take a long time - depending on your installation!\e[0m"
	echo ""
    cp -R $BACKUP/themes $NCPATH/
	cp -R $BACKUP/config $NCPATH/
	cp -R $BACKUP/data $NCPATH/
	
	echo -e "\e[32mCopying completed.\e[0m"
	echo ""
	sleep 2

	echo -e "\e[33mSetting file permissions...\e[0m"
	echo ""
	
	# Fix permissions
	chown -R ${rootuser}:${htgroup} ${ocpath}/
	chown -R ${htuser}:${htgroup} ${ocpath}/apps/
	chown -R ${htuser}:${htgroup} ${ocpath}/config/
	chown -R ${htuser}:${htgroup} ${ocpath}/data/
	chown -R ${htuser}:${htgroup} ${ocpath}/themes/
	chown -R ${htuser}:${htgroup} ${ocpath}/updater/
	
	chmod +x ${ocpath}/occ
	sleep 2
	echo -e "\e[32mFile permissions set successfully!\e[0m"
	echo ""
	
	# occ upgrade
	echo -e "\e[32mStarting Upgrade Process....\e[0m"
	sleep 2
	echo ""
    sudo -u apache php $NCPATH/occ maintenance:mode --off
	echo ""
    sudo -u apache php $NCPATH/occ upgrade
else
    echo "Something went wrong with backing up your old nextcloud instance, please check in $BACKUP if the folders exist."
	echo "NEXTCLOUD UPDATE FAILED - /themes couldn't be backed up - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
	echo ""
	echo -e "\e[33mRestoring Database...\e[0m"
	gunzip ${FILE}.gz
	echo "${FILE}"
	mv ${FILE} ${RESTORE}
	mysql --user=${USER} --password=${PASS} ${DATABASE} < ${FILE}
	echo ""
	echo -e "\e[32mDatabase restored successfully...\e[0m"
	echo ""
	echo "NEXTCLOUD UPDATE FAILED - Database restored successfully - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
	sleep 1
    exit 1
fi

# Change owner of $BACKUP folder to root
chown -R root:root $BACKUP
chown -R apache:apache $NCPATH

CURRENTVERSION_after=$(sudo -u apache php $NCPATH/occ status | grep "versionstring" | awk '{print $3}')
if [[ "$NCVERSION" == "$CURRENTVERSION_after" ]]
then
    echo
    echo "Latest version is: $NCVERSION. Current version is: $CURRENTVERSION_after."
	echo ""
	echo -e "\e[4;32mUPGRADE SUCCESS!\e[0m"
    echo ""
    echo "NEXTCLOUD UPDATE success - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
	
	# Send E-Mail if successfully updated
	echo "Hey there!

Your Nextcloud-Update completed successfully!
	
Host: $HOST 
Name: $NAME
directory: $NCPATH
	
`date +"%d.%m.%Y-%H:%M:%S"`

Thank you for using Piet's Host Nextcloud-Updater!" | mail -s "NEXTCLOUD UPDATE SUCCESS - `date +"%d.%m.%Y"`" $EMAIL
    sudo -u apache php $NCPATH/occ status
	echo ""
    sudo -u apache php $NCPATH/occ maintenance:mode --off
    echo
    echo "Thank you for using Piet's Host Nextcloud-Updater!"
	echo ""
    ## Uncomment, if you want to reboot your server after upgrade
    # reboot
    exit 0
else
    echo
	echo echo -e "\e[40;38;4;82mLatest: $NCVERSION \e[30;48;4;82mCurrent: $CURRENTVERSION_after \e[0m"
    sudo -u apache php $NCPATH/occ status
    echo -e "\e[31mUPGRADE FAILED!\e[0m"
    echo "Your files are still backed up at $BACKUP. No worries!"
    echo "Please report this issue to support@piets-host.de"
	echo ""
	echo "NEXTCLOUD UPDATE FAILED - `date +"%Y_%m_%d"`" >> /var/log/ncupdater/ncupdater_$NAME.log
    exit 1
fi
