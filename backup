#!/bin/bash
STARTTIME=$(date +%s)
  #command block that takes time to complete... 
  #........
if [ ! -d "$DIRECTORY" ]; then
  # if false this block of code will execute
    mkdir $DIRECTORY
    mount -t cifs  //server_ip/share /backup/ -o username=admin,rw,password=password
    rsync -arv /path_source /path_destiny
    umount /backup/
    else
  # if true this block of code will execute
    mount -t cifs  //server_ip/share /backup/ -o username=admin,rw,password=password
    rsync -arv /path_source /path_destiny
    umount /backup/
fi
ENDTIME=$(date +%s)
echo "It takes $($ENDTIME - $STARTTIME) seconds to complete this task..."
