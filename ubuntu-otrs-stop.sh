#!/bin/bash

sudo service cron stop
sudo -u otrs /opt/otrs/bin/Cron.sh stop
sudo -u otrs /opt/otrs/bin/otrs.Daemon.pl stop
sudo service apache2 stop
sudo service postfix stop

