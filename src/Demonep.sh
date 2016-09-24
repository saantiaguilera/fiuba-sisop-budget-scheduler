#!/bin/bash

#TODO s/COUNTRY/STATE/gc !

# Dirs
DIR_REJECTED=$DIRNOK
DIR_ACCEPTED=$DIROK
DIR_NEWS=$DIRREC
DIR_LOG=$DIRLOG
FILE_LOG="Demonep.log"

# Shell scripts
sh_mov="$BINDIR/Movep.sh"
sh_log="$BINDIR/Logep.sh"
sh_process="$BINDIR/Procep.sh"

# Sleep time
TIME_SLEEP=15

# Messages
MSG_ACCEPTED="Archivo aceptado"
MSG_FILE_DETECTED="Archivo detectado: %FILE_NAME%"
MSG_ERR_INVALID_FILE_TYPE="Archivo rechazado, motivo: no es un archivo de texto"
MSG_ERR_INVALID_FILE_SIZE="Archivo rechazado, motivo: archivo vacio"
MSG_ERR_INVALID_FILE_NAME="Archivo rechazado, motivo: formato de nombre incorrecto"
MSG_ERR_INVALID_DATE="Archivo rechazado, motivo: a;o %YEAR% incorrecto"
MSG_ERR_OUTOFBOUNDS_DATE="Archivo rechazado, motivo: fecha %DATE% incorrecta."
MSG_ERR_INVALID_COUNTRY_CODE="Archivo rechazado, motivo: provincia %STATE% incorrecta"
MSG_ERR_UNKNOWN="Archivo rechazado, motivo: Desconocido"
MSG_ERR_NOT_INITIALIZED="Procep corriendo bajo el no.: %PID%"
MSG_ERR_PID_RUNNING="Invocacion de Procep pospuesta para el siguiente ciclo"

# Evicts non text files or empty from the news dir handling the rejected ones.
function evict_malformed_files() {
	for FILE in $(ls -1 "$DIR_NEWS");do
		IS_REJECTED=0
		if [ $(file "$DIR_NEWS/$FILE" | grep -c "text") = 0 ]
			then
				#TODO ver mensajes y el primer parametro del log
		    	$sh_log "$FILE_LOG" "$MSG_ERR_INVALID_FILE_TYPE"
		    	$sh_mov "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		    	$IS_REJECTED=1
		fi

		if [ $IS_REJECTED -eq 0 ] && [ `wc -l $FILE` -eq 0 ]
			then
				$sh_log "$FILE_LOG" "$MSG_ERR_INVALID_FILE_SIZE"
				$sh_mov "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		fi
	done
}

# Saves the country codes in array CODES_COUNTRIES
function parse_country_codes() {
	# TODO ver el countrydir y codes.csv
	CODES_COUNTRIES=($(cat "$DIRMAE/codes.csv" | cut -d \; -f 1))
}

# Validates the country code passed as param is inside the country array
function validate_country_code() {
	case "${CODES_COUNTRIES[@]}" in
	    *"$1"*)
			#Code was found. Move on.	
	    ;;
	    *)
			#TODO check first param of the log
	        $sh_log "$FILE_LOG" "$MSG_ERR_INVALID_COUNTRY_CODE"
	        $sh_mov "$DIR_NEWS/$2" "$DIR_REJECTED"
	        let "EXIT_CODE = 1"
	    ;;
  	esac
}

# Validates date
function validar_fecha() {
	M_DATE=$(echo $1 | sed 's/#REGEX FOR DATE#//' | sed 's/#REGEX FOR DATE#//')
	M_YEAR=$(echo ${M_DATE} | cut -c1-4)
	M_MONTH=$(echo ${M_DATE} | cut -c5-6)
	M_DAY=$(echo ${M_DATE} | cut -c7-8)

	# TODO verify this
	if [ $M_YEAR -lt `date +'%Y'` ]; then
		$sh_log "$FILE_LOG" "$MSG_ERR_INVALID_DATE"
		$sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
		let "EXIT_CODE = 1"
		return
	else
		: # Good to go
	fi

	if [ $(date -d "$M_DATE" +"%Y%b%d" 2>/dev/null 1>/dev/null; echo $?) == 1 ];then
		$sh_log "$FILE_LOG" "$MENSAJE_FECHA_INVALIDA"
		$sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
		let "EXIT_CODE = 1"
	fi
}

#TODO Check program hasnt been initialized!!

# Initialize cycle
let "CYCLE_COUNT = 0"
while true; do
	CYCLE_NUMBER_MESSAGE="Demonep ciclo nro. $CYCLE_COUNT"
 
	# TODO ver mensaje de log
	$sh_log "$FILE_LOG" "$CYCLE_NUMBER_MESSAGE"

	let "CYCLE_COUNT = CYCLE_COUNT + 1"

	evict_malformed_files

	parse_country_codes
	FILES=$(ls $DIR_NEWS)
	for FILE in $FILES ;do
		# Exit code can be: 0-OK / 1-Error_but_not_yet_resolved / 2-Error_resolved
		let "EXIT_CODE = 0"

		$sh_log "$FILE_LOG" `echo "$MSG_FILE_DETECTED" | sed "s/\%FILE_NAME\%/$FILE/`

		#TODO forgot to validate some stuff. add it (like "a;o presupuestario!" and whole file!

		if [ $EXIT_CODE -eq "0" ]; then
	        COUNTRY_CODE=$(echo $FILE | sed 's/#Regex for getting the code#//' )
	        validate_country_code "$COUNTRY_CODE" "$FILE"
	    fi

	    if [ $EXIT_CODE -eq "0" ]; then
		    validate_date "$FILE"
		fi

		if [ $EXIT_CODE -eq "0" ]; then
			$sh_log "$FILE_LOG" "$MSG_ACCEPTED"
			$sh_mov "$DIR_NEWS/$FILE" "$DIR_ACCEPTED"
		fi
	done



	sleep "$TIME_SLEEP"
done

