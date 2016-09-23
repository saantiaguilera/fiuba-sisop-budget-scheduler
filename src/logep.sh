#!/bin/bash

COMMAND=""
MESSAGE=""
TYPE=""

while getopts "h?c:m:t:" opt; do
  case "$opt" in
    h|\?)
      echo "Usage: logep.sh -c command -m 'Message' -t type of message"
      echo "Example: logep.sh -c movep -m 'File foo moved' -t INF"
      exit 0
      ;;
    c)
      echo "Command: $OPTARG"
      COMMAND=$OPTARG
      ;;
    m)
      echo "Message: $OPTARG"
      MESSAGE=$OPTARG
      ;;
    t)
      echo "Message type: $OPTARG"
      TYPE=$OPTARG
      ;;
  esac
done

FILE="$COMMAND.log"
echo "`date -u` `whoami` $TYPE $MESSAGE" >> $FILE
