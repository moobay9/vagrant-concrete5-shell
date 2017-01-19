#!/bin/sh
# Copyright Funaffect, Inc. (M.Oobayashi)

### Parameter

CONCRETE5_DL_PATH="https://www.concrete5.org/download_file/-/view/93074/"

CONCRETE5_DB_NAME=concrete5
CONCRETE5_DB_USER=c5_user
CONCRETE5_DB_PASS=c5_password
CONCRETE5_DB_HOST=localhost

MYSQL_PASSWORD=mysqlpassword

HTTPCNF=/etc/httpd/conf/httpd.conf
MYCNF=/etc/my.cnf
PHPINI=/etc/php.ini

### rpm
rpm -ivh http://ftp.iij.ad.jp/pub/linux/fedora/epel/6/i386/epel-release-6-8.noarch.rpm
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

sed -i 's/^#baseurl/baseurl/g' /etc/yum.repos.d/epel.repo
sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/epel.repo




### HTTPd Install
yum -y install httpd httpd-devel mod_ssl

sed -i "s/ServerTokens OS/ServerTokens Prod/g" $HTTPCNF
sed -i "s/ServerAdmin root@localhost/ServerAdmin webmaster@example.com/g" $HTTPCNF
sed -i "s/\#ServerName new\.host\.name:80/ServerName `hostname`:80/g" $HTTPCNF
sed -i "s/\#ServerName www\.example\.com:80/ServerName `hostname`:80/g" $HTTPCNF
sed -i "s/Options Indexes FollowSymLinks/Options -Indexes FollowSymLinks/g" $HTTPCNF
sed -i "s/\# DefaultLanguage nl/DefaultLanguage ja/g" $HTTPCNF
sed -i "s/LanguagePriority en ca cs da de el eo es et fr he hr it ja/LanguagePriority ja en ca cs da de el eo es et fr he hr it/g" $HTTPCNF
sed -i "s/^Alias \/icons\//#Alias \/icons\//" $HTTPCNF
sed -i "s/^Alias \/error\//#Alias \/error\//" $HTTPCNF
sed -i "s/End of proxy directives\./End of proxy directives\.\n\nTraceEnable Off\n/g" $HTTPCNF

cat << _EOFVH_ > /etc/httpd/conf.d/concrete5.conf
#---- concrete5 -------------------------------------\n<VirtualHost *:80>\n\tServerAdmin\twebmaster@example.com\n\tDocumentRoot\t/vagrant/htdocs\n\tServerName\tconcrete5.vagrant.localhost\n\n\tDirectoryIndex\t\tindex.html index.php\n\tAddDefaultCharset\tUTF-8\n\n\t<Directory /vagrant/htdocs>\n\t\tOptions\t\tFollowSymLinks\n\t\tAllowOverride\tAll\n\t\tEnableSendfile\tOff\n\t</Directory>\n</VirtualHost>\n\n
_EOFVH_
sed -i 's/\\t/\t/g' /etc/httpd/conf.d/concrete5.conf
sed -i 's/\\n/\n/g' /etc/httpd/conf.d/concrete5.conf


mkdir /vagrant/htdocs

service httpd start
chkconfig httpd on


### PHP Install
yum -y --enablerepo=remi,remi-php71 install php php-devel php-gd php-mbstring php-pear php-bcmath php-mysqlnd php-pdo php-xml php-json php-pecl-zip

echo "output_handler = mb_output_handler" >> ${PHPINI}
echo "default_charset = \"UTF-8\"" >> ${PHPINI}
echo "include_path = \".:/usr/lib/php:/usr/share/pear\"" >> ${PHPINI}
echo "mbstring.language = Japanese" >> ${PHPINI}
echo "mbstring.internal_encoding = UTF-8" >> ${PHPINI}
echo "mbstring.http_input = auto" >> ${PHPINI}
echo "mbstring.http_output = UTF-8" >> ${PHPINI}
echo "mbstring.encoding_translation = Off" >> ${PHPINI}
echo "mbstring.detect_order = auto" >> ${PHPINI}
echo "mbstring.substitute_character = none;" >> ${PHPINI}

sed -i 's/;date.timezone =/;date.timezone =\ndate.timezone = Asia\/Tokyo/g' ${PHPINI}

service httpd graceful

### MySQL Install
yum -y install mysql mysql-devel mysql-server

service mysqld start
chkconfig mysqld on
service mysqld stop

rm -rf /var/lib/mysql
rm -f /etc/my.cnf
cp -p /usr/share/doc/mysql-server-5.1.*/my-medium.cnf $MYCNF

sed -i "s/\[client\]/[client]\ndefault-character-set = utf8/g" $MYCNF
sed -i "s/\[mysqld\]/[mysqld]\ndatadir = \/var\/lib\/mysql\/data\ncharacter-set-server = utf8\nlog-error = \/var\/log\/mysql\/error.log\nslow_query_log_file = \/var\/log\/mysql\/slow-queries.log\nsync_binlog = 1\ndefault-storage-engine=innodb\nexpire_logs_days = 14\n\ninnodb_file_per_table\n/g" $MYCNF
sed -i "s/^skip-locking/skip-external-locking/g" $MYCNF

sed -i "s/log-bin=mysql-bin/log-bin = \/var\/lib\/mysql\/binlog\/binlog/g" $MYCNF
sed -i "s/server-id.*=.*1/server-id = 10/g" $MYCNF

sed -i "s/\#innodb_data_home_dir = \/var\/lib\/mysql\//innodb_data_home_dir = \/var\/lib\/mysql\/data\//g" $MYCNF
sed -i "s/\#innodb_log_group_home_dir = \/var\/lib\/mysql\//innodb_log_group_home_dir = \/var\/lib\/mysql\/data\//g" $MYCNF
sed -i "s/\#innodb_log_arch_dir = \/var\/lib\/mysql\//innodb_log_arch_dir = \/var\/lib\/mysql\/data\//g" $MYCNF
sed -i "s/\#innodb_data_file_path = ibdata1:10M:autoextend/innodb_data_file_path = ibdata1:100M;ibdata2:100M:autoextend/g" $MYCNF

sed -i "s/\#innodb_/innodb_/g" $MYCNF

mkdir -p /var/lib/mysql/data
mkdir -p /var/lib/mysql/binlog
chown -R mysql:mysql /var/lib/mysql
mkdir -p /var/log/mysql
touch /var/log/mysql/error.log
touch /var/log/mysql/slow-queries.log
chown -R mysql:mysql /var/log/mysql
mysql_install_db --user=mysql

sleep 5
service mysqld stop
service mysqld start
sleep 5

mysqladmin -u root password ${MYSQL_PASSWORD}
mysql -uroot -p${MYSQL_PASSWORD} -e "drop database test;delete from mysql.user where user='';"


### Database Create
mysql -uroot -p${MYSQL_PASSWORD} -e "create database \`${CONCRETE5_DB_NAME}\` default character set utf8"

mysql -uroot -p${MYSQL_PASSWORD} -e "grant all privileges on \`${CONCRETE5_DB_NAME}\`.* to \`${CONCRETE5_DB_USER}\`@\`127.0.0.1\` identified by \"${CONCRETE5_DB_PASS}\" "
mysql -uroot -p${MYSQL_PASSWORD} -e "grant all privileges on \`${CONCRETE5_DB_NAME}\`.* to \`${CONCRETE5_DB_USER}\`@\`localhost\` identified by \"${CONCRETE5_DB_PASS}\" "
#mysql -uroot -p${MYSQL_PASSWORD} -e "grant all privileges on \`${CONCRETE5_DB_NAME}\`.* to \`${CONCRETE5_DB_USER}\`@\`%\` identified by \"${CONCRETE5_DB_PASS}\" "


### Concrete5
yum -y install unzip
curl -sS -o concrete5.zip ${CONCRETE5_DL_PATH}
unzip concrete5.zip
mv concrete5-*/* /vagrant/htdocs
chmod 777 -R /vagrant/htdocs/{application/files/,application/config/,packages/,updates/}
rm -rf concrete5*

service httpd restart

### iptables
iptables -I INPUT 5 -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
service iptables save


### End

echo "End of Install script. Enjoy Concrete5 !!"