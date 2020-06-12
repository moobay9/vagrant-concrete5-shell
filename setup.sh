#!/bin/sh
# Copyright Funaffect, Inc. (M.Oobayashi)

### Parameter

CONCRETE5_DL_PATH="https://www.concrete5.org/download_file/-/view/113632/"

CONCRETE5_DB_NAME=concrete5
CONCRETE5_DB_USER=c5_user
CONCRETE5_DB_PASS=c5_password
CONCRETE5_DB_HOST=localhost

MYSQL_PASSWORD=mysqlpassword

# HTTPCNF=/etc/httpd/conf/httpd.conf
# MYCNF=/etc/my.cnf
PHPINI=/etc/php.ini

### 共通設定
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

firewall-cmd --add-service=https --zone=public --permanent
firewall-cmd --add-service=http --zone=public --permanent
firewall-cmd --reload


### Timezone
\cp /usr/share/zoneinfo/Japan /etc/localtime

### Concrete5
sudo mkdir /vagrant/htdocs
curl -sS -o concrete5.zip ${CONCRETE5_DL_PATH}
unzip concrete5.zip
mv concrete5-*/* /vagrant/htdocs
chmod 777 -R /vagrant/htdocs/{application/files/,application/config/,packages/,updates/}
rm -rf concrete5*

# ### rpm
wget -q http://rpms.famillecollet.com/enterprise/remi-release-8.rpm
rpm -ivh remi-release-8.rpm

### PHP Install
dnf -y module reset php
dnf -y module install php:remi-7.4
dnf -y install php-devel php-devel php-gd php-pear php-bcmath php-mysqlnd php-pdo php-pecl-zip

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

systemctl enable php-fpm
systemctl start php-fpm


### NGINX
dnf install -y nginx 

sed -i '38,57 s/^/#/g' /etc/nginx/nginx.conf
cat << \_EOFCP_ > /etc/nginx/conf.d/concreate5.conf

server {
    include /etc/nginx/default.d/*.conf;

    listen       80 default_server;
    listen       [::]:80 default_server;
    server_name  tconcrete5.vagrant.localhost;
    include      /etc/nginx/default.d/*.conf;

    root /vagrant/htdocs;

    index index.html index.htm index.php;

    sendfile off;
    client_max_body_size 100m;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php-fpm/www.sock;
        fastcgi_index index.php;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;

        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
}
_EOFCP_

systemctl start nginx
systemctl enable nginx


### MySQL Install
yum -y install mariadb mariadb-server mariadb-devel
systemctl start mariadb.service
systemctl status mariadb.service

# rm -rf /var/lib/mysql
# rm -f /etc/my.cnf
# cp -p /usr/share/doc/mysql-server-5.1.*/my-medium.cnf $MYCNF

sed -i "s/\[client\]/[client]\ndefault-character-set = utf8/g" /etc/my.cnf.d/client.cnf


mysqladmin -u root password ${MYSQL_PASSWORD}


### Database Create
mysql -uroot -p${MYSQL_PASSWORD} -e "create database \`${CONCRETE5_DB_NAME}\` default character set utf8"

mysql -uroot -p${MYSQL_PASSWORD} -e "grant all privileges on \`${CONCRETE5_DB_NAME}\`.* to \`${CONCRETE5_DB_USER}\`@\`127.0.0.1\` identified by \"${CONCRETE5_DB_PASS}\" "
mysql -uroot -p${MYSQL_PASSWORD} -e "grant all privileges on \`${CONCRETE5_DB_NAME}\`.* to \`${CONCRETE5_DB_USER}\`@\`localhost\` identified by \"${CONCRETE5_DB_PASS}\" "
#mysql -uroot -p${MYSQL_PASSWORD} -e "grant all privileges on \`${CONCRETE5_DB_NAME}\`.* to \`${CONCRETE5_DB_USER}\`@\`%\` identified by \"${CONCRETE5_DB_PASS}\" "

### End

# echo "End of Install script. Enjoy Concrete5 !!"
