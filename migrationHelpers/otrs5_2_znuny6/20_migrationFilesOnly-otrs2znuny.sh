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

CONF_FILE_REL=/Kernel/Config.pm

# validate input and  & return 1 if failed
if [[ ! -d "$ZNUNY_PREPARE_DIR" ]]; then
   echo "missing parameter folder Znuny preparation."
   echo "this folder is the target folder, where this script prepares a new znuny installation"
   echo "e.g. use /tmp to create the new znuny folder, so your command would be:"
   echo "$0 /tmp <znunyTagetDir>"
   exit 1
fi

############################################################

echo "cleanup any prior /tmp/otrs folder"
rm -rf $ZNUNY_PREPARE_DIR/otrs

mkdir -p $ZNUNY_PREPARE_DIR
cd $ZNUNY_PREPARE_DIR

wget https://download.znuny.org/releases/znuny-latest-6.0.tar.gz
tar zxf znuny-latest-6.0.tar.gz
find . -maxdepth 1 -type d -name znuny-6* -exec mv {} ./otrs \;
echo "prepared clean installation"

cd $ZNUNY_PREPARE_DIR/otrs
find $ZNUNY_PREPARE_DIR -type f -name \*znuny-conf-backup.tar.gz -exec tar zxf {} \;
echo "updated installation with your backup files from `find $ZNUNY_PREPARE_DIR -type f -name \*znuny-conf-backup.tar.gz`"

echo "your new installation folder is located under /tmp/otrs"
