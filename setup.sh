#!/usr/bin/env bash

echo "Removing existing nginx installation if any..."
sudo yum -y remove nginx

echo "Removing existing PHP packages if any..."
sudo yum -y remove php*

echo "Adding REMI, EPEL and Webtatic repositories..."
sudo yum install epel-release
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
sudo rpm -Uvh https://mirror.webtatic.com/yum/el6/latest.rpm
sudo rpm -Uvh http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm

echo "Install PHP 7 packages from webtatic rmp repo..."
sudo yum -y install php70w

echo "Install required PHP 7 modules..."
sudo yum -y install php70w-mysql php70w-xml php70w-soap php70w-xmlrpc php70w-pecl-imagick
sudo yum -y install php70w-mbstring php70w-json php70w-gd php70w-mcrypt

echo "Installing nginx..."
sudo yum -y install nginx

echo "Installing PHP-FPM..."
sudo yum -y install php70w-fpm

echo "Skipping imagick version check..."
sudo cp imagick.ini /etc/php.d/imagick.ini

echo "Installing composer..."
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/bin/composer

echo "Replacing /etc/php-fpm.d/www.conf file..."
sudo cp www.conf /etc/php-fpm.d/www.conf
sudo chown root:root /etc/php-fpm.d/www.conf
sudo chmod 0644 /etc/php-fpm.d/www.conf

echo "Replacing /etc/nginx/nginx.conf file..."
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo chown root:root /etc/nginx/nginx.conf
sudo chmod 0644 /etc/nginx/nginx.conf

echo "Replacing /etc/nginx/conf.d/default.conf file..."
sudo cp default.conf /etc/nginx/conf.d/default.conf
sudo chown root:root /etc/nginx/conf.d/default.conf
sudo chmod 0644 /etc/nginx/conf.d/default.conf

echo "Replacing /etc/nginx/conf.d/proxy.conf file..."
sudo cp proxy.conf /etc/nginx/conf.d/proxy.conf
sudo chown root:root /etc/nginx/conf.d/proxy.conf
sudo chmod 0644 /etc/nginx/conf.d/proxy.conf

if [[ -f /etc/nginx/conf.d/virtual.conf ]]; then
    echo "Removing /etc/nginx/conf.d/virtual.conf file..."
    sudo rm /etc/nginx/conf.d/virtual.conf
fi

if [[ ! -d /var/nginx/proxy_temp ]]; then
    echo "Creating directory /var/nginx/proxy_temp..."
    sudo mkdir -p /var/nginx/proxy_temp
    sudo chown nginx:root /var/nginx/proxy_temp
fi

if [[ ! -d /var/nginx/client_body_temp ]]; then
    echo "Creating directory /var/nginx/client_body_temp..."
    sudo mkdir -p /var/nginx/client_body_temp
    sudo chown nginx:root /var/nginx/client_body_temp
fi

echo "Emptying server root directory /var/www ..."
sudo rm -rf /var/www/*

echo "Creating www-data group..."
sudo groupadd www-data

echo "Creating user www-data belonging to group www-data..."
sudo useradd -g www-data www-data

echo "Adding test file..."
sudo mkdir /var/www/web
sudo cp app.php /var/www/web
sudo chown -R www-data:www-data /var/www/

echo "Add nginx user to www-data group..."
sudo usermod -a -G www-data nginx

echo "Make sure nginx user owns /var/run/php-fpm directory...."
sudo chown -R nginx:nginx /var/run/php-fpm

echo "Starting nginx...."
sudo /etc/init.d/nginx start
sudo /etc/init.d/nginx reload
sudo service nginx status

echo "Starting PHP-FPM..."
sudo /etc/init.d/php-fpm start
sudo /etc/init.d/php-fpm reload
sudo service php-fpm status

echo "Make sure nginx always start on server reload..."
sudo chkconfig nginx on

echo "Make sure php-fpm always start on server reload..."
sudo chkconfig php-fpm on