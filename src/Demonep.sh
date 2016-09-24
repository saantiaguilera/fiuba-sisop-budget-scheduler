#!/bin/bash

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
MSG_ACCEPTED="Archivo $NOMBRE_ARCHIVO aceptado, movido a $PATH_ACEPTADO"
MSG_FILE_DETECTED="Archivo detectado: "
MSG_ERR_INVALID_FILE_TYPE="Archivo rechazado, motivo: no es un archivo de texto"
MSG_ERR_INVALID_FILE_SIZE="Archivo rechazado, motivo: archivo vacio"
MSG_ERR_INVALID_DATE="Fecha invalida"
MSG_ERR_OUTOFBOUNDS_DATE="Fecha fuera de rango"
MSG_ERR_INVALID_COUNTRY_CODE="Codigo de provincia inexistente"
MSG_ERR_UNKNOWN="Error desconocido"
MSG_ERR_NOT_INITIALIZED="Proceso corriendo bajo el no.: $PID"
MSG_ERR_PID_RUNNING="Invocacion de #### pospuesta para el siguiente ciclo"

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
		let "EXIT_CODE = 0"

		$sh_log "$FILE_LOG" "$MSG_FILE_DETECTED $FILE"

		#TODO forgot to validate "a;o presupuestario!"

		if [ $EXIT_CODE -eq "0" ]; then
	        COUNTRY_CODE=$(echo $file | sed 's/#Regex for getting the code#//' )
	        validate_country_code "$COUNTRY_CODE" "$FILE"
	    fi

	    if [ $EXIT_CODE -eq "0" ]; then
		    validate_date "$FILE"
		fi
	done

	hay_archivos $NOVEDADES
	if [ $cantidad_archivos -eq 0 ];then
	    # echo $(ls -1 "$ACEPTADOS")
	    hay_archivos $ACEPTADOS
	    if [ $cantidad_archivos -gt 0 ];then
	      # echo "Voy a arrancar AFUMB"
	      if [[ $(ps -aux | grep -e "[0-9] [a-z]* AFREC" ) == "" ]];then
	        	# echo "No se esta ejecutando asi que lo arranco"
	        	bash $BINDIR/Arrancar.sh ./AFUMB
	        	PID_AFUMB=$(pgrep AFUMB)
	    	    $GRALOG "AFREC" "AFUMB corriendo bajo el no.: $PID_AFUMB" "INFO"
		    else
	        	# echo "Se esta ejecutando asi que lo pospongo"
	        	$GRALOG "AFREC" "$MENSAJE_AFUMB_OCUPADO" "WAR"
	        fi
	    fi
	fi


	sleep "$TIME_SLEEP"
done

