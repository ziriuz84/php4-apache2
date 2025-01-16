#!/bin/sh
postfix start
/usr/local/apache2/bin/httpd -D FOREGROUND -f /usr/local/apache2/conf/httpd.conf -k start
