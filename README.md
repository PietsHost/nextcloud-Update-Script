# Nextcloud Update-Script

This script features an automatic Backup & Update of your Nextcloud installation, using occ.<br />
The script will check your installed version (e.g. 10.0.0) and the latest release-version (e.g. 10.0.2).<br />
If an update is available, the script will backup the following folders: /data, /config, /themes, /apps<br />
It also backups your current database - just in case, the upgrade goes wrong!

The script will check whether the backup was successful or not, and then it begins the update process by downloading the latest release.

If everything goes as expected, the script will use the occ upgrade command to upgrade your nextcloud installation.  You will receive an email upon successful installation. If the upgrade process fails, your database will be restored

That's it! Visit your website and enjoy the latest version of Nextcloud!


## update script of the official Nextcloud VM by Tech and Me, maintened by:
* [Daniel Hanson](https://github.com/enoch85) @ [Tech and Me](https://www.techandme.se)
* [Ezra Holm](https://github.com/ezraholm50) @ [Tech and Me](https://www.techandme.se)
* [Luis Guzman](https://github.com/Ark74) @ [SwITNet](https://switnet.net)


# Usage
Simply change lines 22 - 34 to suit your needs:
```
# Directories - change the following lines to suit your needs
HTML=/var/www/html		# root html directory
BACKUP=$HTML/backup		# name of the backup folder, which will be created
NCPATH=$HTML/nextcloud1	# name of your subfolder in html directory, where your nextcloud installation is located
EMAIL=example@domain.com	# will be used for sending emails, if upgrade was successfull
htuser='apache'  		 # Webserver-User (CentOS: apache, suseLinux: wwwrun, etc..)
htgroup='apache' 		 # Webserver-Group (CentOS: apache, suseLinux: www, etc...)
NAME=nextcloud_install_1 # Define a name for your Instance, which will be upgraded

# Database Variables - Look in your config.php
DBSERVER=127.0.0.1		# Database host
DATABASE=databasename	# Database name
USER=databaseuser		# Database username
PASS=S€crEtP@s$			# Database password
```

After that, set +x to the script and run it:
```
chmod +x ./ncupdate.sh
./ncupdate.sh
```

## Notes
* Tested on CentOS 6.8 & 7.3
* Tested on openSUSE Leap 42.1

I'm sure it will work on every Linux System, even if I haven't tested it yet :)

## Requirements
This script requires the following packages: bzip2 rsync pv php5-posix

* CentOS / RHEL:
```
yum install -y bzip2 rsync pv php5-posix
```
* openSUSE:
```
zypper in bzip2 rsync pv php5-posix
```

<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/">Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License</a>.
