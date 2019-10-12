#!/bin/bash

#************************************************#
#                   music.sh                     #
#           written by Joe Courtney              #
#             updated 8/9/2018                   #
#                                                #
#  downloads, parses, imports youtube playlists  #
#************************************************#

E_WRONG=85

check_args(){
    if [ $# -eq 0 ]; then
        echo "*** No arguments supplied ***"
        usage
        exit $E_WRONG
    fi

    if [ -z "$url" ] ; then
        echo "You must supply all arguments -u {URL} -i {image/path} -a 'Artist' -A 'Album'"
        cd ..
        rm -rfP NewMusic
        exit $E_WRONG
    fi
}

rmpar(){
    if [ "$removepar" ] ; then
        cd finished
        ls *.mp3 | sed 's/.mp3//' | sed 's/.(.*)//' > titles.txt
        arr=( * )
        count=0
        IFS=$'\n'  #IMPORTANT

        for next in `cat titles.txt`; do
            arr[${count}]=${next}
            (( count++ ))
        done

        count=0
        ls *.mp3 > titles.txt
        while read -r name ; do
            id3v2 -t "${arr[$count]}" "$name"
            (( count++ ))
        done < titles.txt

        rm titles.txt
        cd ..
    fi
}

rmartist(){
    if [ "$removeartist" ] ; then
        cd finished
        ls *.mp3 | sed 's/.* -.//' | sed 's/.mp3//' > titles.txt
        arr=( * )
        count=0
        IFS=$'\n'  #IMPORTANT

        for next in `cat titles.txt`; do
            arr[${count}]=${next}
            (( count++ ))
        done

        count=0
        ls *.mp3 > titles.txt
        while read -r name ; do
            id3v2 -t "${arr[$count]}" "$name"
            (( count++ ))
        done < titles.txt

        rm titles.txt
        cd ..
    fi
}

usage(){
    cat << EOF
    Usage: music -option arg ...

    This script downloads album playlists from youtube, adds Artist, Album, and
    Artwork id3 metadata to the outfile.mp3s and exports them to iTunes library

    OPTIONS:
       -u {url}           Playlist url
                 *** optional ***
       -i {path/to/image} Album artwork path 
       -a {'artist'}      Artist
       -A {'album'}       Album Name
       -r                 Remove trailing parenthetical add-ons from track title
       -x                 Remove artist name from track title
       -h                 Show this message

    REQUIRES:
       - youtube-dl
       - ffmpeg
       - id3v2 
       - macOS
       - internet connection
EOF
}

# make and change to download directory
mkdir NewMusic
cd NewMusic

#flag Options
while getopts 'u:i:a:A:rxh' flag; do
  case "${flag}" in
    u)  url="${OPTARG}"
        get_info $url
	    art=$PWD/sddefault.jpg
	    artist=`cat artist`
	    album=`cat album` ;;
    i)  art="${OPTARG}" ;;
    a)  artist="${OPTARG}" ;;
    A)  album="${OPTARG}" ;;
    r)  removepar=1 ;;
    x)  removeatrist=1 ;;
    h)  usage
        exit 1 ;;
  esac
done

# Check for arguments
#check_args

# music download/ convert to mp3
youtube-dl -ci --extract-audio --audio-format mp3 --audio-quality 0 -o "%(title)s.%(ext)s" $url
# youtube-dl -o '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'
# how can playlist_index be used to change each downloads metadata 
# needs to be with id3v2

# get list of mp3 file names
ls -1 | grep .mp3 > mus.txt

# make new album directory for updated id3 files, add new arg to change name
mkdir finished

# loop through filenames to change album art
IFS=$'\n'
filename='mus.txt'

for next in `cat $filename`
do
  ffmpeg -i "$next" -i $art -map 0:0 -map 1:0 -c copy -y -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" "finished/$next"
done

# remove trailing parenthetical add-ons from titles
rmpar

# remove artist name from beginning of titles
rmartist

# add album and artist tags
id3v2 -a "${artist}" -A "${album}" finished/*.mp3
sleep 5s

# open mp3s to import to iTunes
for next in `cat $filename`
do
  open "finished/$next"
  sleep 2s
done
sleep 5s

# delete filenames, extra mp3s
cd ..
rm -rfP NewMusic
rm -P $art

exit 1
