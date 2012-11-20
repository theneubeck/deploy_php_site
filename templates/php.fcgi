#!/bin/bash

export PHPRC="/etc/php5/vhosts.d/%{sitename}/"
export PHP_FCGI_CHILDREN=0
export PHP_FCGI_MAX_REQUESTS=500
exec /usr/bin/php-cgi
