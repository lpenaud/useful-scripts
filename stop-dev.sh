#!/bin/bash

echo "Stopping nginx..."
sudo service nginx start

echo "Stopping mariadb..."
sudo service mysql start

echo "Stopping php-fpm..."
sudo service php7.0-fpm start

echo "Tasks finished with success !"

