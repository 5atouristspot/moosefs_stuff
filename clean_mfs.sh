#!/usr/bin/env bash

apt-get remove --purge moosefs-master -y
apt-get remove --purge moosefs-cli -y



rm -rf /etc/mfs
rm -rf /var/lib/mfs


#apt-get remove --purge moosefs-cgiserv -y
#rm -rf  /etc/default/moosefs-cgiserv
#rm -rf /etc/mfs
#rm -rf /var/lib/mfs

#apt-get remove --purge moosefs-metalogger -y
#rm -rf  /etc/default/moosefs-metalogger
#rm -rf /etc/mfs
#rm -rf /var/lib/mfs


#apt-get remove --purge moosefs-chunkserver -y
#rm -rf  /etc/default/moosefs-chunkserver
#rm -rf /etc/mfs
#rm -rf /var/lib/mfs
#rm -rf /mnt/mfschunk


apt-get remove --purge moosefs-client -y
rm -rf /etc/mfs/mfsmount.cfg.sample /etc/mfs/mfsmount.cfg