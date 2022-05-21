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

OTRS_INSTALL_DIR=$1
BACKUP_TARGET_DIR=$2

CONF_FILE_REL=/Kernel/Config.pm

#validate input and  & return 1 if failed, 0 if succeed
CONF_FILE=$OTRS_INSTALL_DIR/$CONF_FILE_REL
if [[ ! -d "$OTRS_INSTALL_DIR" ]]; then
   echo "missing parameter folder of your current OTRS."
   echo "this is the folder there your current OTRS installation is residing"
   echo "typically it is /opt/otrs"
   echo "$0 /opt/otrs"
   exit 1
fi

# validate if config file is at required location, fail if not
if test -f "$CONF_FILE"; then
   echo "$CONF_FILE exists going on..."
else
   echo "this seems not to be a valid OTRS/Znuny installation. Did not find $CONF_FILE"
   exit 1
fi

# ask for backup location
if [ ! -n "$BACKUP_TARGET_DIR" ]; then
   read -p "where shall I copy your configurations as tar.gz for migration? Enter e.g. /tmp : " BACKUP_TARGET_DIR
   echo "Using $BACKUP_TARGET_DIR"
   if [[ ! -d "$BACKUP_TARGET_DIR" ]]; then
      echo "could not find your entered folder $BACKUP_TARGET_DIR"
      exit 1
   fi
else
   echo "using target backup directory $BACKUP_TARGET_DIR"
fi

############################################################

# backup the config files
CURR_DIR=$(pwd)
cd `dirname $CONF_FILE`

# prepare files for the backup
CONF_BAK=/tmp/$(mktemp -d znuny-migration.XXXXXXX)
mkdir -p $CONF_BAK/Kernel/Config/Files/XML
cp -ra ./Config.pm $CONF_BAK/Kernel
cp -ra ./Config $CONF_BAK/Kernel/

# cleanup developer maintained config files
cd $CONF_BAK/Kernel
rm ./Config/Files/CloudServices.xml
rm ./Config/Files/Daemon.xml
rm ./Config/Files/Framework.xml
rm ./Config/Files/GenericInterface.xml
rm ./Config/Files/ProcessManagement.xml
rm ./Config/Files/Ticket.xml
rm ./Config/Defaults.pm

# cleanup internediate files, which get generated after migration from new version
rm ./Config/Files/ZZZACL.pm
rm ./Config/Files/ZZZAAuto.pm
rm ./Config/Files/ZZZProcessManagement.pm

# copy now the /var files which contain stats and file storages
cd $OTRS_INSTALL_DIR 
cp -ra var $CONF_BAK/

# Restore dotfiles from the homedir to the new directory
echo "copy dot files '.*'"
for f in $(find . -maxdepth 1 -type f -name \.\* -not -name \*.dist); do cp -av "$f" "$CONF_BAK/"; done
echo "copy dot folders '.*'"
for f in $(find . -maxdepth 1 -type d -name \.\* -not -name \*.dist|grep -v "^.$"); do cp -arv "$f" "$CONF_BAK/"; done

# cleanup developer maintained var files
cd $CONF_BAK/var
rm -rf cron/*.dist
rm -rf fonts
rm -rf httpd
rm -rf processes/examples
rm -rf tmp
rm -rf webservices/examples
rm logo-otrs.png


CURR_DATE=$(date '+%Y-%m-%d-%H-%M-%S')
#echo $CURR_DATE

cd $CONF_BAK
tar zcf $BACKUP_TARGET_DIR/$CURR_DATE-znuny-conf-backup.tar.gz ./

echo created backup file $BACKUP_TARGET_DIR/$CURR_DATE-znuny-conf-backup.tar.gz

# cleanup
rm -rf $CONF_BAK
