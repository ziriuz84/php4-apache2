FROM alpine:3.22.2 AS build
RUN apk add --no-cache build-base ncurses-dev zlib-dev wget flex perl imap-dev postfix mailx busybox-extras libcurl curl-dev curl libjpeg-turbo-dev libjpeg libpng libpng-dev libxml2-dev libxml2 zlib freetype freetype-dev libxpm libxpm-dev imap imap-dev apache-mod-auth-kerb


WORKDIR /tmp

# Build Apache 2.2
ADD httpd-2.2.34.tar.bz2 .
WORKDIR /tmp/httpd-2.2.34 
RUN ./configure \
  --prefix=/usr/local/apache2 \
  --enable-mods-shared=all \
  --enable-deflate \
  --enable-proxy \
  --enable-proxy-balancer \
  --enable-proxy-http \
  --with-imap \
  && make \
  && make install

WORKDIR /tmp
# Build PHP 4
ADD php-4.4.9.tar.bz2 .
COPY php.ini /usr/local/apache2/php.ini
WORKDIR /tmp/php-4.4.9 
RUN ./configure \ 
  --with-apxs2=/usr/local/apache2/bin/apxs \
  --enable-bcmath \
  --enable-calendar \
  --enable-ftp \
  --enable-gd-native-ttf \
  --enable-libxml \
  --enable-magic-quotes \
  --enable-sockets \
  # --prefix=/usr/php4 \
  --with-freetype-dir=/usr \
  --with-iconv \
  --with-imap=/opt/php_with_imap_client/ \
  --with-imap-ssl=/usr \
  --with-libdir=lib64 \
  --with-libxml-dir=/opt/xml2/ \
  --with-mysql \
  --with-mysql-sock=/var/lib/mysql/mysql.sock \
  --with-pic \
  --with-ttf \
  --with-xpm-dir=/usr \
  --with-zlib \
  --with-zlib-dir=/usr \
  # --with-kerberos \
  --with-gd \
  --enable-cli \
  --with-config-file-path=/usr/local/apache2 \
  && make && make install && make install-cli

# Setup PHP to Run on Apache
RUN echo 'AddType application/x-httpd-php php' >> /usr/local/apache2/conf/httpd.conf \
  && sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' /usr/local/apache2/conf/httpd.conf


# Linuxtrheads hack explained: https://bugs.mysql.com/bug.php?id=19785
# gnu++98 (error: narrowing conversion):  https://bugs.mysql.com/bug.php?id=19785

FROM alpine:3.22.2
# FROM mariadb:5.5.62

RUN apk add --no-cache libstdc++ imap-dev tzdata postfix bash ncurses-dev gcompat openssl-dev ncurses-libs openssl certbot certbot-apache
RUN apk add --no-cache build-base ncurses-dev zlib-dev wget flex perl imap-dev postfix mailx busybox-extras libcurl curl-dev curl libjpeg-turbo-dev libjpeg libpng libpng-dev libxml2-dev libxml2 zlib freetype freetype-dev libxpm libxpm-dev imap imap-dev apache-mod-auth-kerb
# RUN apt-get update && apt-get install -y libstdc++ imap-dev tzdata postfix bash \
#   && mkdir -p /run/postfix \
# && newaliases

# # Build Mysql 4
# RUN apk add --no-cache build-base ncurses-dev zlib-dev wget flex perl imap-dev postfix mailx busybox-extras cmake jemalloc-dev boost-dev
# WORKDIR /tmp
# ADD mariadb-5.5.68.tar.bz2 .
# RUN echo '/* Linuxthreads */' >> /usr/include/pthread.h \ 
#   && ls -a -l \
#   && mv mariadb-5.5.40 /usr/local/mysql 
# RUN ls -a -l
# RUN mv mariadb-5.5.68-linux-x86_64 /usr/local/mysql 

# Setup Mysql to Run
COPY my.cnf /usr/local/mysql/my.cnf
# RUN addgroup -S mysql && adduser -S mysql -G mysql \
#   && mkdir /usr/local/mysql/var \
#   && chown -R root /usr/local/mysql && chown -R mysql /usr/local/mysql/var && chgrp -R mysql /usr/local/mysql

COPY --from=build /usr/local/apache2 /usr/local/apache2
COPY --from=build /usr/local/bin/php /usr/local/bin/php
COPY --from=build /usr/local/lib/php/build /usr/local/lib/php/build
COPY --from=build /usr/local/include/php /usr/local/include/php
COPY --from=build /usr/local/bin/phpize /usr/local/bin/phpize
COPY --from=build /usr/local/bin/php-config /usr/local/bin/php-config
COPY --from=build /tmp/php-4.4.9 /tmp/php-4.4.9 
RUN ln -s /usr/local/apache2/bin/apachectl /usr/local/apache2/bin/apache2ctl
COPY main.cf /etc/postfix/main.cf
COPY my.cnf /etc/my.cnf
COPY startapp.sh /bin/start_app.sh
RUN chmod +x /bin/start_app.sh

RUN mkdir -p /var/spool/postfix /var/spool/postfix/pid /run/postfix && \
  chmod 755 /var/spool/postfix && \
  chmod 755 /var/spool/postfix/pid && \
  chmod 755 /run/postfix

# RUN /usr/local/mysql/bin/mysqld --initialize --user=mysql
# RUN /usr/local/mysql/bin/mysqld_safe --user=mysql

# ENV PATH="${PATH}:/usr/local/apache2/bin/:/usr/local/mysql/bin/"
ENV PATH="${PATH}:/usr/local/apache2/bin/"
# VOLUME /usr/local/mysql/var /usr/local/apache2/htdocs/ /usr/local/apache2/conf /usr/local/apache2/logs
VOLUME /usr/local/apache2/htdocs/ /usr/local/apache2/conf /usr/local/apache2/logs
# WORKDIR /usr/local/mysql
# RUN chown -R mysql . \
#   && chgrp -R mysql . \
#   && ./scripts/mysql_install_db --user=mysql \
#   && chown mysql -R /usr/local/mysql/var/ \
#   && mysqld_safe --user=mysql --defaults-file=/usr/local/mysql/my.cnf

# Configurazione server ftp
# CMD [ "rc-update", "add", "vsftpd", "default" ]
# CMD [ "rc-service", "vsftpd", "start" ]

# Lancio lo script di partenza
CMD ["/bin/start_app.sh"]
