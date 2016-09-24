#!/bin/bash

DIR_REJECTED=$DIRREC
DIR_ACCEPTED=$ACEPDIR
DIR_NEWS=$NOVEDIR
_mov="$BINDIR/MoverA.sh"
_log="$BINDIR/GraLog.sh"

TIME_SLEEP=15

MSG_ACCEPTED="Archivo $NOMBRE_ARCHIVO aceptado, movido a $PATH_ACEPTADO"
MSG_ERR_INVALID_FILE="Tipo de archivo invalido"
MSG_ERR_INVALID_DATE="Fecha invalida"
MSG_ERR_OUTOFBOUNDS_DATE="Fecha fuera de rango"
MSG_ERR_INVALID_COUNTRY_CODE="Central inexistente"
MSG_ERR_UNKNOWN="Error desconocido"
MSG_ERR_NOT_INITIALIZED="AFUMB corriendo bajo el no.: $PID"
MSG_ERR_PID_RUNNING="Invocacion de AFUMB pospuesta para el siguiente ciclo"
