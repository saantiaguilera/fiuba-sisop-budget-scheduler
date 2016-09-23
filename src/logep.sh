#!/bin/bash

readonly MAX_LOG_SIZE=1048576 # 1MB
readonly NO_LINES_TO_KEEP=100
COMMAND=""
MESSAGE=""
TYPE="INF"

function max_log_size_reached() {
  if [ ! -f $1 ]; then
    return 0
  fi
  local size=$(echo "`du -b $1 | cut -f1`")
  echo $size
  if [[ size -ge MAX_LOG_SIZE ]]; then
    return 1
  else
    return 0
  fi
}

function reduce_log_file() {
  local temp_file="$1_1.log"
  tail -n $NO_LINES_TO_KEEP $1 > $temp_file
  mv $temp_file $1 
}

function write_log_file() {
  # local file="$DIR_LOG/$1.log"
  local file="log/$1.log"
  max_log_size_reached $file
  if [ $? -gt 0 ]; then
    reduce_log_file $file
  fi
  echo "`date -u` `whoami` $2 $3" >> $file 
}

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


write_log_file $COMMAND $TYPE $MESSAGE
