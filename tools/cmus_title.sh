if [ ! -x /usr/bin/cmus-remote ];
then
  echo "cmus is not installed."
  exit
fi

ARTIST=$( cmus-remote -Q 2>/dev/null | grep artist | cut -d " " -f 3- )
TITLE=$( cmus-remote -Q 2>/dev/null | grep title | cut -d " " -f 3- )

if [ -z "$TITLE" ];
then
  echo "Nothing"
else
  echo "$ARTIST - $TITLE"
fi
