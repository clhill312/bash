#! /usr/bin/python3

import datetime,os,glob

# get date in yyyy-mm-dd--hhmm-ss format
date = datetime.datetime.now()
date = date.strftime("%Y-%m-%d--%H%M-%S")

# create rsync log dirs if not exist
def mklogdir(hddpath):
    if not os.path.exists(hddpath+"/rsynclogs/"):
        print("rsynclogs directory not found, creating")
        os.mkdir(hddpath+"/rsynclogs/")
    else:
        print("rsynclogs directory found")

# log filter function
def logparse(hddpath,pname):
    logs = glob.glob(hddpath+"/rsynclogs/*"+pname+"*")
    latestlog = max(logs, key=os.path.getctime)

    llog = open(latestlog,"r")

    df = "" # deleted files
    af = "" # added files
    ad = "" # added dirs

    for fyle in llog:
        if "*deleting" in fyle:
            df += fyle
        elif ">f+++++++++" in fyle: 
            af += fyle
        elif "cd+++++++++" in fyle:
            ad += fyle

    llog.close()

    print(":::::::::::::::::::::::\n")
    print(":::"+pname+" Summary:::\n")
    print(":::::::::::::::::::::::\n")
    if df != "":
        print("Deleted Files: \n")
        print(df)
    if af != "":
        print("Added Files: \n")
        print(af)
    if ad != "":
        print("Added Directories: \n")
        print(ad)


# sync files of HDD1
hdd1path = "/mnt/usbhdd1"

if os.path.ismount(hdd1path):
    print("HDD1 is mounted, copying")

    mklogdir(hdd1path)

    excludes = "--exclude=System\ Volume\ Information --exclude=syslog --exclude=Movies --exclude=TV\ Shows"

    rsynccmd = "rsync -avzhP --delete "+excludes+" 192.168.0.1:/mnt/Storage/* "+hdd1path+" --log-file="+hdd1path+"/rsynclogs/HDD1rsynclog_"+date+".log"

    os.system(rsynccmd) # execute the rsync command

    logparse(hdd1path,"")

else:
    print("HDD1 is not mounted, skipping...")


# sync files of HDD2
hdd2path = "/mnt/usbhdd2"

if os.path.ismount(hdd2path):
    print("HDD2 is mounted, copying")

    mklogdir(hdd2path)

    rsyncmoviescmd = "rsync -avzhP 192.168.0.1:/mnt/Storage/Movies --delete "+hdd2path+" --log-file="+hdd2path+"/rsynclogs/HDD2rsynclog_Movies_"+date+".log"
    os.system(rsyncmoviescmd)
    rsynctvshowscmd = "rsync -avzhP 192.168.0.1:'/mnt/Storage/TV\ Shows' --delete "+hdd2path+" --log-file="+hdd2path+"/rsynclogs/HDD2rsynclog_TVShows_"+date+".log"
    os.system(rsynctvshowscmd)

    # movies summary
    logparse(hdd2path,"Movies")

    # TV shows summary
    logparse(hdd2path,"TVShows")

else:
    print("HDD2 is not mounted, skipping...")

