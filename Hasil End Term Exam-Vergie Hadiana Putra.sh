#!/bin/bash
## Author: Vergie Hadiana Putra
## Nomor Registrasi DTS PROA LINUX 4D: 152361164101-385 
## Linkedln: https://www.linkedin.com/in/vergiehadiana/
## PurPose: Answer End Term Exam Shell Script (Must Run on ROOT User)
## Date Created: 24 Oct 2022 - Due Date 27 Oct 2022 23:59 
## Link Google Class: https://classroom.google.com/c/NTQ3NzUxNDEwODgy/a/NTAzNDY5NzAyNzE5/details

#ssh root@servera or root@serverb

if [[ "${UID}" -ne 0 ]]; then
    echo " You need to run this script as root on servera or serverb"
    exit 1
fi

echo -ne '\n'
echo -ne '#	                     		(0%)\r'
echo -ne '\n'
# Nomor 1 - Create a simple partition/storage stack on serverA with 1GB of /dev/vdd, .1GB of /dev/vdb, and 1GB of /dev/vdc.. 
# 			Make sure that, the file system is xfs. Mount the storage stack to /stack and make sure it's persistent!

lsblk > before_format.txt

# Format Disk vdb, vdc and vdd 
# vdb
parted -s /dev/vdb mklabel gpt
udevadm settle
parted -s /dev/vdb mkpart primary 0% 100%
parted -s /dev/vdb set 1 lvm on
mkfs.xfs /dev/vdb1

# vdc
parted -s /dev/vdc mklabel gpt
udevadm settle
parted -s /dev/vdc mkpart primary 0% 100%
parted -s /dev/vdc set 1 lvm on
mkfs.xfs /dev/vdc1

# vdd
parted -s /dev/vdd mklabel gpt
udevadm settle
parted -s /dev/vdd mkpart primary 0% 100%
parted -s /dev/vdd set 1 lvm on
mkfs.xfs /dev/vdd1

# For Debug parted
#parted /dev/vdb print
#parted /dev/vdb print
#parted /dev/vdb print

# Create Physical Volume
pvcreate --setphysicalvolumesize 1G /dev/vdb1 -y
pvcreate --setphysicalvolumesize 1G /dev/vdc1 -y
pvcreate --setphysicalvolumesize 1G /dev/vdd1 -y

# Create Volume Group
vgcreate extra_storage /dev/vdb1 /dev/vdc1 /dev/vdd1 
#vgdisplay extra_storage

# Create Logical Volume
lvcreate -l 100%FREE -n vol_stack extra_storage 
#lvdisplay /dev/extra_storage/vol_stack

# Format filesystem to xfs
mkfs.xfs /dev/extra_storage/vol_stack

# Create folder /stack
rmdir /stack
mkdir /stack

# Get UUID partition
uuid_extrastorage=$(blkid -s UUID -o value /dev/extra_storage/vol_stack)
echo "UUID for /dev/extra_storage/vol_stack is $uuid_extrastorage"

# insert UUID new partition /stack using LVM
echo "#mount extrastorage for /stack" >> /etc/fstab
echo "UUID=$uuid_extrastorage    /stack    xfs    defaults    0    0" >> /etc/fstab

# Check fstab and mount
systemctl daemon-reload
cat /etc/fstab
mount -a

lsblk  > after_format.txt
lsblk -fp

echo -ne '####							(12%)\r'
sleep 1
echo -ne '\n'


# Nomor 2 - Please create a scheduling job every day at 08:00 am, by fetching https://wttr.in/Surabaya?T0 using curl, and put the output into /tmp/weather-(date).txt. 
# 			Date format should be yyyy-mm-dd.

# Check Location Surabaya and save to file by date ()
date=$(date '+%Y-%m-%d') && curl https://wttr.in/Surabaya > /tmp/weather-sby-$date.txt

# Create scheduling on crontab
(crontab -l && echo "0 8 * * * date=$(date '+%Y-%m-%d') && curl https://wttr.in/Surabaya?T0 > /tmp/weather-$date.txt") | crontab -

echo -ne '#######						(25%)\r'
sleep 1
echo -ne '\n'


# Nomor 3 - Please apply configuration to server with high throughput plan using tuned! Make sure tuned already installed and the service already enabled!

# Check tuned installed and services has been started
dnf install tuned -y
systemctl enable --now tuned
systemctl is-active tuned
#systemctl status tuned

# Set High-Throughput Plan from tuned list
tuned-adm active
tuned-adm profile throughput-performance
tuned-adm active

echo -ne '##########					(37%)\r'
sleep 1
echo -ne '\n'


# Nomor 4 - User want to use /data/www as httpd/apache web directory, but encounter error, please apply a selinux configuration to make it works, and move the 
#			default web server root directory to /data/www (also check whether the folder exist or not.), and change the httpd port to 8000

# Install httpd and run the services
yum install httpd -y
systemctl enable --now httpd
systemctl is-active httpd
#systemctl status httpd.service

# create directory/data/www and create symbolic link to /var/www/html and create index.html for test
mkdir -p /data/www/
ln -s /var/www/html/ /data/www/
echo "Httpd on RHEL 9.0 by Vergie" > /data/www/html/index.html
ls -lah /data/www/html/ /var/www/html/

# Change default port httpd 80 to 8000 and Set SELinux Rules for Port 8000
sed -i 's/Listen 80$/Listen 8000/' /etc/httpd/conf/httpd.conf
semanage port -a -t http_port_t -p tcp 8000	#add if doesnt add before
semanage port -m -t http_port_t -p tcp 8000 #modify if exist
semanage port -l | grep '^http_port_t'

# Restart Services httpd and allow firewall for port http and 8000/tcp
systemctl restart httpd.service 
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload

echo "\nTest Check Access using port 80 (default http) and 8000\n"
curl -k http://servera.lab.example.com:8000
curl -k http://servera.lab.example.com

echo -ne '#############					(50%)\r'
sleep 1
echo -ne '\n'


# Nomor 5 - You are tasked with enabling home userdir with apache/httpd, but even with right selinux file context, you still encounter error, 
#			please troubleshoot and write down the command that need to be enabled so userdir will work!

yum install policycoreutils -y

sealert -a /var/log/audit/audit.log
ausearch -m avc | audit2allow

ls -laZ /data/www/

setsebool -P httpd_enable_homedirs true
semanage fcontext -a -t httpd_sys_content_t '/data/www(/.*)?'
restorecon -Rv /data/www/

ls -laZ /data/www/


echo -ne '################				(62%)\r'
sleep 1
echo -ne '\n'


# Nomor 6 - An php script need to write in /var/www/home/upload, but can't write on the folder. Based on the php-fpm.log report, it raise permission denied error. 
#			When you check the permissions, it already set to apache:apache as the folder owner with appropriate rwx permissions for the folder. 
#			You got error on selinux error as it has httpd_sys_content_t, based on this information, what should you do in order to make php script can write into that folder.

mkdir -p /var/www/home/upload/
ls -laZ /var/www/home/upload/

semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/home/upload(/.*)?'
restorecon -RFv /var/www/home/upload

echo -ne '###################			(75%)\r'
sleep 1
echo -ne '\n'


# Nomor 7 - There are need to create a stratis pool, you need to create simple stratis pool and inhibit whole /dev/vdb (5GB), after that make sure you mount it persistently.

lsblk -fp

# Comment UUID for /stack from Question Number 1
eval "$( blkid -o export /dev/extra_storage/vol_stack )"
sed -i '/^UUID='"$UUID"'/ s/^/#/' /etc/fstab

# Unmount and Remove LV VG PV from Question Number 1
umount /stack
lvremove /dev/extra_storage/vol_stack -y
vgremove extra_storage -y
pvremove /dev/vdb1 /dev/vdc1 /dev/vdd1 -y
# Remove partition table and filesystem https://man7.org/linux/man-pages/man8/wipefs.8.html
wipefs -a /dev/vdb
wipefs -a /dev/vdc
wipefs -a /dev/vdd
lsblk -fp

systemctl daemon-reload

# Install and enable services Stratis
dnf install stratisd stratis-cli -y
systemctl enable --now stratisd
systemctl is-active stratisd
#systemctl status stratisd

# create Pool and Filesystem
stratis pool create pool_simple /dev/vdb
stratis pool list
stratis fs create pool_simple fs_test
stratis fs list

rmdir /stratis-storage
mkdir /stratis-storage

# edit fstab to mount stratis 
uuid_stratisstorage=$(blkid -s UUID -o value /dev/stratis/pool_simple/fs_test)
echo "UUID for /dev/stratis/pool_simple/fs_test is $uuid_stratisstorage"
echo "#mount Stratis Pool for /stratis-storage" >> /etc/fstab
echo "UUID=$uuid_stratisstorage    /stratis-storage    xfs    defaults    0    0" >> /etc/fstab

blkid -p /dev/stratis/pool_simple/fs_test

# reload daemon and mount the fs
systemctl daemon-reload
cat /etc/fstab
mount -a

lsblk -fp

### FOR DELETE Stratis FS and POOL
#umount /stratis-storage
#stratis filesystem destroy pool_simple fs_test
#stratis pool destroy pool_simple

echo -ne '######################		(87%)\r'
sleep 1
echo -ne '\n'


# Nomor 8 - You need to run docker.io/library/mysql latest version, mount it's port to 13306, and mount it's data folder to /home/student/mysql, name mysql8. 
#			Make sure it works and make it accessible from other machine! After your are successful in creating the instance, make it auto start as a service when boot.

dnf install container-tools jq mariadb -y 

podman login --tls-verify=false registry.lab.example.com -u admin -p redhat321
skopeo inspect --tls-verify=false docker://registry.lab.example.com/rhel8/mariadb-103 | jq -r '.RepoTags'

# Create Directory for data folder
rmdir /home/student/mysql
mkdir -p /home/student/mysql
chmod 777 /home/student/mysql

# Create Docker Container
podman run --tls-verify=false -d --name mysqldb -p 13306:3306 \
-e MYSQL_USER=student \
-e MYSQL_PASSWORD=student \
-e MYSQL_DATABASE=studentdb \
-e MYSQL_ROOT_PASSWORD=redhat \
-v /home/student/mysql:/var/lib/mysql/data:Z \
registry.lab.example.com/rhel8/mariadb-103:latest

echo "\n Testing access to container mysqldb and check data files... \n" 
sleep 5s 
# Test Connection MYSQL Docker
mysql -u student --password=student --port=13306 --host=127.0.0.1 -e "show databases"
mysql -u student --password=student --port=13306 --host=127.0.0.1 -e "show databases" | grep studentdb; if [ $? -eq 0 ]; then echo SUCCESS; else echo FAILED; fi

ls -lah /home/student/mysql
podman ps
sleep 5s

echo "\n Generate Systemd unit file and try remove existing running container... \n" 
podman generate systemd --new --files --name mysqldb
cat ./container-mysqldb.service 
cp ./container-mysqldb.service /usr/lib/systemd/system 

podman stop mysqldb
podman rm mysqldb
podman ps
sleep 5s

echo "\n Set auto-starting for containers and check container running...  \n" 

systemctl daemon-reload
systemctl enable --now container-mysqldb.service
systemctl is-active container-mysqldb.service
#systemctl status container-mysqldb.service

podman ps
loginctl enable-linger

### FOR REMOVE ONLY
#systemctl stop container-mysqldb.service
#systemctl disable container-mysqldb.service
#rm -f /usr/lib/systemd/system/container-mysqldb.service
#rm -f ./container-mysqldb.service
#podman stop mysqldb
#podman rm mysqldb
#podman rmi -f registry.lab.example.com/rhel8/mariadb-103

echo -ne '#########################		(100%)\r'
echo -ne '\n'
echo 'Script Ended...'
exit 0
