#!/bin/bash

# Copyright (c) 2021, Laendle-Web and/or its affiliates.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License, version 2.0,
#  as published by the Free Software Foundation.
#
#  This program is also distributed with certain software that is 
#  licensed under separate terms, as designated in a particular file 
#  or component or in included license documentation.  The authors 
#  of otrs-znuny-helper hereby grant you an additional permission to 
#  link the program and your derivative works with the separately 
#  licensed software that they have included with otrs-znuny-helper.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License, version 2.0, for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the 
#  Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, 
#  Boston, MA 02110-1301, USA

# debug
set -xv

ZNUNY_PREPARE_DIR=$1
OTRS_INSTALL_DIR=$2


CONF_FILE_REL=/Kernel/Config.pm

# validate input and  & return 1 if failed
if [[ ! -d "$ZNUNY_PREPARE_DIR" ]]; then
   echo "missing parameter folder Znuny preparation folder. e.g. use $0 /tmp <znunyTagetDir>"
   exit 1
fi


CONF_FILE=$OTRS_INSTALL_DIR/$CONF_FILE_REL
if [[ ! -n "$OTRS_INSTALL_DIR" ]]; then
   echo "missing parameter folder of OTRS/Znuny. e.g. $0 <prepareDir> /opt/otrs"
   exit 1
fi

############################################################

CURR_DATE=$(date '+%Y-%m-%d-%H-%M-%S')
#echo $CURR_DATE

echo "move current otrs to backup folder"
mv /opt/otrs /opt/otrs-obsolete-$CURR_DATE

echo "move prepared package to final location"
mv /tmp/otrs /opt/otrs

cd /opt/otrs
./bin/otrs.SetPermissions.pl || exit 1

echo "installing typically missing packages on OTRS 5 installations"
sudo apt install -y libcss-minifier-xs-perl libjavascript-minifier-xs-perl

MISSING_DPKG_CHECK=$(sudo -u otrs /opt/otrs/bin/otrs.CheckModules.pl --all|grep "Not installed" | grep -v "DBD::Oracle")
if [ -n "$MISSING_DPKG_CHECK" ]; then
   echo "echo packages are not installed"
   exit 1;
fi
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Database::Check || exit 1

echo "prepare config files"
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Dev::Tools::Migrate::ConfigXMLStructure --source-directory Kernel/Config/Files

echo "starting DB migration"
sudo -u otrs ./scripts/DBUpdate-to-6.pl

sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Cache::Delete
sudo -u otrs /opt/otrs/bin/otrs.Console.pl Maint::Session::DeleteAll


echo "upgrading installed packages"
sudo -u otrs ./bin/otrs.Console.pl Admin::Package::UpgradeAll

echo "preparing apache"
a2enmod perl
# a2enmod deflate
a2enmod filter
a2enmod headers
ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/sites-available/zzz_otrs.conf
a2ensite zzz_otrs.conf


exit 1
echo installing missing packages


mkdir -p $ZNUNY_PREPARE_DIR
cd $ZNUNY_PREPARE_DIR

wget https://download.znuny.org/releases/znuny-latest-6.0.tar.gz
tar zxf znuny-latest-6.0.tar.gz
find . -maxdepth 1 -type d -name znuny-6* -exec mv {} ./otrs \;

cd $ZNUNY_PREPARE_DIR/otrs
find $ZNUNY_PREPARE_DIR -type f -name \*znuny-conf-backup.tar.gz -exec tar zxf {} \;

# validate if config file is at required location, fail if not
if test -f "$CONF_FILE"; then
   echo "$CONF_FILE exists going on..."
else
   echo "this seems not to be a valid OTRS/Znuny installation. Did not find $CONF_FILE"
   exit 1
fi

