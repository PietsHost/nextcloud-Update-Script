#!/bin/sh
#
## Piet's Host ## - ©2017, https://piets-host.de
#
# Tested on CentOS 6.8 & 7.3
# Tested on openSUSE Leap 42.1
#
# Most part of this script is based on the install script from dore42/manual_nextcloud

#nextcloud_version_11.0.2
echo -n "Enter the username of you raspberry-pi [default is pi]: "
read username
echo -n "Enter the password for the root database: "
read database_password
echo -n "Enter the username for the nextcloud admin user: "
read admin_user
echo -n "Enter the password for the nextcloud admin user: "
read admin_password
echo -n "Enter the max upload size that you want [MB]: "
read upload_max_filesize
let "post_max_size = $upload_max_filesize + 40"
echo -n "Enter your domain: "
read domain
echo -n "Enter your mail (for SSL certification): "
read mail

#need to echo to here : DBpass X2 for the next row
echo "$database_password\n$database_password\n"
mysql -u root -p$database_password -e "CREATE DATABASE ncdb"
mysql -u root -p$database_password -e "USE ncdb"
mysql -u root -p$database_password -e "GRANT ALL PRIVILEGES ON nextcloud.* TO '$username'@'localhost' IDENTIFIED BY '$database_password'"
cd /home/pi/Documents/
wget https://download.nextcloud.com/server/releases/nextcloud-11.0.2.tar.bz2
sudo tar jxf nextcloud-11.0.2.tar.bz2 -C /var/www/
touch nextcloud_permissions.sh
cat <<'EOF' >> nextcloud_permissions.sh
#!/bin/bash
ocpath='/var/www/nextcloud'
htuser='www-data'
htgroup='www-data'
rootuser='root'
printf "Creating possible missing Directories\n"
mkdir -p $ocpath/data
mkdir -p $ocpath/assets
mkdir -p $ocpath/updater
printf "chmod Files and Directories\n"
find ${ocpath}/ -type f -print0 | xargs -0 chmod 0640
find ${ocpath}/ -type d -print0 | xargs -0 chmod 0750
printf "chown Directories\n"
chown -R ${rootuser}:${htgroup} ${ocpath}/
chown -R ${htuser}:${htgroup} ${ocpath}/apps/
chown -R ${htuser}:${htgroup} ${ocpath}/assets/
chown -R ${htuser}:${htgroup} ${ocpath}/config/
chown -R ${htuser}:${htgroup} ${ocpath}/data/
chown -R ${htuser}:${htgroup} ${ocpath}/themes/
chown -R ${htuser}:${htgroup} ${ocpath}/updater/
chmod +x ${ocpath}/occ
printf "chmod/chown .htaccess\n"
if [ -f ${ocpath}/.htaccess ]
then
 chmod 0644 ${ocpath}/.htaccess
 chown ${rootuser}:${htgroup} ${ocpath}/.htaccess
fi
if [ -f ${ocpath}/data/.htaccess ]
then
 chmod 0644 ${ocpath}/data/.htaccess
 chown ${rootuser}:${htgroup} ${ocpath}/data/.htaccess
fi
EOF
sudo chmod +x nextcloud_permissions.sh
sudo ./nextcloud_permissions.sh
rm nextcloud_permissions.sh


cd /home/pi/Documents/
sudo -u www-data php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name "ncdb" --database-user "root" --database-pass "$database_password" --admin-user "$admin_user" --admin-pass "$admin_password"
#can add a different directory than /var/www/nextcloud/data, by adding < --data-dir="/home/pi/whatever.." > to the command line above. (theres error with doing it, it can't write there...)


sudo -u www-data php /var/www/nextcloud/occ config:system:set trusted_domains 2 --value=$domain
