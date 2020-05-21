#!/bin/bash
#find /var/www/ -type f -print0 | xargs -0 chmod 0640
#find /var/www/ -type d -print0 | xargs -0 chmod 0750
chmod -R 775 /var/www/letsencrypt 
chmod -R 755 /etc/letsencrypt 
chown -R www-data:www-data /var/www/
#chown -R www-data:www-data /var/nc_data/
chmod 0644 /var/www/nextcloud/.htaccess
chmod 0644 /var/www/nextcloud/.user.ini
chmod 600 /etc/letsencrypt/rsa-certs/fullchain.pem
chmod 600 /etc/letsencrypt/rsa-certs/privkey.pem
chmod 600 /etc/letsencrypt/rsa-certs/chain.pem
chmod 600 /etc/letsencrypt/rsa-certs/cert.pem
chmod 600 /etc/letsencrypt/ecc-certs/fullchain.pem
chmod 600 /etc/letsencrypt/ecc-certs/privkey.pem
chmod 600 /etc/letsencrypt/ecc-certs/chain.pem
chmod 600 /etc/letsencrypt/ecc-certs/cert.pem
chmod 600 /etc/ssl/certs/dhparam.pem
exit 0
