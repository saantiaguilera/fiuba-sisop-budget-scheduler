#!/bin/bash

while getopts "hc:m:t:" opt; do
  case "$opt" in
    h)
      echo "Help"
      exit 0
      ;;
    c)
      echo "Command: $OPTARG"
      ;;
    m)
      echo "Message: $OPTARG"
      ;;
    t)
      echo "Message type: $OPTARG"
      ;;
  esac
done


