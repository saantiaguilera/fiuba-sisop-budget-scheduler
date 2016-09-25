#!/bin/bash

readonly MAX_LOG_SIZE=1048576 # 1MB
readonly NO_LINES_TO_KEEP=100
COMMAND=""
MESSAGE=""
TYPE="INF"

#######################################
# Shows help function.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function show_help() {
  cat << EOF
Uso: logep.sh -c comando -m 'Mensaje' -t tipo de mensaje
Ejemplo: logep.sh -c movep -m 'Se movio archivo foo' -t INF 
  -h                  Muestra este mensaje de ayuda.
  -c comando          Escribir el mensaje en comando.log.
  -m 'Mensaje'        Mensaje a escribir.
  -t tipo de mensaje  Especifica el tipo de mensaje. Puede ser
                      INF (tipo default), WAR, ERR. (Parametro opcional)
EOF
}

#######################################
# Check if log file reached the maximum size allowed.
# Globals:
#   MAX_LOG_SIZE
# Arguments:
#   file
# Returns:
#   1 if max size reached, 0 if don't.
#######################################
function max_log_size_reached() {
  if [ ! -f $1 ]; then
    return 0
  fi
  local size=$(echo "`du -b $1 | cut -f1`")
  if [[ size -ge MAX_LOG_SIZE ]]; then
    return 1
  else
    return 0
  fi
}

#######################################
# Keep last n lines to reduce size of log file
# Globals:
#   NO_LINES_TO_KEEP
# Arguments:
#   file
# Returns:
#   None
#######################################
function reduce_log_file() {
  local temp_file="$1_1.log"
  tail -n $NO_LINES_TO_KEEP $1 > $temp_file
  mv $temp_file $1 
}

#######################################
# Write log file
# Globals:
#   None
# Arguments:
#   command type_of_message message
# Returns:
#   None
#######################################
function write_log_file() {
  # local file="$DIR_LOG/$1.log"
  #local file="log/$1.log"
  local file="$1.log"
  if [ ! -f $file ]; then
    touch $file
  fi
  max_log_size_reached $file
  if [ $? -gt 0 ]; then
    reduce_log_file $file
  fi
  echo "`date -u` `whoami` $2 $3" >> $file 
}

while getopts "h?c:m:t:" opt; do
  case "$opt" in
    h|\?)
      show_help
      exit 0
      ;;
    c)
      COMMAND=$OPTARG
      ;;
    m)
      MESSAGE=$OPTARG
      ;;
    t)
      TYPE=$OPTARG
      ;;
  esac
done

if [[ -z $COMMAND || -z $MESSAGE ]]; then
  show_help
  exit 0
fi

write_log_file $COMMAND $TYPE $MESSAGE
