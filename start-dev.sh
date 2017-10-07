#!/bin/bash

echo "Starting nginx..."
sudo service nginx start

echo "Starting mariadb..."
sudo service mysql start

echo "Starting php-fpm..."
sudo service php7.0-fpm start

echo "Tasks finished with success !"

