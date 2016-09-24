#!/bin/bash

#TODO s/COUNTRY/STATE/gc !
#TODO CHECK THE sh_mov dirs 

# Dirs
DIR_REJECTED=$DIRNOK
DIR_ACCEPTED=$DIROK
DIR_NEWS=$DIRREC
DIR_LOG=$DIRLOG
DIR_ASSETS=$DIRMAE
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
MSG_ERR_INVALID_BUDGET_YEAR="Archivo rechazado, motivo: a;o %YEAR% incorrecto"
MSG_ERR_OUTOFBOUNDS_DATE="Archivo rechazado, motivo: fecha %DATE% incorrecta."
MSG_ERR_INVALID_COUNTRY_CODE="Archivo rechazado, motivo: provincia %STATE% incorrecta"
MSG_ERR_UNKNOWN="Archivo rechazado, motivo: Desconocido"
MSG_ERR_PROCESS_RUNNING="Procep corriendo bajo el no.: %PID%"
MSG_ERR_PROCESS_POSTPONED="Invocacion de Procep pospuesta para el siguiente ciclo"

# Function

# Get files count in a dir passed as param. 
# @Returns in $FILES_SIZE
function get_files_count() {
	FILES_SIZE=$(ls -1 $1 | wc -l)
}

# Evicts non text files or empty from the news dir handling the rejected ones.
# Will remove file from directory if malformed
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
# @Return $CODE_COUNTRIES with non zero array
function parse_country_codes() {
	# TODO ver el countrydir y codes.csv
	CODES_COUNTRIES=($(cat "$DIR_ASSETS/codes.csv" | cut -d \; -f 1))
}

# If no error yet, print the generic error. Else skip.
# Returns EXIT_CODE with 1 if was printed. Else retains previous value
function print_generic_error_if_needed() {
	if [ $EXIT_CODE -eq "0" ]
		then
			$sh_log "$FILE_LOG" "$MSG_ERR_INVALID_FILE_NAME"
			let "EXIT_CODE = 1"
	fi
}

# Validates the default format matches (the ejecutado_ and .csv)
# Wont remove file from directory if malformed.
# @Return EXIT_CODE with state output
function validate_file_name() {
	FILE_NAME=`echo "$1" | sed "s/.*\///"`

	# Check if filename at least matches the start and end the name should have
	if ! [[ `echo $FILE_NAME | sed "s/^ejecutado_*\.csv$//"` == "" ]]
		then
			print_generic_error_if_needed
	fi
}

function validate_budget_year() {
	FILE_NAME=`echo "$1" | sed "s/.*\///"`
	CURRENT_YEAR=`date +%Y`
	FILE_BUDGET_YEAR=`echo "$FILE_NAME" | sed "s/^ejecutado_//" | sed "s/_*//"`

	# Check if the budget year is this one
	if ! [ $FILE_BUDGET_YEAR -eq $CURRENT_YEAR ]
		then
			print_generic_error_if_needed
	        $sh_log "$FILE_LOG" `echo $MSG_ERR_INVALID_BUDGET_YEAR | sed "s/%YEAR%/$FILE_BUDGET_YEAR/"`
	        $sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
	        let "EXIT_CODE = 2"
	fi
}

# Validates the country code passed as param is inside the country array
# Might remove file from directory if code malformed. 
# @Return EXIT_CODE with state output
function validate_country_code() {
	COUNTRY_CODE=$(echo $1 | sed "s/^ejecutado_...._//" | sed "s/_*//" )

	# Check if code exists in the countries code
	case "${CODES_COUNTRIES[@]}" in
	    "$COUNTRY_CODE")
			#Code was found. Move on.	
	    ;;
	    *)
			print_generic_error_if_needed
	        $sh_log "$FILE_LOG" `echo $MSG_ERR_INVALID_COUNTRY_CODE | sed "s/%STATE%/$COUNTRY_CODE"`
	        $sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
	        let "EXIT_CODE = 2"
	    ;;
  	esac
}

# Validates date
# Might remove file from dir if date malformed. 
# @Return EXIT_CODE with state output
function validate_date() {
	M_DATE=$(echo $1 | sed 's/^ejecutado_.._//' | sed 's/_*//')
	M_YEAR=$(echo ${M_DATE} | cut -c1-4)
	M_MONTH=$(echo ${M_DATE} | cut -c5-6)
	M_DAY=$(echo ${M_DATE} | cut -c7-8)
	CURRENT_YEAR=`date +%Y`

	# Check it wasnt in past years
	if [ $M_YEAR -lt $CURRENT_YEAR ]; then
		print_generic_error_if_needed
		$sh_log "$FILE_LOG" `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"`
		$sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
		let "EXIT_CODE = 2"
		return
	fi

	# Check if it was this year
	if [ $M_YEAR -e $CURRENT_YEAR ]
		then
			# Check it wasnt in this month but in a future day
			if [ M_MONTH -e `date +%m` ] && [ M_DAY -gt `date +%d` ]
				then
					#its in this month but some days in the future
					print_generic_error_if_needed
					$sh_log "$FILE_LOG" `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"`
					$sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
					let "EXIT_CODE = 2"
					return
			fi

			# Check it wasnt in a future month
			if [ M_MONTH -gt `date +%m` ]
				then
					print_generic_error_if_needed
					$sh_log "$FILE_LOG" `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"`
					$sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
					let "EXIT_CODE = 2"
					return
			fi
	fi

	# Check date is not malformed
	if [ $(date -d "$M_DATE" +"%Y%m%d" 2>/dev/null 1>/dev/null; echo $?) == 1 ]
		then
			print_generic_error_if_needed
			$sh_log "$FILE_LOG" `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"`
			$sh_mov "$DIR_NEWS/$1" "$DIR_REJECTED"
			let "EXIT_CODE = 2"
	fi
}

#TODO Check program hasnt been initialized!!

# Initialize cycle
let "CYCLE_COUNT = 0"
while true; do
	CYCLE_NUMBER_MESSAGE="Demonep ciclo nro. $CYCLE_COUNT"
 
	$sh_log "$FILE_LOG" "$CYCLE_NUMBER_MESSAGE"

	let "CYCLE_COUNT = CYCLE_COUNT + 1"

	evict_malformed_files

	parse_country_codes
	FILES=$(ls $DIR_NEWS)
	for FILE in $FILES ;do
		# Exit code can be: 0-OK / 1-Error_but_not_yet_resolved / 2-Error_resolved
		let "EXIT_CODE = 0"

		$sh_log "$FILE_LOG" `echo "$MSG_FILE_DETECTED" | sed "s/%FILE_NAME%/$FILE/"`

		if [ $EXIT_CODE -eq "0" ]; then
			validate_file_name "$FILE"
		fi

		if [ $EXIT_CODE -le "1" ]; then
			validate_budget_year "$FILE"
		fi

		if [ $EXIT_CODE -lt "1" ]; then
	        validate_country_code "$FILE"
	    fi

	    if [ $EXIT_CODE -lt "1" ]; then
		    validate_date "$FILE"
		fi

		if [ $EXIT_CODE -eq "1" ]; then
			$sh_log "$FILE_LOG" "$MSG_ERR_UNKNOWN"
			$sh_mov "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		fi

		if [ $EXIT_CODE -eq "0" ]; then
			$sh_log "$FILE_LOG" "$MSG_ACCEPTED"
			$sh_mov "$DIR_NEWS/$FILE" "$DIR_ACCEPTED"
		fi
	done

	get_files_count $DIR_ACCEPTED
	if [ $FILES_SIZE -gt 0 ]
		then
			if [[ $(ps -aux | grep -e "[0-9] [a-z]* Procep.sh" ) == "" ]]
				then
					$sh_process
					PID_PROCESS=$(pgrep Procep*)
					$sh_log "$FILE_LOG" `echo $MSG_ERR_PROCESS_RUNNING | sed "s/%PID%/$PID_PROCESS/"`
				else
					$sh_log "$FILE_LOG" "$MSG_ERR_PROCESS_POSTPONED"
			fi
	fi

	sleep "$TIME_SLEEP"
done

