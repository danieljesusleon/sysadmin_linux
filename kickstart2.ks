# System authorization information
auth  --useshadow  --passalgo=sha512
# Use CDROM installation media
cdrom
# Use text mode install
text
firstboot --enable
# Keyboard layouts
keyboard 'la-latin1'
# System language
lang es_VE
# Network information
network  --bootproto=static --device=enp0s3  --ip=192.168.0.80  --netmask=255.255.255.0 --gateway=192.168.0.1 --nameserver=192.168.0.78 --activate
network --hostname=localhost
# Root password
rootpw --plaintext manager
# System timezone
timezone America/Caracas
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Firewall configuration
firewall --enabled --http --ssh
# SELinux configuration
selinux --enforcing
# Halt after installation
#halt
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
# Partition clearing information
clearpart --drives=sda --all
# Disk partitioning information
ignoredisk  --only-use=sda
part /boot --fstype="xfs" --ondisk=sda --size=500
part pv.124 --fstype="lvmpv" --ondisk=sda --size=1 --grow
volgroup centos --pesize=8192 pv.124
logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=centos
logvol /  --fstype="xfs" --size=8192 --label="root" --name=root --vgname=centos
reboot

%packages
@core
-*firmware*
ntp
kexec-tools
yum-utils
bash-completion
vim-enhanced
httpd
bind
git
syslinux
tftp-server
net-tools
lvm2
mlocate
policycoreutils-python
wget
curl
firewalld
%end

%post --log=/tmp/post-install.log
exec >> /tmp/post-install.log 2>&1
/usr/bin/firewall-offline-cmd --add-service=mysql
/usr/bin/firewall-offline-cmd --add-service=http
/usr/bin/firewall-offline-cmd --add-service=https
/usr/bin/systemctl enable httpd
/usr/bin/systemctl start httpd
/usr/bin/wget http://192.168.0.81/epel.repo
/usr/bin/wget http://192.168.0.81/remi-php54.repo
/usr/bin/wget http://192.168.0.81/remi.repo
/usr/bin/mv *.repo /etc/yum.repos.d/
/usr/bin/wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
/usr/bin/wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
/usr/bin/rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
/usr/bin/rpm --import http://192.168.0.81/RPM-GPG-KEY-EPEL-7
/usr/bin/rpm -K epel-release-7-10.noarch.rpm
/usr/bin/rpm -ivh epel-release-7-10.noarch.rpm
/usr/bin/wget https://rpms.remirepo.net/RPM-GPG-KEY-remi
/usr/bin/mv RPM-GPG-KEY-remi /etc/pki/rpm-gpg/
/usr/bin/yum remove -y mariadb-libs
/usr/bin/rpm -ivh mysql-community-release-el7-5.noarch.rpm
/usr/bin/yum install -y mysql-server mysql php php-gd php-mysql php-mcrypt
/usr/bin/systemctl start mysqld
/usr/bin/wget http://192.168.0.81/drotacap_test.sql
/usr/bin/wget http://192.168.0.81/drotaca_code.tar
/usr/bin/tar xvf drotaca_code.tar
/usr/bin/mv drotaca_test/ /var/www/
/usr/bin/chown -R apache.apache /var/www/
/usr/sbin/semanage fcontext -a -t httpd_sys_content_t "/var/www/drotaca_test(/.*)?"
/usr/sbin/restorecon -Rv /var/www/
/usr/bin/sed -i -e 's/var\/www\/html/var\/www\/drotaca_test/g' /etc/httpd/conf/httpd.conf
/usr/bin/touch create.sh
/usr/bin/echo "#!/bin/bash" >> create.sh
/usr/bin/echo "/usr/bin/mysql <<EOF" >> create.sh
/usr/bin/echo "CREATE DATABASE drotacap_test;" >> create.sh
/usr/bin/echo "UPDATE mysql.user SET Password=PASSWORD('manager') WHERE User='root';" >> create.sh
/usr/bin/echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';" >> create.sh
/usr/bin/echo "DELETE FROM mysql.user WHERE User='';" >> create.sh
/usr/bin/echo "DROP DATABASE IF EXISTS test;" >> create.sh
/usr/bin/echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" >> create.sh
/usr/bin/echo "FLUSH PRIVILEGES;" >> create.sh
/usr/bin/echo "EOF" >> create.sh
/usr/bin/echo "systemctl restart mysqld" >> create.sh
/usr/bin/echo "mysql -u root -pmanager drotacap_test < /drotacap_test.sql" >> create.sh
/usr/bin/chmod +x create.sh
/usr/bin/chown mysql.mysql create.sh
/usr/bin/touch /usr/lib/systemd/system/create.service
/usr/bin/echo "[Unit]" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "After=mysqld.service" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "[Service]" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "Type=simple" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "TimeoutStartSec=9min" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "ExecStart=/create.sh" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "[Install]" >> /usr/lib/systemd/system/create.service
/usr/bin/echo "WantedBy=multi-user.target" >> /usr/lib/systemd/system/create.service
/usr/bin/systemctl enable create.service
%end
