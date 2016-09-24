#!/bin/bash

# Dirs
DIR_REJECTED=$DIRREC
DIR_ACCEPTED=$ACEPDIR
DIR_NEWS=$NOVEDIR

# Shell scripts
SH_MOV="$BINDIR/MoverA.sh"
SH_LOG="$BINDIR/GraLog.sh"

# Sleep time
TIME_SLEEP=15

# Messages
MSG_ACCEPTED="Archivo $NOMBRE_ARCHIVO aceptado, movido a $PATH_ACEPTADO"
MSG_ERR_INVALID_FILE="Tipo de archivo invalido"
MSG_ERR_INVALID_DATE="Fecha invalida"
MSG_ERR_OUTOFBOUNDS_DATE="Fecha fuera de rango"
MSG_ERR_INVALID_COUNTRY_CODE="Codigo de provincia inexistente"
MSG_ERR_UNKNOWN="Error desconocido"
MSG_ERR_NOT_INITIALIZED="#### corriendo bajo el no.: $PID"
MSG_ERR_PID_RUNNING="Invocacion de #### pospuesta para el siguiente ciclo"

# Initialize cycle
let "CYCLE_COUNT = 0"
while true; do
  CYCLE_NUMBER_MESSAGE="#### ciclo nro. $CYCLE_COUNT"
 
  $SH_LOG "AFREC" "$CYCLE_NUMBER_MESSAGE" "INFO"

  let "CYCLE_COUNT = CYCLE_COUNT + 1"

sleep "$TIME_SLEEP"
done

