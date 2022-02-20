#!/bin/bash

sudo service cron start
sudo -u otrs /opt/otrs/bin/Cron.sh start
sudo -u otrs /opt/otrs/bin/otrs.Daemon.pl start
sudo service apache2 start
sudo service postfix start

