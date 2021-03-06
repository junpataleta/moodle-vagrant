#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "Running operating system updates..."
apt-get update
apt-get -y upgrade
echo "Installing required packages..."
apt-get -y install lamp-server^
apt-get -y install postgresql \
    postgresql-contrib \
    php-pgsql \
    php-intl \
    php-curl \
    php-xmlrpc \
    php-soap \
    php-gd \
    php-json \
    php-cli \
    php-pear \
    php-xsl \
    php-zip \
    php-mbstring \
    php-ldap \
    php-dev \
    build-essential \
    git \
    python \
    python-pip \
    libmysqlclient-dev \
    libpq-dev \
    python-dev \
    phpmyadmin \
    phppgadmin \
    ruby-dev \
    libsqlite3-dev \
    unixodbc-dev
echo "Configuring Apache..."
machinename=$1
cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    # The ServerName directive sets the request scheme, hostname and port that
    # the server uses to identify itself. This is used when creating
    # redirection URLs. In the context of virtual hosts, the ServerName
    # specifies what hostname must appear in the request's Host: header to
    # match this virtual host. For the default virtual host (this file) this
    # value is not decisive as it is used as a last resort host regardless.
    # However, you must set it for any further virtual host explicitly.
    ServerName ${machinename}

    ServerAdmin webmaster@localhost
    DocumentRoot /home/vagrant/www
    <Directory /home/vagrant/www/>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
    # error, crit, alert, emerg.
    # It is also possible to configure the loglevel for particular
    # modules, e.g.
    #LogLevel info ssl:warn

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    # For most configuration files from conf-available/, which are
    # enabled or disabled at a global level, it is possible to
    # include a line for only one particular virtual host. For example the
    # following line enables the CGI configuration for this host only
    # after it has been globally disabled with "a2disconf".
    #Include conf-available/serve-cgi-bin.conf
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

echo "Setting password for PostgreSQL's postgres user..."
sudo -u postgres psql postgres <<EOF
\password
moodle
moodle
\quit
EOF
service postgresql restart

echo "Extracting your current PHP version."
# Determine the PHP version.
PHPVER=$(php -v | cut -d' ' -f 2)
# Extract the major version.
MAJORVER=$(echo $PHPVER | cut -d'.' -f 1 -s)
# Extract the minor version.
MINORVER=$(echo $PHPVER | cut -d'.' -f 2 -s)
PHPVER="$MAJORVER.$MINORVER"
echo "You're on PHP $PHPVER!"

echo "Set up SQL Server"
pecl install sqlsrv pdo_sqlsrv
echo "extension=pdo_sqlsrv.so" > /etc/php/$PHPVER/mods-available/pdo_sqlsrv.ini
echo "extension=sqlsrv.so" > /etc/php/$PHPVER/mods-available/sqlsrv.ini

echo "Installing MailCatcher..."
gem install mailcatcher

echo "Installing Docker Community Edition..."
apt-get update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get -y install docker-ce
echo "Testing Docker CE installation..."
docker run --name hello hello-world
docker stop hello
docker rm hello
echo "Adding user vagrant to the docker users group"
usermod -aG docker vagrant

echo "Moodle-SDK (MDK) installation..."
cd ~
if [ -f "get-pip.py" ]
then
    echo "get-pip.py already downloaded..."
else
    echo "Downloading get-pip.py..."
    wget https://bootstrap.pypa.io/get-pip.py
fi
python get-pip.py
echo "Installing MDK..."
pip install moodle-sdk
pip install psycopg2-binary
echo "Restarting Apache..."
service apache2 restart

cat <<EOF
Server installed...
EOF
