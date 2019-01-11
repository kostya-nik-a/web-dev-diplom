#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Force Locale
echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale
locale-gen en_US.UTF-8

# Install Some PPAs
apt-get install -y software-properties-common curl

apt-add-repository ppa:nginx/development -y
apt-add-repository ppa:ondrej/php -y
]
apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 5072E1F5

curl -s https://packagecloud.io/gpg.key | apt-key add -

curl --silent --location https://deb.nodesource.com/setup_8.x | bash -


# Update Package Lists
apt-get update

# Update System Packages
apt-get -y upgrade

# Install Some Basic Packages
apt-get install -y build-essential dos2unix gcc git libmcrypt4 libpcre3-dev ntp unzip \
make python2.7-dev python-pip re2c supervisor unattended-upgrades whois vim libnotify-bin \
pv cifs-utils mcrypt bash-completion zsh ntpdate

# Set My Timezone

ln -sf /usr/share/zoneinfo/UTC /etc/localtime

apt-get install -y  \
php7.2-cli php7.2-dev \
php7.2-pgsql php7.2-sqlite3 php7.2-gd \
php7.2-curl php7.2-memcached \
php7.2-imap php7.2-mysql php7.2-mbstring \
php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
php7.2-intl php7.2-readline \
php-xdebug php-pear

apt-get install zip unzip

apt-get install php-pear php-xdebug php-apcu php-memcached

# Set Some PHP CLI Settings
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/cli/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/cli/php.ini
sudo sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/cli/php.ini
sudo sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/cli/php.ini

# Install Nginx & PHP-FPM
apt-get install -y nginx php7.2-fpm

rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default

echo "xdebug.remote_enable = 1" >> /etc/php/7.2/mods-available/xdebug.ini
echo "xdebug.remote_connect_back = 1" >> /etc/php/7.2/mods-available/xdebug.ini
echo "xdebug.remote_port = 9000" >> /etc/php/7.2/mods-available/xdebug.ini
echo "xdebug.max_nesting_level = 512" >> /etc/php/7.2/mods-available/xdebug.ini
echo "opcache.revalidate_freq = 0" >> /etc/php/7.2/mods-available/opcache.ini

# Setup Some PHP-FPM Options
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.2/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.2/fpm/php.ini
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.2/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.2/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.2/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.2/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.2/fpm/php.ini

printf "[openssl]\n" | tee -a /etc/php/7.2/fpm/php.ini
printf "openssl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | tee -a /etc/php/7.2/fpm/php.ini

printf "[curl]\n" | tee -a /etc/php/7.2/fpm/php.ini
printf "curl.cainfo = /etc/ssl/certs/ca-certificates.crt\n" | tee -a /etc/php/7.2/fpm/php.ini

# Disable XDebug On The CLI
sudo phpdismod -s cli xdebug

# Copy fastcgi_params to Nginx because they broke it on the PPA
cat > /etc/nginx/fastcgi_params << EOF
fastcgi_param	QUERY_STRING		\$query_string;
fastcgi_param	REQUEST_METHOD		\$request_method;
fastcgi_param	CONTENT_TYPE		\$content_type;
fastcgi_param	CONTENT_LENGTH		\$content_length;
fastcgi_param	SCRIPT_FILENAME		\$request_filename;
fastcgi_param	SCRIPT_NAME		\$fastcgi_script_name;
fastcgi_param	REQUEST_URI		\$request_uri;
fastcgi_param	DOCUMENT_URI		\$document_uri;
fastcgi_param	DOCUMENT_ROOT		\$document_root;
fastcgi_param	SERVER_PROTOCOL		\$server_protocol;
fastcgi_param	GATEWAY_INTERFACE	CGI/1.1;
fastcgi_param	SERVER_SOFTWARE		nginx/\$nginx_version;
fastcgi_param	REMOTE_ADDR		\$remote_addr;
fastcgi_param	REMOTE_PORT		\$remote_port;
fastcgi_param	SERVER_ADDR		\$server_addr;
fastcgi_param	SERVER_PORT		\$server_port;
fastcgi_param	SERVER_NAME		\$server_name;
fastcgi_param	HTTPS			\$https if_not_empty;
fastcgi_param	REDIRECT_STATUS		200;
EOF

ln -s /vagrant/000.conf /etc/nginx/sites-enabled/

# Set The Nginx & PHP-FPM User
sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

sed -i "s/user = www-data/user = vagrant/" /etc/php/7.2/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = vagrant/" /etc/php/7.2/fpm/pool.d/www.conf

# Add Vagrant User To WWW-Data
usermod -a -G www-data vagrant
id vagrant
groups vagrant

service php7.2-fpm restart

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Add Composer Global Bin To Path
printf "\nPATH=\"/home/vagrant/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.profile

# Install Laravel Envoy & Installer
sudo su vagrant <<'EOF'
/usr/local/bin/composer global require "laravel/envoy"
/usr/local/bin/composer global require "laravel/installer"
EOF

# Install Nodejs
apt-get install -y nodejs
/usr/bin/npm install -g npm
/usr/bin/npm install -g yarn

# Install Mysql
echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
apt-get install -y mysql-server

sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/my.cnf

mysql --user="root" --password="root" -e "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'root' WITH GRANT OPTION;"
service mysql restart


mysql --user="root" --password="root" -e "CREATE USER 'local'@'0.0.0.0' IDENTIFIED BY 'local';"
mysql --user="root" --password="root" -e "GRANT ALL ON *.* TO 'local'@'0.0.0.0' IDENTIFIED BY 'local' WITH GRANT OPTION;"
mysql --user="root" --password="root" -e "GRANT ALL ON *.* TO 'local'@'%' IDENTIFIED BY 'local' WITH GRANT OPTION;"
mysql --user="root" --password="root" -e "FLUSH PRIVILEGES;"
mysql --user="local" --password="local" -e "CREATE DATABASE local character set UTF8mb4 collate utf8mb4_bin;"

service mysql restart

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql --user=root --password=root mysql

# Clean Up
apt-get -y autoremove
apt-get -y clean
chown -R vagrant:vagrant /home/vagrant

su vagrant

# Install project enviroment
cd /vagrant/

sudo rm -f .env || true && touch .env && echo -e "
DB_HOST=localhost
DB_DATABASE=local
DB_USERNAME=local
DB_PASSWORD=local
APP_DEBUG=true
API_PREFIX=api
APP_KEY=
" >> .env

composer install

php artisan key:generate
php artisan config:cache
php artisan migrate
php artisan passport:install
php artisan package:discover
php artisan passport:keys

sudo chown www-data:www-data /vagrant/storage/logs/laravel.log 2>/dev/null

sudo service nginx restart
