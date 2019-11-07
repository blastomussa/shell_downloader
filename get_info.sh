#!/bin/bash

# usage function
usage(){
    cat << EOF
	This program parses info and downloads the cover art for an album from 
	the corresponding youtube playlist.

        Usage: get_info URL 
EOF
}

E_WRONG=85
# Check for null arguments
if [ $# -eq 0 ]; then
  echo "*** No arguments supplied ***"
  usage
  exit $E_WRONG 
fi

wget -O playlist "$1"

grep 'sddefault' playlist | sed -n '1p' | awk '/http/{print $NF}' | sed 's/content="//' | sed 's/">//' | sed 's/amp;//' > jpg

URL=`cat jpg`
wget -O sddefault.jpg "$URL"

grep 'name="title"' playlist | sed -n 's/.*="//p'| sed -n 's/.-.*$//p' > album

grep -i 'yt-uix-sessionlink      spf-link' playlist | sed -n '2p'| sed -n 's/.* >//p' | sed -n 's/<.*$//p'| sed 's/.-.*//' > artist

rm -P playlist
rm -P jpg

exit 1
