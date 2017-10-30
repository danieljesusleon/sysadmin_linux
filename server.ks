#version=RHEL7
# System authorization information
auth --enableshadow --passalgo=sha512

# Use CDROM installation media
#url --url="http://mirror.centos.org/centos/7/os/x86_64/"
#url --url="http://192.168.122.1/pub/centos7/repo"
cdrom

# Use text install
text

# Run the Setup Agent on first boot
firstboot --enable
# Keyboard layouts
keyboard --vckeymap=latam --xlayouts='latam'
# System language
lang en_US.UTF-8

# Configuracion de red
network  --bootproto=static --device=eth0 --ip=192.168.122.254 --netmask=255.255.255.0 --gateway=192.168.122.1 --ipv6=auto --activate
network  --bootproto=static --device=eth1 --ip=10.11.1.254 --netmask=255.255.255.0 --nameserver=10.11.1.254 --ipv6=auto --activate
network  --hostname=server.example.com

# Root password
rootpw --plaintext password
# System services
services --enabled="ntpd"
# System timezone
timezone America/Argentina/Buenos_Aires --isUtc --ntpservers=0.centos.pool.ntp.org,1.centos.pool.ntp.org,2.centos.pool.ntp.org,3.centos.pool.ntp.org

# Particiones y LVM
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=vda
clearpart --drives=vda --all
ignoredisk --only-use=vda
part /boot --fstype="xfs" --ondisk=vda --size=500
part pv.124 --fstype="lvmpv" --ondisk=vda --size=1 --grow
volgroup centos --pesize=4096 pv.124
logvol swap  --fstype="swap" --size=2048 --name=swap --vgname=centos
logvol /  --fstype="xfs" --size=4096 --label="root" --name=root --vgname=centos
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
dhcp
syslinux
tftp-server
openldap-servers
openldap-clients
openldap
migrationtools
pam_krb5
krb5-server
krb5-workstation
%end

%post --nochroot
/usr/bin/cp /run/install/repo/isolinux/{vmlinuz,initrd.img,splash.png} /mnt/sysimage/boot/
%end

%post --log=/tmp/post-install.log
set -x

# Habilitar IP forwarding y configurar firewall
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
/usr/bin/firewall-offline-cmd --change-interface=eth0 --zone=external
echo "ZONE=external" >> /etc/sysconfig/network-scripts/ifcfg-eth0
/usr/bin/firewall-offline-cmd --change-interface=eth1 --zone=internal
echo "ZONE=internal" >> /etc/sysconfig/network-scripts/ifcfg-eth1
/usr/bin/firewall-offline-cmd --add-service=tftp --zone=internal
/usr/bin/firewall-offline-cmd --add-service=http --zone=internal
/usr/bin/firewall-offline-cmd --add-service=dns --zone=internal

# Montar siempre el iso, es usado como repositorio para este server y para instalar otras VMs
/usr/sbin/blkid /dev/cdrom | awk '/CentOS/ {print $2"\t/var/www/html/pub/centos7/repo\tiso9660\t_netdev\t0 0"}' >> /etc/fstab

# Preparar el repositorio de paquetes
mkdir -p /var/www/html/pub/centos7/repo
/usr/sbin/restorecon -R /var/www/html
/usr/bin/systemctl enable httpd
/usr/bin/yum-config-manager --disable > /dev/null
cat > /etc/yum.repos.d/CentOS7-Local.repo << EOF
[CentOS7-Local]
name=CentOS7 Local Server repository
baseurl=file:///var/www/html/pub/centos7/repo
enabled=1
gpgcheck=1
gpgkey=file:///var/www/html/pub/centos7/repo/RPM-GPG-KEY-CentOS-7
EOF

# Configurar servidor dhcp
/usr/bin/systemctl enable dhcpd
cat > /etc/dhcp/dhcpd.conf << EOF
allow booting;
allow bootp;
allow unknown-clients;
option domain-name-servers 10.11.1.254;
option domain-name "example.com";
authoritative;

subnet 10.11.1.0 netmask 255.255.255.0 {
   range 10.11.1.100 10.11.1.109;
   option routers 10.11.1.254;
   option broadcast-address 10.11.1.255;
   next-server 10.11.1.254;
   filename "pxelinux.0";
}
EOF

# Configurar servidor DNS
/usr/bin/systemctl enable named
cat > /etc/named.conf << EOF
options {
        listen-on port 53 { 127.0.0.1; 10.11.1.254; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { any; };
        recursion yes;
        forward only;
        forwarders { 192.168.122.1; };
        dnssec-enable yes;
        dnssec-validation no;
        dnssec-lookaside auto;
        bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "example.com" {
        type master;
        file "example.com.zone";
        allow-update { none; };
};
zone "1.11.10.in-addr.arpa" {
        type master;
        file "example.com.revzone";
        allow-update { none; };
};
zone "." IN {
        type hint;
        file "named.ca";
};
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

cat > /var/named/example.com.zone << EOF
\$TTL 86400
@ IN SOA server.example.com. root.example.com. (
20150402 ; Serial
1d ; refresh
2d ; retry
4w ; expire
1h ) ; min cache
 IN NS server.example.com.
 IN MX 10 server.example.com.

labo100 IN A 10.11.1.100
labo101 IN A 10.11.1.101
labo102 IN A 10.11.1.102
labo103 IN A 10.11.1.103
labo104 IN A 10.11.1.104
labo105 IN A 10.11.1.105
labo106 IN A 10.11.1.106
labo107 IN A 10.11.1.107
labo108 IN A 10.11.1.108
labo109 IN A 10.11.1.109
server  IN A 10.11.1.254
EOF

cat > /var/named/example.com.revzone << EOF
\$TTL 86400
@ IN SOA server.example.com. root.example.com. (
20150402 ; Serial
1d ; refresh
2d ; retry
4w ; expire
1h ) ; min cache
 IN NS server.example.com.

100     IN PTR  labo100.example.com.
101     IN PTR  labo101.example.com.
102     IN PTR  labo102.example.com.
103     IN PTR  labo103.example.com.
104     IN PTR  labo104.example.com.
105     IN PTR  labo105.example.com.
106     IN PTR  labo106.example.com.
107     IN PTR  labo107.example.com.
108     IN PTR  labo108.example.com.
109     IN PTR  labo109.example.com.
254     IN PTR  server.example.com.
EOF

# Configurar servidor PXE
/usr/bin/systemctl enable tftp.socket
/usr/bin/cp /usr/share/syslinux/{pxelinux.0,vesamenu.c32} /var/lib/tftpboot/
/usr/bin/cp /boot/{vmlinuz,initrd.img,splash.png} /var/lib/tftpboot/
/usr/bin/mkdir /var/lib/tftpboot/pxelinux.cfg
cat > /var/lib/tftpboot/pxelinux.cfg/default << EOF
default vesamenu.c32
timeout 200
menu background splash.png
ontimeout local
label linux
   menu label ^Instalar CentOS7
   menu default
   kernel vmlinuz
   append initrd=initrd.img ip=dhcp ksdevice=link ks=http://server.example.com/pub/centos7/lab.ks
label local
   menu label Iniciar desde disco rigido
   localboot 0xffff
EOF
cat > /var/www/html/pub/centos7/lab.ks << EOF
#version=RHEL7
auth --enableshadow --passalgo=sha512
url --url="http://server.example.com/pub/centos7/repo"
text
keyboard --vckeymap=latam --xlayouts='latam'
lang en_US.UTF-8
#network  --bootproto=dhcp --device=eth0  --ipv6=auto 
rootpw --plaintext password
timezone America/Argentina/Buenos_Aires --isUtc
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=vda
clearpart --drives=vda --all
ignoredisk --only-use=vda
part /boot --fstype="xfs" --ondisk=vda --size=500
part pv.125 --fstype="lvmpv" --ondisk=vda --size=2048 --grow
volgroup centos --pesize=4096 pv.125
logvol swap  --fstype="swap" --size=1024 --name=swap --vgname=centos
logvol /  --fstype="xfs" --size=4096 --label="root" --name=root --vgname=centos
reboot
\%packages
@core
-*firmware*
\%end
EOF
/usr/bin/sed -i 's/^\\%/%/g' /var/www/html/pub/centos7/lab.ks

# Configurar servidor Kerberos
cat > /var/kerberos/krb5kdc/kdc.conf << EOF
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 EXAMPLE.COM = {
  master_key_type = aes256-cts
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
  default_principal_flags = +preauth
 }
EOF

cat > /etc/krb5.conf << EOF
[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = EXAMPLE.COM
 default_ccache_name = KEYRING:persistent:%{uid}

[realms]
 EXAMPLE.COM = {
  kdc = server.example.com
  admin_server = server.example.com
}

[domain_realm]
 .example.com = EXAMPLE.COM
 example.com = EXAMPLE.COM
EOF

/usr/sbin/kdb5_util create -s -r EXAMPLE.COM -P password
/usr/bin/systemctl enable krb5kdc
/usr/bin/systemctl enable kadmin
/usr/bin/systemctl start krb5kdc
/usr/bin/systemctl start kadmin
/usr/bin/firewall-offline-cmd --add-port=749/tcp --zone=internal
/usr/bin/firewall-offline-cmd --add-service=kerberos --zone=internal


cat > /tmp/kerberos_principals << EOF
addprinc root/admin
root
root
addprinc astorni
astorni
astorni
addprinc jborges
jborges
jborges
addprinc esabato
esabato
esabato
addprinc socampo
socampo
socampo
addprinc -randkey host/server.example.com
ktadd host/server.example.com
quit
EOF
/usr/sbin/kadmin.local < /tmp/kerberos_principals

# Configurar servidor ldap
echo -n password > /etc/openldap/passwd
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
/usr/bin/systemctl enable slapd
/usr/bin/firewall-offline-cmd --add-service=ldap --zone=internal

cat > /tmp/changes.ldif << EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=example,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: password

dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/cert.pem

dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/priv.pem

dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: -1

dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=example,dc=com" read by * none
EOF

cat > /tmp/base.ldif << EOF
dn: dc=example,dc=com
dc: example
objectClass: top
objectClass: domain

dn: ou=People,dc=example,dc=com
ou: People
objectClass: top
objectClass: organizationalUnit

dn: ou=Group,dc=example,dc=com
ou: Group
objectClass: top
objectClass: organizationalUnit
EOF

cat > /tmp/groups.ldif << EOF
dn: cn=jborges,ou=Group,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: jborges
userPassword: {crypt}x
gidNumber: 1000

dn: cn=esabato,ou=Group,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: esabato
userPassword: {crypt}x
gidNumber: 1001

dn: cn=socampo,ou=Group,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: socampo
userPassword: {crypt}x
gidNumber: 1002

dn: cn=astorni,ou=Group,dc=example,dc=com
objectClass: posixGroup
objectClass: top
cn: astorni
userPassword: {crypt}x
gidNumber: 1003
EOF

cat > /tmp/users.ldif << EOF
dn: uid=jborges,ou=People,dc=example,dc=com
uid: jborges
cn: Jorge Luis Borges
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: jborges
shadowLastChange: 16546
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: 1000
gidNumber: 1000
homeDirectory: /home/jborges
gecos: Jorge Luis Borges

dn: uid=esabato,ou=People,dc=example,dc=com
uid: esabato
cn: Ernesto Sabato
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: esabato
shadowLastChange: 16546
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: 1001
gidNumber: 1001
homeDirectory: /home/esabato
gecos: Julio Cortazar

dn: uid=socampo,ou=People,dc=example,dc=com
uid: socampo
cn: Silvina Ocampo
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: socampo
shadowLastChange: 16546
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: 1002
gidNumber: 1002
homeDirectory: /home/socampo
gecos: Silvina Ocampo

dn: uid=astorni,ou=People,dc=example,dc=com
uid: astorni
cn: Alfonsina Storni
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
userPassword: astorni
shadowLastChange: 16546
shadowMin: 0
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: 1003
gidNumber: 1003
homeDirectory: /home/astorni
gecos: Alfonsina Storni
EOF

mv /etc/rc.d/rc.local /etc/rc.d/rc.local.old
cat > /etc/rc.d/rc.local << EOF
#!/bin/bash
#
# Estos comandos tienen que correr despues de que el servidor se haya instalado y reiniciado
#
exec >> /tmp/post-install.log 2>&1
while [ \$(/usr/bin/systemctl -q is-active slapd ; echo \$?) != 0 ] ;do sleep 2; done
/usr/bin/ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/cosine.ldif
/usr/bin/ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f /etc/openldap/schema/nis.ldif
/usr/bin/ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/changes.ldif
/usr/bin/ldapadd -x -w password -D cn=Manager,dc=example,dc=com -f /tmp/base.ldif
/usr/bin/ldapadd -x -w password -D cn=Manager,dc=example,dc=com -f /tmp/groups.ldif
/usr/bin/ldapadd -x -w password -D cn=Manager,dc=example,dc=com -f /tmp/users.ldif
mv /etc/rc.d/rc.local.old /etc/rc.d/rc.local
EOF
chmod +x /etc/rc.d/rc.local

# Algunos alias usados frequentemente
echo "alias destroy='echo Destroying... && dd if=/dev/zero of=/dev/vda bs=1M count=10 && reboot && exit'" >> /root/.bashrc
echo "set -o vi" >> /root/.bashrc

%end

