#! /bin/bash

# NAS hostname/IP address
nashost="nas"

# check if $nashost is reachable
if ping -c 3 $nashost; then
    echo "$nashost is reachable"
else
    echo "$nashost is not reachable"
    exit 1
fi

# check ssh key for $nashost
authkeys=$(ssh root@$nashost cat /root/.ssh/authorized_keys | grep $HOSTNAME)

if [ ! -z "$authkeys" ]; then
    echo "passwordless access configured"
else
    echo "passwordless acces NOT configured"
    exit 2
fi

# get date in yyyy-mm-dd--hhmm-ss format
date=$(date +"%Y-%m-%d--%H%M-%S")

# create rsync log dir function
mklogdir () {
    if [ -d "$hddmountpath/rsynclogs/" ]; then
        echo "rsynclogs directory found"
    else
        echo "rsynclogs directory not found, creating"
        mkdir "$hddmountpath/rsynclogs/"
    fi
}

# log summary function
logsum () {
    rsynclog=$(ls -t $hddmountpath/rsynclogs/*$date* | head -n1) # sort by time modified, select first

    deletedfiles=$(grep deleting $rsynclog)

    addedfiles=$(grep ">f+++++++++" $rsynclog)

    echo ":::DELETED FILES:::"
    echo "$deletedfiles"

    echo ":::ADDED FILES:::"
    echo "$addedfiles"
}


# backup HDD paths
# by UUID
hdd1="58DE8D54DE8D2AF8"
hdd1mountpath=$(lsblk -o UUID,MOUNTPOINT | grep $hdd1 | awk '{print $2}')

hdd2="A0C2411DC240F8D4"
hdd2mountpath=$(lsblk -o UUID,MOUNTPOINT | grep $hdd2 | awk '{print $2}')



# check if HDDs are mounted
if [ ! -z $hdd1mountpath ]; then
    echo "$hdd1 is mounted; copying"
    hddmountpath=$hdd1mountpath
    mklogdir

    rsync --archive --human-readable --progress --delete --exclude={Movies,TV\ Shows,rsynclogs} "$nashost:/netstor/" "$hdd1mountpath/" --log-file="$hddmountpath/rsynclogs/$date.log" 

    logsum

else
    echo "$hdd1 is not mounted; skipping..."
fi

if [ ! -z $hdd2mountpath ]; then
    echo "$hdd2 is mounted; copying"
    hddmountpath=$hdd2mountpath
    mklogdir

    rsync --archive --human-readable --progress --delete "$nashost:/netstor/Movies" $hddmountpath --log-file="$hddmountpath/rsynclogs/Movies_$date.log"
    rsync --archive --human-readable --progress --delete $nashost:'/netstor/TV\ Shows' $hddmountpath --log-file="$hddmountpath/rsynclogs/TVShows_$date.log"

    logsum

else
    echo "$hdd2 is not mounted; skipping..."

fi
