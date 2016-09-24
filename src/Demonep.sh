#!/bin/bash

# Dirs
DIR_REJECTED=$DIRREC
DIR_ACCEPTED=$ACEPDIR
DIR_NEWS=$NOVEDIR

# Shell scripts
sh_mov="$BINDIR/MoverA.sh"
sh_log="$BINDIR/GraLog.sh"

# Sleep time
TIME_SLEEP=15

# Messages
MSG_ACCEPTED="Archivo $NOMBRE_ARCHIVO aceptado, movido a $PATH_ACEPTADO"
MSG_ERR_INVALID_FILE="Tipo de archivo invalido"
MSG_ERR_INVALID_DATE="Fecha invalida"
MSG_ERR_OUTOFBOUNDS_DATE="Fecha fuera de rango"
MSG_ERR_INVALID_COUNTRY_CODE="Codigo de provincia inexistente"
MSG_ERR_UNKNOWN="Error desconocido"
MSG_ERR_NOT_INITIALIZED="Proceso corriendo bajo el no.: $PID"
MSG_ERR_PID_RUNNING="Invocacion de #### pospuesta para el siguiente ciclo"

# Returns number of files in the dir passed as param inside FILES_SIZE
# @Return FILES_SIZE
function get_files_size() {
  FILES_SIZE=$(ls -1 $1 | wc -l)
}

# Evicts non text files from the news dir handling the rejected ones.
function evict_malformed_files() {
	for FILE in $(ls -1 "$DIR_NEWS");do
		if [ $(file "$DIR_NEWS/$FILE" | grep -c "text") = 0 ]
			then
				#TODO ver mensajes y el primer parametro del log
		    	$sh_log "#####" "$MSG_ERR_INVALID_FILE" "INFO"
		    	$sh_mov "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		fi
	done
}

# Saves the country codes in array CODES_COUNTRIES
function parse_country_codes() {
	# TODO ver el countrydir y codes.csv
	CODES_COUNTRIES=($(cat "$COUNTRY_DIR/codes.csv" | cut -d \; -f 1))
}

# Initialize cycle
let "CYCLE_COUNT = 0"
while true; do
	CYCLE_NUMBER_MESSAGE="Daemonep ciclo nro. $CYCLE_COUNT"
 
	# TODO ver mensaje de log
	$sh_log "####" "$CYCLE_NUMBER_MESSAGE" "INFO"

	let "CYCLE_COUNT = CYCLE_COUNT + 1"

	get_files_size $DIR_NEWS
	if [ $FILES_SIZE -gt 0 ]
 		then
	 		evict_malformed_files

	    	parse_country_codes
			FILES=$(ls $DIR_NEWS)
  	fi

	sleep "$TIME_SLEEP"
done

