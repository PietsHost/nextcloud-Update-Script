#!/bin/sh
#
## Piet's Host ## - ©2017, https://piets-host.de
#
# Tested on CentOS 6.8 & 7.3
# Tested on openSUSE Leap 42.1
#
# Some parts of this script are based on the update script of the official Nextcloud VM by Tech and Me:
# https://www.techandme.se/nextcloud-vm
# https://github.com/nextcloud/vm/blob/master/nextcloud_update.

header=' _____ _      _         _    _           _
|  __ (_)    | |       | |  | |         | |
| |__) |  ___| |_ ___  | |__| | ___  ___| |_
|  ___/ |/ _ \ __/ __| |  __  |/ _ \/ __| __|	+-+-+-+-+
| |   | |  __/ |_\__ \ | |  | | (_) \__ \ |_ 	| v 1.3 |
|_|   |_|\___|\__|___/ |_|  |_|\___/|___/\__|	+-+-+-+-+'

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin

# Directories - change the following lines to suit your needs:
html=/var/www/html		# root html directory
ncpath=$html/nextcloud1	# name of your subfolder in root html directory, where your nextcloud installation is located
backup=$html/backup_`date +"%Y%m%d"`		# name of the backup folder, which will be created
now=`date +"%Y-%m-%d"`
date_diff="7"
old=$(date --date="${now} -${date_diff} day" +%Y-%m-%d)
oldbackup=/home/backup/backupsewikom_$old
backupenabled="false"
email="example@domain.com"	# will be used for sending emails, if upgrade was successfull
htuser='apache'  		 # Webserver-User (CentOS: apache, suseLinux: wwwrun, etc..)
htgroup='apache' 		 # Webserver-Group (CentOS: apache, suseLinux: www, etc...)
name=nextcloud_install_1 # Define a name for your Instance, which will be upgraded

# Database Variables
dbserver=127.0.0.1		# Database host
database="databasename"	# Database name
user="databaseuser"		# Database username
pass="S€crEtP@s$"			# Database password

# Variables - Do NOT Change!
standardpath=$html/nextcloud
file=nextcloud.sql.`date +"%Y%m%d"`
restore=nextcloud.sql
host=$hostname
ocpath=$ncpath
rootuser='root'

ncrepo="https://download.nextcloud.com/server/releases"

red='\e[31m'
green='\e[32m'
yellow='\e[33m'
reset='\e[0m'
redbg='\e[41m'
lightred='\e[91m'
blue='\e[34m'
cyan='\e[36m'
ugreen='\e[4;32m'

show_help() {
cat << EOF

 Usage: ${0##*/} [-b BACKUP] ...
	-h --help	display this help and exit
	-b --backup	enable File-Backup to another folder
	
EOF
}

while :; do
    case $1 in
        -h|-\?|--help)   # Call a "show_help" function , then exit.
        	show_help
			stty echo
            exit
            ;;
		-b|--backup)
				backupenabled="true"
				shift
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf $redbg'Invalid option: %s' "$1" >&2
			printf $reset"\n"
			stty echo
			exit 0
            ;;
        *)               # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

### For NC <12 only
yum -y install diffutils

printf $green"$header"$reset
echo ""

# Versions
chmod +x $ncpath/occ
rm -rf $backup
if [[ "$backupenabled" == "true" ]]; then
	rm -rf $oldbackup
	mkdir -p $backup
	echo ""
	echo ""
	printf $green"File-Backup is enabled!\n"$reset
	echo ""
	sleep 1
fi

mkdir -p /var/log/ncupdater
currentversion=$(sudo -u $htuser php $ncpath/occ status | grep "versionstring" | awk '{print $3}')
ncversion=$(curl -s -m 900 $ncrepo/ | tac | grep unknown.gif | sed 's/.*"nextcloud-\([^"]*\).zip.sha512".*/\1/;q')

# Must be root
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script, type: sudo -i"; exit 1; }

# Upgrade Nextcloud
echo ""
echo ""
echo "Checking latest released version on the Nextcloud download server and if it's possible to download..."
wget -q -T 10 -t 2 $ncrepo/nextcloud-$ncversion.tar.bz2 > /dev/null
if [ $? -eq 0 ]; then
	echo ""
    printf $ugreen"SUCCESS!\n"$reset
	rm -f nextcloud-$ncversion.tar.bz2
else
    echo
    printf $lightred"Nextcloud $ncversion doesn't exist.\n"$reset
    echo "Please check available versions here: $ncrepo"
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
if version_gt "$ncversion" "$currentversion"
then
	echo ""
    printf "Latest version is: ${ugreen}${ncversion}${reset}. Current version is: ${ugreen}${currentversion}\n"$reset
	echo ""
    printf $green"New version available! Upgrade continues...\n"$reset
	echo ""
	sleep 2
else
	echo ""
    printf "Latest version is: ${ugreen}${ncversion}${reset}. Current version is: ${ugreen}${currentversion}\n"$reset
	echo ""
    echo "No need to upgrade, this script will exit..."
	echo "Your Nextcloud Version $ncversion is already up to date - No upgrade needed - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
	sleep 2
    exit 0
fi

if [[ "$backupenabled" == "true" ]]; then
	echo "Backing up files and upgrading to Nextcloud $ncversion in 5 seconds..." 
else
	echo "Upgrading to Nextcloud $ncversion in 5 seconds..." 
fi
echo "Press CTRL+C to abort."

printf "  |===>                |   (20%%)\r"
sleep 1
printf "  |=======>            |   (40%%)\r"
sleep 1
printf "  |===========>        |   (60%%)\r"
sleep 1
printf "  |===============>    |   (80%%)\r"
sleep 1
printf "  |===================>|   (100%%)\r"
printf "\n"

### For NC <12 only
sudo -u $htuser php $ncpath/occ app:list > /tmp/list_before_$name

if [[ "$backupenabled" == "true" ]]; then
	# Backup data
	echo ""
	printf $yellow"Backing up data... That may take some time - depending on your Installation!\n"$reset
	echo ""

	rsync -Aax $ncpath/config $backup 
	rsync -Aax $ncpath/themes $backup
	rsync -Aax $ncpath/apps $backup

	rsync_param_data="-Aaxv"
	rsync "$rsync_param_data" $ncpath/data $backup  |\

	pv -lep -s $(rsync "$rsync_param_data"n $ncpath/data $backup  | awk 'NF' | wc -l)

else
	{
	rm -rf `find $ncpath/. |grep -v "data"|grep -v "config"|grep -v "themes"|grep -v "apps"`
	} &> /dev/null
fi

	unalias rm     2> /dev/null
	rm $ncpath/${file}     2> /dev/null
	rm $ncpath/${file}.gz  2> /dev/null
	sleep 1

	# Database Backup
	echo ""
	printf $yellow"Starting Database Backup...\n"$reset
	echo ""
	sleep 1
	# use this command for a database server on a separate host:
	#mysqldump --opt --protocol=TCP --user=${user} --password=${pass} --host=${dbserver} ${database} > $ncpath/${file}

	# use this command for a database server on localhost. add other options if need be.
	mysqldump --opt --user=${user} --password=${pass} ${database} > $ncpath/${file}

	gzip $file
	printf $green"${file}.gz was created\n"$reset
	sleep 1
	echo ""

function dbrestore {
		echo ""
		printf $yellow"Restoring Database...\n"$reset
		gunzip $ncpath/${file}.gz
		echo "$ncpath/${file}"
		mv $ncpath/${file} ${restore}
		mysql --user=${user} --password=${pass} ${database} < $ncpath/${restore}
		echo ""
		printf $green"Database restored successfully...\n"$reset
		echo ""
		echo "NEXTCLOUD UPDATE FAILED - Database restored successfully - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		sleep 1
}

if [[ $? > 0 ]]
then
	if [[ "$backupenabled" == "true" ]]; then
		printf $red"Backup was not OK.${reset} Please check $backup and see if the folders are backed up properly"
		echo "NEXTCLOUD UPDATE FAILED - Backup wasn't successfull - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		exit 1
	else
		printf $red"Backup was not OK.${reset} Please check $ncpath and see if the folders still exist"
		echo "NEXTCLOUD UPDATE FAILED - Backup wasn't successfull - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
else
    printf $ugreen"Backup OK!\n"$reset
	echo ""
	sleep 1
fi

echo "Downloading $ncrepo/nextcloud-$ncversion.tar.bz2..."
echo ""
wget -q -T 10 -t 2 $ncrepo/nextcloud-$ncversion.tar.bz2 -P $html

if [ -f $html/nextcloud-$ncversion.tar.bz2 ]; then
    printf "$html/nextcloud-$ncversion.tar.bz2 ${green}exists\n"$reset
else
    echo "Aborting,something went wrong with the download"
	echo "NEXTCLOUD UPDATE FAILED - Download couldn't be completed - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
	dbrestore
    exit 1
fi

if [[ "$backupenabled" == "true" ]]; then
	if [ -d $backup/config/ ]; then
		printf "$backup/config/ ${green}exists\n"$reset
	else
		echo "Something went wrong with backing up your old nextcloud instance, please check in $backup if config/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /config couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
else
	if [ -d $ncpath/config/ ]; then
		printf "$ncpath/config/ ${green}exists\n"$reset
	else
		echo "Something went wrong with backing up your old nextcloud instance, please check in $ncpath if config/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /config couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
fi

if [[ "$backupenabled" == "true" ]]; then
	if [ -d $backup/data/ ]; then
		printf "$backup/data/ ${green}exists\n"$reset
	else
		echo "Something went wrong with backing up your old nextcloud instance, please check in $backup if data/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /data couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
else
	if [ -d $ncpath/data/ ]; then
		printf "$ncpath/data/ ${green}exists\n"$reset
	else
		echo "Something went wrong with backing up your old nextcloud instance, please check in $ncpath if data/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /data couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
fi

if [[ "$backupenabled" == "true" ]]; then
	if [ -d $backup/apps/ ]; then
		printf "$backup/apps/ ${green}exists\n"$reset
	else
		echo "Something went wrong with backing up your old nextcloud instance, please check in $backup if apps/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /apps couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
else
	if [ -d $ncpath/apps/ ]; then
		printf "$ncpath/apps/ ${green}exists\n"$reset
	else
		echo "Something went wrong with backing up your old nextcloud instance, please check in $ncpath if apps/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /apps couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
fi

if [[ "$backupenabled" == "true" ]]; then
	if [ -d $backup/themes/ ]; then
		printf "$backup/themes/ ${green}exists\n"$reset
    else 
	echo "Something went wrong with backing up your old nextcloud instance, please check in $backup if apps/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /apps couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
else
	if [ -d $ncpath/themes/ ]; then
		printf "$ncpath/themes/ ${green}exists\n"$reset
    else 
	echo "Something went wrong with backing up your old nextcloud instance, please check in $ncpath if apps/ folder exist."
		echo "NEXTCLOUD UPDATE FAILED - /apps couldn't be backed up - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
		dbrestore
		exit 1
	fi
fi

	echo ""
	if [[ "$backupenabled" == "true" ]]; then
		printf $green"All files are backed up.\n"$reset
		sleep 1
		echo ""
		echo "Removing old Nextcloud instance in 5 seconds..."
	else
		printf $green"All files are okay.\n"$reset
		echo ""
		echo "Removing old Nextcloud files in 5 seconds..."
	fi	

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

if [[ "$backupenabled" == "true" ]]; then
    rm -rf $ncpath
	echo ""
	printf $green"All files removed!\n"$reset
	echo ""
	sleep 1
fi

	printf $yellow"Files are being extracted... \n"$reset
	echo ""

	pv -w 80 $html/nextcloud-$ncversion.tar.bz2 | tar xjf - -C $html

if [[ "$backupenabled" == "true" ]]; then
	mkdir -p $ncpath
	mv $standardpath/* $ncpath/
	mv $standardpath/.htaccess $ncpath/
	mv $standardpath/.user.ini $ncpath/
else
	{
	rm -rf $standardpath/data
	rm -rf $standardpath/config
	rm -rf $standardpath/apps
	rm -rf $standardpath/themes
	rm -f $ncpath/.htaccess
	rm -f $ncpath/.user.ini
	} &> /dev/null
	mv $standardpath/* $ncpath/
	mv $standardpath/.htaccess $ncpath/
	mv $standardpath/.user.ini $ncpath/
fi
	rm $html/nextcloud-$ncversion.tar.bz2
	sleep 1

	echo ""
	printf $green"Extract completed.\n"$reset
	echo ""
	sleep 1

if [[ "$backupenabled" == "true" ]]; then
	printf $yellow"Copying files back to installation.... That may take a long time - depending on your installation!\n"$reset
	echo ""
    cp -R $backup/themes $ncpath/
	cp -R $backup/config $ncpath/
	cp -R $backup/data $ncpath/
	
	printf $green"Copying completed.\n"$reset
	echo ""
	sleep 2
fi	

	# remove config.sample.php
	rm -f $ncpath/config/config.sample.php
	printf $yellow"Setting file permissions...\n"$reset
	echo ""

	# Fix permissions
	chown -R ${rootuser}:${htgroup} ${ocpath}/
	chown -R ${htuser}:${htgroup} ${ocpath}/apps/
	chown -R ${htuser}:${htgroup} ${ocpath}/config/
	chown -R ${htuser}:${htgroup} ${ocpath}/data/
	chown -R ${htuser}:${htgroup} ${ocpath}/themes/
	chown -R ${htuser}:${htgroup} ${ocpath}/updater/

	sleep 2
	printf $green"File permissions set successfully!\n"$reset
	echo ""

	# occ upgrade
	printf $green"Starting Upgrade Process....\n"$reset
	sleep 2
	echo ""
	chmod +x $ncpath/occ

	echo ""
    sudo -u $htuser php $ncpath/occ upgrade

	### For NC <12 only
	sudo -u $htuser php $ncpath/occ app:list > /tmp/list_after_$name
	diff <(sed -n "/Enabled:/,/Disabled:/p" /tmp/list_before_$name) <(sed -n "/Enabled:/,/Disabled:/p" /tmp/list_after_$name) | grep '<' | cut -d- -f2 | cut -d: -f1 | xargs -L 1 sudo -u $htuser php $ncpath/occ app:enable
	rm -f /tmp/list_after_$name
	rm -f /tmp/list_before_$name

if [[ "$backupenabled" == "true" ]]; then
	# Change owner of $backup folder to root
	chown -R root:root $backup
fi

currentversion_after=$(sudo -u $htuser php $ncpath/occ status | grep "versionstring" | awk '{print $3}')
if [[ "$ncversion" == "$currentversion_after" ]]
then
    echo
    echo "Latest version is: $ncversion. Current version is: $currentversion_after."
	echo ""
	printf $ugreen"UPGRADE SUCCESS!\n"$reset
    echo ""
    echo "NEXTCLOUD UPDATE $CURRENTVERSION_after success - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
	
	# Send E-Mail if successfully updated
	echo "Hey there!

Your Nextcloud-Update completed successfully!
	
Host: $host 
Name: $name
directory: $ncpath
	
`date +"%d.%m.%Y-%H:%M:%S"`

Thank you for using Piet's Host Nextcloud-Updater!" | mail -s "NEXTCLOUD UPDATE SUCCESS - `date +"%d.%m.%Y"`" $email
    sudo -u $htuser php $ncpath/occ status
	echo ""
    sudo -u $htuser php $ncpath/occ maintenance:mode --off
    echo
    echo "Thank you for using Piet's Host Nextcloud-Updater!"
	echo ""
    ## Uncomment, if you want to reboot your server after upgrade
    # reboot
    exit 0
else
    echo
	printf "\e[40;38;4;82mLatest: $ncversion \e[30;48;4;82mCurrent: $currentversion_after \n"$reset
    sudo -u $htuser php $ncpath/occ status
    printf $red"UPGRADE FAILED!\n"$reset
    echo "Your files are still backed up at $ncpath. No worries!"
    echo "Please report this issue to support@piets-host.de"
	echo ""
	echo "NEXTCLOUD UPDATE FAILED - `date +"%d.%m.%Y"`" >> /var/log/ncupdater/ncupdater_$name.log
    exit 1
fi
