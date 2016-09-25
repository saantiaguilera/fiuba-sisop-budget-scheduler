#!/bin/bash

####################################################
################       DAEMON       ################
####################################################
# NOTES;
# - Daemon task made by: Santiago Aguilera
# - Please always ensure the daemon is run in a background job. For this append at the end of the shell command a '&' eg "echo "test" &"
# - Must be runned in an environment which has previously run Initep (To ensure we can reach the environment variables set by it in their exports).

#### Dirs ####
DIR_REJECTED=$DIRNOK
DIR_ACCEPTED=$DIROK
DIR_NEWS=$DIRREC
DIR_ASSETS=$DIRMAE

#### Shell scripts ####
sh_mov="$DIRBIN/Movep.sh"
sh_log="$DIRBIN/logep.sh"
sh_process="$DIRBIN/Procep.sh"

#### Sleep time ####
TIME_SLEEP=15

#### Messages ####
TYPE_ERROR="ERR"
TYPE_INFO="INF"
MSG_INFO_ACCEPTED="Archivo aceptado"
MSG_INFO_FILE_DETECTED="Archivo detectado: %FILE_NAME%"
MSG_ERR_INVALID_FILE_TYPE="Archivo rechazado, motivo: no es un archivo de texto"
MSG_ERR_INVALID_FILE_SIZE="Archivo rechazado, motivo: archivo vacio"
MSG_ERR_INVALID_FILE_NAME="Archivo rechazado, motivo: formato de nombre incorrecto"
MSG_ERR_INVALID_BUDGET_YEAR="Archivo rechazado, motivo: a;o %YEAR% incorrecto"
MSG_ERR_OUTOFBOUNDS_DATE="Archivo rechazado, motivo: fecha %DATE% incorrecta."
MSG_ERR_INVALID_STATE_CODE="Archivo rechazado, motivo: provincia %STATE% incorrecta"
MSG_ERR_UNKNOWN="Archivo rechazado, motivo: Desconocido"
MSG_INFO_PROCESS_RUNNING="Procep corriendo bajo el no.: %PID%"
MSG_INFO_PROCESS_POSTPONED="Invocacion de Procep pospuesta para el siguiente ciclo"
MSG_ERR_INSTANCE_RUNNING="El entorno no se encuentra en ejecucion. Para correr el daemon es necesario tener un entorno de Initep activo"

#### Functions ####

#######################################
# Get files count in a dir passed as param. 
# Globals:
#   FILES_SIZE
# Arguments:
#   1. Directory to inspect
# Returns:
#   FILES_SIZE with size of files inside param directory
#######################################
function get_files_count() {
	FILES_SIZE=$(ls -1 $1 | wc -l)
}

#######################################
# Log and move according to the params
# Arguments:
#   1. Log message
#   2. Log type
#   3. Move target
#   4. Move dest
#######################################
function log_n_move() {
	$sh_log -c "Demonep" -m $1 -t $2
	$sh_mov -c "Demonep" -o $3 -d $4
}

#######################################
# Evicts non text files or empty from the news dir handling the rejected ones.
# Will remove file from directory if malformed
#######################################
function evict_malformed_files() {
	for FILE in $(ls -1 "$DIR_NEWS");do
		local IS_REJECTED=0
		local MIME_TYPE=($(file "$DIR_NEWS/$FILE" | cut -d' ' -f2))
		if [ `echo "$MIME_TYPE" | grep '(^ASCII)' >/dev/null` ]
			then
				log_n_move "$MSG_ERR_INVALID_FILE_TYPE" "$TYPE_ERROR" "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		    	$IS_REJECTED=1
		fi

		if [ $IS_REJECTED -eq 0 ] && [ "`wc -l "$DIR_NEWS/$FILE"`" == 0 ]
			then
				log_n_move "$MSG_ERR_INVALID_FILE_SIZE" "$TYPE_ERROR" "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		fi
	done
}

#######################################
# Saves the state codes in array CODES_STATES
# Globals:
#   CODES_STATES
# Returns:
#   CODES_STATES with non-zero array
#######################################
function parse_state_codes() {
	CODES_STATES=($(cat "$DIR_ASSETS/provincias.csv" | cut -d \; -f 1))
}

#######################################
# If no error yet, print the generic error. Else skip.
# Globals:
#   EXIT_CODE
# Returns:
#   Exit code if logged, else retains previous value
#######################################
function print_generic_error_if_needed() {
	if [ $EXIT_CODE -eq "0" ]
		then
			$sh_log -c "Demonep" -m "$MSG_ERR_INVALID_FILE_NAME" -t "$TYPE_ERROR"
			let "EXIT_CODE = 1"
	fi
}

#######################################
# Validates the default format matches (the ejecutado_ and .csv)
# Wont remove file from directory if malformed.
# Globals:
#   EXIT_CODE
# Arguments:
#   1. File name to validate
# Returns:
#   Exit code with state
#######################################
function validate_file_name() {
	local FILE_NAME=`echo "$1" | sed "s/.*\///"`

	# Check if filename at least matches the start and end the name should have
	if ! [[ `echo $FILE_NAME | sed "s/^ejecutado_*\.csv$//"` == "" ]]
		then
			print_generic_error_if_needed
	fi
}

#######################################
# Validates the budget year is the current one
# Will remove file from directory if malformed.
# Globals:
#   EXIT_CODE
# Arguments:
#   1. File name to validate
# Returns:
#   Exit code with state
#######################################
function validate_budget_year() {
	local FILE_NAME=`echo "$1" | sed "s/.*\///"`
	local CURRENT_YEAR=`date +%Y`
	local FILE_BUDGET_YEAR=`echo "$FILE_NAME" | sed "s/^ejecutado_//" | sed "s/_.+//"`

	# Check if the budget year is this one
	if ! [ $FILE_BUDGET_YEAR -eq $CURRENT_YEAR ]
		then
			print_generic_error_if_needed
			log_n_move `echo $MSG_ERR_INVALID_BUDGET_YEAR | sed "s/%YEAR%/$FILE_BUDGET_YEAR/"` "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
	    	let "EXIT_CODE = 2"
	fi
}

#######################################
# Validates the state code passed as param is inside the state array
# Might remove file from directory if code malformed. 
# Globals:
#   EXIT_CODE
# Arguments:
#   1. File name to validate
# Returns:
#   Exit code with state
#######################################
function validate_state_code() {
	local STATE_CODE=$(echo $1 | sed "s/^ejecutado_...._//" | sed "s/_*//" )

	# Check if code exists in the states code
	case "${CODES_STATES[@]}" in
		"$STATE_CODE")
			#Code was found. Move on.	
		;;
		*)
			print_generic_error_if_needed
			log_n_move `echo $MSG_ERR_INVALID_STATE_CODE | sed "s/%STATE%/$STATE_CODE"` "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
			let "EXIT_CODE = 2"
		;;
	esac
}

#######################################
# Validates date
# Might remove file from dir if date malformed. 
# Globals:
#   EXIT_CODE
# Arguments:
#   1. File name to validate
# Returns:
#   Exit code with state
#######################################
function validate_date() {
	local M_DATE=$(echo $1 | sed 's/^ejecutado_.._//' | sed 's/_*//')
	local M_YEAR=$(echo ${M_DATE} | cut -c1-4)
	local M_MONTH=$(echo ${M_DATE} | cut -c5-6)
	local M_DAY=$(echo ${M_DATE} | cut -c7-8)
	local CURRENT_YEAR=`date +%Y`

	# Check it wasnt in past years
	if [ $M_YEAR -lt $CURRENT_YEAR ]; then
		print_generic_error_if_needed
		log_n_move `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"` "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
		let "EXIT_CODE = 2"
		return
	fi

	# Check if it was this year
	if [ $M_YEAR -e $CURRENT_YEAR ]
		then
			# Check it wasnt in this month but in a future day
			if [ $M_MONTH -e `date +%m` ] && [ $M_DAY -gt `date +%d` ]
				then
					#its in this month but some days in the future
					print_generic_error_if_needed
					log_n_move `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"` "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
					let "EXIT_CODE = 2"
					return
			fi

			# Check it wasnt in a future month
			if [ $M_MONTH -gt `date +%m` ]
				then
					print_generic_error_if_needed
					log_n_move `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"` "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
					let "EXIT_CODE = 2"
					return
			fi
	fi

	# Check date is not malformed
	if [ $(date -d "$M_DATE" +"%Y%m%d" 2>/dev/null 1>/dev/null; echo $?) == 1 ]
		then
			print_generic_error_if_needed
			log_n_move `echo $MSG_ERR_OUTOFBOUNDS_DATE | sed "s/%DATE%/$M_DATE/"` "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
			let "EXIT_CODE = 2"
	fi
}

#### Main ####

# Check init is running
if [ -z "$DIRMAE" ] # Or any other environment variable. Just randomed it from the ones I need.
	then
		$sh_log -c "Demonep" -m "$MSG_ERR_INSTANCE_RUNNING" -t "$TYPE_ERROR"
		exit 1;
fi

# Initialize cycle
let "CYCLE_COUNT = 0"

# Im gonna live 4evah
while true; do
	CYCLE_NUMBER_MESSAGE="Demonep ciclo nro. $CYCLE_COUNT"
 
	$sh_log -c "Demonep" -m "$CYCLE_NUMBER_MESSAGE" -t "$TYPE_INFO"

	let "CYCLE_COUNT = CYCLE_COUNT + 1"

	evict_malformed_files

	parse_state_codes
	FILES=$(ls $DIR_NEWS)
	for FILE in $FILES ;do
		# Exit code can be: 0-OK / 1-Error_found_but_dunno_which / 2-Error_sought_n_destroyed
		let "EXIT_CODE = 0"

		$sh_log -c "Demonep" -m "`echo "$MSG_INFO_FILE_DETECTED" | sed "s/%FILE_NAME%/$FILE/"`" -t "$TYPE_INFO"

		#Derp this conditional
		if [ $EXIT_CODE -eq "0" ]; then
			validate_file_name "$FILE"
		fi

		if [ $EXIT_CODE -le "1" ]; then
			validate_budget_year "$FILE"
		fi

		if [ $EXIT_CODE -le "1" ]; then
	        validate_state_code "$FILE"
		fi

		if [ $EXIT_CODE -le "1" ]; then
		    validate_date "$FILE"
		fi

		if [ $EXIT_CODE -eq "1" ]; then
			log_n_move "$MSG_ERR_UNKNOWN" "$TYPE_ERROR" "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		fi

		if [ $EXIT_CODE -eq "0" ]; then
			log_n_move "$MSG_INFO_ACCEPTED" "$TYPE_INFO" "$DIR_NEWS/$FILE" "$DIR_ACCEPTED"
		fi
	done

	get_files_count $DIR_ACCEPTED
	if [ $FILES_SIZE -gt 0 ]
		then # Check if with ax works. Else use -aux?
			if [[ $(ps -ax | grep -e "[0-9] [a-z]* $sh_process" ) == "" ]]
				then
					$sh_process
					PID_PROCESS=$(pgrep "$sh_process")
					$sh_log -c "Demonep" -m `echo $MSG_INFO_PROCESS_RUNNING | sed "s/%PID%/$PID_PROCESS/"` -t "$TYPE_INFO"
				else
					$sh_log -c "Demonep" -m "$MSG_INFO_PROCESS_POSTPONED" -t "$TYPE_INFO"
			fi
	fi

	sleep "$TIME_SLEEP"
done
