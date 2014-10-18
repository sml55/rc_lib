if [ ! -x /usr/bin/cmus-remote ];
then
  echo "cmus is not installed."
  exit
fi

ARTIST=$( cmus-remote -Q 2>/dev/null | grep artist | cut -d " " -f 3- )
ARTIST_NN=`echo $ARTIST | tr -d '\n'`
TITLE=$( cmus-remote -Q 2>/dev/null | grep title | cut -d " " -f 3- )
TITLE_NN=`echo $TITLE | tr -d '\n'`

echo "$ARTIST_NN - $TITLE_NN"
