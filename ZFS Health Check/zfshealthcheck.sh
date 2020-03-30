#! /bin/sh

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# condition.htm and healthstatus.htm files are generated here
htmllocation='/var/www/html/zfshealthcheck'


# set problems counter to 0
problems=0


# check if all ZFS volumes are in good condition
condition=$(/sbin/zpool status | egrep -i '(DEGRADED|FAULTED|OFFLINE|UNAVAIL|REMOVED|FAIL|DESTROYED|corrupt|cannot|unrecover)')
if [ "${condition}" ]; then
        healthstatus="`hostname` - ZFS pool - HEALTH fault"
        problems=1
else
  healthstatus="`hostname` - ZFS pool - HEALTHY"
fi


# ensure pool capacity is 85% or less
maxCapacity=85

if [ ${problems} -eq 0 ]; then
   capacity=$(/sbin/zpool list -H -o capacity | cut -d'%' -f1)
   for line in ${capacity}
     do
       if [ $line -ge $maxCapacity ]; then
         healthstatus="`hostname` - ZFS pool - Capacity Exceeded"
         problems=1
       fi
     done
fi


# Errors - Check the columns for READ, WRITE and CKSUM (checksum) drive errors
if [ ${problems} -eq 0 ]; then
   errors=$(/sbin/zpool status | grep ONLINE | grep -v state | awk '{print $3 $4 $5}' | grep -v 000)
   if [ "${errors}" ]; then
        healthstatus="`hostname` - ZFS pool - Drive Errors"
        problems=1
   fi
fi


# Scrub Expired - Check if all volumes have been scrubbed in at least the last 8 days
scrubExpire=691200

currentDate=$(date +%s)
zfsVolumes=$(/sbin/zpool list -H -o name)

for volume in ${zfsVolumes}
do
if [ $(/sbin/zpool status $volume | egrep -c "none requested") -ge 1 ]; then
    printf "ERROR: You need to run \"zpool scrub $volume\" before this script can monitor the scrub expiration time."
    break
fi
if [ $(/sbin/zpool status $volume | egrep -c "scrub in progress|resilver") -ge 1 ]; then
    break
fi

### CentOS date format
scrubRawDate=$(/sbin/zpool status $volume | grep scrub | awk '{print $13" "$14" " $15" " $16" "$17}')
scrubDate=$(date -d "$scrubRawDate" +%s)


if [ $(($currentDate - $scrubDate)) -ge $scrubExpire ]; then
  scrubstatus="Scrub Needed on Volume(s). Scrub last ran on $scrubRawDate"
  scrubExpired=1
fi
done



# generate final status

if [ "$problems" -ne 0 ]; then
  echo -e "${RED} $healthstatus"
  # generate healthstatus.htm
  echo '' > "$htmllocation/healthstatus.htm"
  echo '<html>' >> "$htmllocation/healthstatus.htm"
  echo '<body bgcolor="#FF0000">' >> "$htmllocation/healthstatus.htm"
  echo '<H1>' >> "$htmllocation/healthstatus.htm"
  echo "$healthstatus" >> "$htmllocation/healthstatus.htm"
  echo '</H1>' >> "$htmllocation/healthstatus.htm"
  echo '</body>' >> "$htmllocation/healthstatus.htm"
  echo '</html>' >> "$htmllocation/healthstatus.htm"

  
  echo -e "${RED} $condition"
  # generate condition.htm
  echo '' > "$htmllocation/condition.htm"
  echo '<html>' >> "$htmllocation/condition.htm"
  echo '<body bgcolor="#FF0000">' >> "$htmllocation/condition.htm"
  echo '<H1>' >> "$htmllocation/condition.htm"
  echo "$condition" >> "$htmllocation/condition.htm"
  echo '</H1>' >> "$htmllocation/condition.htm"
  echo '</body>' >> "$htmllocation/condition.htm"
  echo '</html>' >> "$htmllocation/condition.htm"

  logger $healthstatus

else
  echo -e "${NC} ZFS pools are healthy"

  # generate healthstatus.htm
  echo '' > "$htmllocation/healthstatus.htm"
  echo '<html>' >> "$htmllocation/healthstatus.htm"
  echo '<body bgcolor="#00D01E">' >> "$htmllocation/healthstatus.htm"
  echo '<H1>' >> "$htmllocation/healthstatus.htm"
  echo "$healthstatus" >> "$htmllocation/healthstatus.htm"
  echo '</H1>' >> "$htmllocation/healthstatus.htm"
  echo '</body>' >> "$htmllocation/healthstatus.htm"
  echo '</html>' >> "$htmllocation/healthstatus.htm"

  # generate condition.htm
  echo '' > "$htmllocation/condition.htm"
  echo '<html>' >> "$htmllocation/condition.htm"
  echo '<body bgcolor="#00D01E">' >> "$htmllocation/condition.htm"
  echo '</body>' >> "$htmllocation/condition.htm"
  echo '</html>' >> "$htmllocation/condition.htm"

fi

if [ $(($scrubExpired)) -ne 0 ]; then
  echo -e "${YELLOW} $scrubstatus"
fi

echo -e "${NC}"