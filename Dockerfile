FROM debian:jessie
MAINTAINER piotr.figlarek@gmail.com

# environment for osticket
ENV OSTICKET_VERSION 1.10.4

# requirements
RUN apt-get update \
 && apt-get -y install wget unzip cron supervisor apache2 libapache2-mod-php5 php5-cli php5-fpm php5-imap php5-gd php5-mysql php5-intl php5-apcu

# Let's set the default timezone in both cli and apache configs
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Warsaw/g' /etc/php5/cli/php.ini
RUN sed -i 's/\;date\.timezone\ \=/date\.timezone\ \=\ Europe\/Warsaw/g' /etc/php5/apache2/php.ini

# Download & install OSTicket
RUN wget https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip -O /tmp/osTicket.zip
RUN unzip /tmp/osTicket.zip -d /tmp/osTicket
RUN rm /var/www/html/index.html
RUN cp -rv /tmp/osTicket/upload/* /var/www/html/
RUN chown -R www-data:www-data /var/www/html/

# Cleanup
RUN rm -r /tmp/osTicket.zip
RUN rm -rf /tmp/osTicket

# Initialize config file
RUN mv /var/www/html/include/ost-sampleconfig.php /var/www/html/include/ost-config.php

# cron is used to fetch incoming emails
COPY crontab /etc/cron.d/osticket-poll
RUN chmod 0644 /etc/cron.d/osticket-poll

# supervisor to monitor both Apache and cron
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
