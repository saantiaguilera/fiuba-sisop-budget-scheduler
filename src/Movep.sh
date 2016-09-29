#!/bin/bash

##############################
############ MOVEP ###########
##############################
# TODO Dice algo de numeros de secuencia... NPI que es, hay que hacerlo

#### VARS ####

COMMAND=""
TARGET="" 
SOURCE=""

MY_NAME="Movep"

#### SCRIPTS ####

sh_log="$DIRBIN/Logep.sh"

#### DIRS ####

DIRDPL="dpl"

#### Messages ####

TYPE_INF="INF"
TYPE_ERR="ERR"
MSG_INF_DUPLICATE_FILE="Se movio %SRC% a %DEST% porque el archivo ya se encontraba en %TARGET%."
MSG_INF_FILE="Se movio %SRC% a %DEST%."
MSG_ERR_NO_TARGET="Destino no existente"
MSG_ERR_NO_SOURCE="Origen no existente"
MSG_ERR_SAME_PATHS="Origen y destino identicos"

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
Uso: Movep.sh -c ":caller_name" -o ":origin_path/:file_name" -d ":destiny_path"
Ejemplo: Movep.sh -c "Demonep" -o "/path/file.csv" -d "/path/NOK/"
  -h                  Muestra este mensaje de ayuda.
  -c comando          Escribir el mensaje en comando.log.
  -d destiny dir      Path al que se desea mover el archivo.
  -o origin path      Path (+ Archivo) el cual se va a mover.
EOF
}

#######################################
# Move file from one place to another with
# backup and incremental suffix
# Globals:
#   None
# Arguments:
#   SOURCE: Path + File to move
#   TARGET: Path to drop the file
# Returns:
#   None
#######################################
function mv_with_backup() {
    local SUFFIX=0
    local FILENAME=$(basename "$1")
    local EXTENSION="${FILENAME##*.}"
    FILENAME="${FILENAME%.*}"
    local FILE="$2/$FILENAME.$EXTENSION"

    while test -e "$FILE"; do
        FILE="$2/$FILENAME.$((++SUFFIX)).$EXTENSION"
    done

    mv "$1" "$FILE"
}

while getopts "h?c:d:o:" opt; do
  case "$opt" in
    h|\?)
      echo "Wrong call"
      show_help
      exit 0
      ;;
    c)
      COMMAND=$OPTARG
      ;;
    d)
      TARGET=$OPTARG
      ;;
    o)
      SOURCE=$OPTARG
      ;;
  esac
done

if [[ -z "$TARGET" ]]
then
    $sh_log -c "$MY_NAME" -m "$MSG_ERR_NO_TARGET" -t "$TYPE_ERR"
    exit 1
fi

if [[ -z "$SOURCE" ]]
then
    $sh_log -c "$MY_NAME" -m "$MSG_ERR_NO_SOURCE" -t "$TYPE_ERR"
    exit 1
fi

if [[ "$TARGET" == "$SOURCE" ]]
then
    $sh_log -c "$MY_NAME" -m "$MSG_ERR_SAME_PATHS" -t "$TYPE_ERR"
    exit 1
fi

LOG_MSG=""
if [ -f "$TARGET/`echo "$SOURCE" | sed "s/.*\///"`" ]
then
    mkdir -p "$DIRBIN/$DIRDPL" >/dev/null  # Create a dir inside bindir for storing duplicates
    mv_with_backup "$SOURCE" "$DIRBIN/$DIRDPL"

    LOG_MSG="`echo "$MSG_INF_DUPLICATE_FILE" | sed "s+%SRC%+$SOURCE+" | sed "s+%DEST%+$PWD+" | sed "s+%TARGET%+$TARGET+"`"
else
    mv $SOURCE $TARGET

    LOG_MSG="`echo "$MSG_INF_FILE" | sed "s+%SRC%+"$SOURCE"+" | sed "s+%DEST%+"$TARGET"+"`"
fi

if ! [[ -z "$LOG_MSG" ]]
then
    $sh_log -c "$MY_NAME" -m "$LOG_MSG" -t "$TYPE_INF"
fi
