moosefs install tool
==

Useage:
--
**master** 
```
mkdir /mfs_stuff && cd /mfs_stuff
./install_mfs.sh --master_host [master_ip] --master
```
**cgiserv**
```
mkdir /mfs_stuff && cd /mfs_stuff
./install_mfs.sh --master_host [master_ip] --cgiserv
```
**logger** 
```
mkdir /mfs_stuff && cd /mfs_stuff
./install_mfs.sh --master_host [master_ip] --logger
```
**chunk** 
```
mkdir /mfs_stuff && cd /mfs_stuff
./install_mfs.sh --master_host [master_ip] --chunk
```
**client**
```
mkdir /mfs_stuff && cd /mfs_stuff
./install_mfs.sh --master_host [master_ip] --client
```

**warning**
if not /etc/iptables.rules on mechine,please excute ..
```
echo "*filter" >> /etc/iptables.rules
echo "COMMIT" >> /etc/iptables.rules
```
