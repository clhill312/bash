#!/bin/bash
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

musicdir='/run/user/1000/gvfs/smb-share:server=freenas.local,share=storage/Music'

flacfiles=$(find $musicdir -name *.flac)

i=0

for file in $flacfiles
do

    let "i++"
    echo "Working on $file
Number $i"

    outputfile="${file/flac/mp3}"

    ffmpeg -i $file -ab 320k -map_metadata 0 -id3v2_version 3 $outputfile

    echo "Created $outputfile"
  
done


# restore $IFS
IFS=$SAVEIFS
