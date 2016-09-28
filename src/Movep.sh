#!/bin/bash

##############################
############ MOVEP ###########
##############################
# TODO Dice algo de numeros de secuencia... NPI que es, hay que hacerlo

#### VARS ####

COMMAND=""
TARGET="" 
SOURCE=""

#### SCRIPTS ####

sh_log="$DIRBIN/Logep.sh"

#### DIRS ####

DIRDPL="dpl"

#### Messages ####

TYPE_INF="INF"
TYPE_ERR="ERR"
MSG_INF_DUPLICATE_FILE="Se movio %SRC% a %DEST%  porque el archivo ya se encontraba en %TARGET%."
MSG_INF_FILE="Se movio %SRC% a %DEST%." 

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
    $sh_log -c "Movep" -m "Destino no existente" -t "$TYPE_ERR"
    exit 1
fi

if [[ -z "$SOURCE" ]]
then
    $sh_log -c "Movep" -m "Origen no existente" -t "$TYPE_ERR"
    exit 1
fi

if [[ "$TARGET" == "$SOURCE" ]]
then
    $sh_log -c "Movep" -m "Origen y destino identicos" -t "$TYPE_ERR"
    exit 1
fi

LOG_MSG=""
if [ -f "$TARGET/`echo "$SOURCE" | sed "s/.*\///"`" ]
then
    cd $DIRBIN >/dev/null
    mkdir $DIRDPL  # Create a dir inside bindir for storing duplicates
    cd $DIRDPL >/dev/null
    mv --backup=t $SOURCE .
   
    LOG_MSG="-m \"`echo "$MSG_INF_DUPLICATE_FILE" | sed "s/%SRC%/$SOURCE/" | sed "s/%DEST%/$PWD/" | sed "s/%TARGET%/$TARGET/"`\""
else
    mv $SOURCE $TARGET

    LOG_MSG="-m \"`echo "$MSG_INF_FILE" | sed "s/%SRC%/$SOURCE/" | sed "s/%DEST%/$TARGET/"`\""
fi

if ! [[ -z "$LOG_MSG" ]]
then
    $sh_log -c "Movep" $LOG_MSG -t "$TYPE_INF"
fi
