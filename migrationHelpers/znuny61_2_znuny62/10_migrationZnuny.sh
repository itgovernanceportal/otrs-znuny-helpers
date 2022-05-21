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
#set -xv

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


VER_ZNUNY_OLD_MAJOR=6
VER_ZNUNY_OLD_MINOR=1
VER_ZNUNY_MAJOR=6
VER_ZNUNY_MINOR=2


OLD_VERSION=`grep -r "$VER_ZNUNY_OLD_MAJOR\.$VER_ZNUNY_OLD_MINOR\." /opt/otrs/RELEASE|awk -P '{print $3}'`
echo $OLD_VERSION


# needed packages for znuny 6.2
apt update
apt install -y libspreadsheet-xlsx-perl


# Download latest Znuny 6.2
cd /opt
wget https://download.znuny.org/releases/znuny-latest-$VER_ZNUNY_MAJOR.$VER_ZNUNY_MINOR.tar.gz || exit 1

# Extract
tar xfz znuny-latest-$VER_ZNUNY_MAJOR.$VER_ZNUNY_MINOR.tar.gz || exit 1

# cd into extracted dir
cd `tar ztf znuny-latest-$VER_ZNUNY_MAJOR.$VER_ZNUNY_MINOR.tar.gz |grep "znuny-$VER_ZNUNY_MAJOR\.$VER_ZNUNY_MINOR\../$"` || exit 1
pwd

# Set permissions
./bin/otrs.SetPermissions.pl || exit 1

# Restore Kernel/Config.pm, articles, etc.
cp -av /opt/otrs/Kernel/Config.pm ./Kernel/ || exit 1

# copy articles if existing
article_count=$(find /opt/otrs/var/article/ -maxdepth 1 -name '*.zip' | wc -l)
if [ $count -gt 0 ] ; then
   mv /opt/otrs/var/article/* ./var/article/ || exit 1
fi

# Restore dotfiles from the homedir to the new directory
for f in $(find /opt/otrs -maxdepth 1 -type f -name .\* -not -name \*.dist); do cp -av "$f" ./; done

# Restore modified and custom cron job
for f in $(find /opt/otrs/var/cron -maxdepth 1 -type f -name .\* -not -name \*.dist); do cp -av "$f" ./var/cron/; done


echo "move current otrs to backup folder"
mv /opt/otrs /opt/otrs-obsolete-$CURR_DATE


CURR_DIR=`pwd`
echo $CURR_DIR

# Create a symlink
ln -s $CURR_DIR /opt/otrs

cd /opt/otrs

# Check for missing modules and add required modules
./bin/otrs.CheckModules.pl --all



echo "starting DB migration"
sudo -u otrs ./scripts/MigrateToZnuny6_2.pl || exit 1


echo "clean caches"
sudo -u otrs ./bin/otrs.Console.pl Maint::Cache::Delete
sudo -u otrs ./bin/otrs.Console.pl Maint::Session::DeleteAll



echo "upgrading installed packages"
sudo -u otrs ./bin/otrs.Console.pl Admin::Package::UpgradeAll


