#!/bin/bash

####################################################
################       DAEMON       ################
####################################################
# NOTES;
# - Please always ensure the daemon is run in a background job. For this append at the end of the shell command a '&' eg "echo "test" &"
# - Must be runned in an environment which has previously run Initep (To ensure we can reach the environment variables set by it in their exports).

#### Dirs ####
DIR_REJECTED=$DIRNOK
DIR_ACCEPTED=$DIROK
DIR_NEWS=$DIRREC
DIR_ASSETS=$DIRMAE

#### Shell scripts ####
sh_mov="$DIRBIN/Movep.sh"
sh_log="$DIRBIN/Logep.sh"
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
	$sh_log -c "Demonep" -m "$1" -t "$2"
	$sh_mov -c "Demonep" -o "$3" -d "$4"
}

#######################################
# Evicts non text files or empty from the news dir handling the rejected ones.
# Will remove file from directory if malformed
#######################################
function evict_malformed_files() {
	for FILE in $(ls -1 "$DIR_NEWS");do
		local IS_REJECTED=0
		local MIME_TYPE=($(file "$DIR_NEWS/$FILE" | cut -d' ' -f2))
		if [ `echo "$MIME_TYPE" | grep '(^ASCII)'` ]
			then
				$sh_log -c "Demonep" -m "`echo "$MSG_INFO_FILE_DETECTED" | sed "s/%FILE_NAME%/$FILE/"`" -t "$TYPE_INFO"
				log_n_move "$MSG_ERR_INVALID_FILE_TYPE" "$TYPE_ERROR" "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		    	$IS_REJECTED=1
		fi
		
		if [ $IS_REJECTED -eq 0 ] && [ "`cat "$DIR_NEWS/$FILE" | wc -l`" -eq 0 ]
			then
				$sh_log -c "Demonep" -m "`echo "$MSG_INFO_FILE_DETECTED" | sed "s/%FILE_NAME%/$FILE/"`" -t "$TYPE_INFO"
				log_n_move "$MSG_ERR_INVALID_FILE_SIZE" "$TYPE_ERROR" "$DIR_NEWS/$FILE" "$DIR_REJECTED"
		fi
	done
}

#######################################
# Saves the state codes in array CODES_STATES
# Globals:
#   CODES_STATES
#######################################
function parse_state_codes() {
	CODES_STATES=($(tail -n +2 "$DIR_ASSETS/provincias.csv" | cut -d\; -f1))
}

#######################################
# Saves the budget data in array BUDGET_DATES. 
# The size of only the budget years is BUDGET_SIZE
# Globals:
#   BUDGET_DATES: Contains :year-:start_date-:end_date
#   BUDGET_SIZE: Contanins size of only :year
#######################################
function parse_budget_dates() {
    # n makes it quiet without printing everything
    local FORMATTED_DATA="`sed -n "/.*Anual.*/p" "$DIR_ASSETS/trimestres.csv"`"

    BUDGET_DATA=()
    BUDGET_DATA+=($(echo "$FORMATTED_DATA" | cut -d\; -f1))
    BUDGET_DATA+=($(echo "$FORMATTED_DATA" | cut -d\; -f3))
    BUDGET_DATA+=($(echo "$FORMATTED_DATA" | cut -d\; -f4))
    
    BUDGET_SIZE="`echo "$FORMATTED_DATA" | wc -l`"
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
	# Check if filename at least matches the start and end the name should have
	if ! [[ `echo $1 | sed "s/^ejecutado_.*\.csv$//"` == "" ]]
		then
			log_n_move "$MSG_ERR_INVALID_FILE_NAME" "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED" 
			let "EXIT_CODE = 2"
	fi
}

#######################################
# Validates the budget year is the current one
# Will remove file from directory if malformed.
# Globals:
#   EXIT_CODE
#   CURRENT_BUDGET_YEAR_INDEX: Inflates in this variable the budget year index of this file
# Arguments:
#   1. File name to validate
# Returns:
#   Exit code with state
#######################################
function validate_budget_year() {
	local FILE_BUDGET_YEAR="`echo "$1" | sed "s/^ejecutado_//" | sed "s/_.*$//"`"
    CURRENT_BUDGET_YEAR_INDEX="-1"

    local i=0
    while ((i<BUDGET_SIZE)); do
        if [[ "${BUDGET_DATA[$i]}" == "$FILE_BUDGET_YEAR" ]]
        then
            CURRENT_BUDGET_YEAR_INDEX="$i"
        fi

        let "i++"
    done

	# Check if the budget year is this one
	if [[ $CURRENT_BUDGET_YEAR_INDEX == "-1" ]]
		then
			print_generic_error_if_needed
			log_n_move "`echo "$MSG_ERR_INVALID_BUDGET_YEAR" | sed "s/%YEAR%/$FILE_BUDGET_YEAR/"`" "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
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
	local STATE_CODE=$(echo $1 | sed "s/^ejecutado_...._//" | sed "s/_.*$//" )

	local FOUND=0
	for ARR_CODE in "${CODES_STATES[@]}"; do
		if [[ "$STATE_CODE" == "$ARR_CODE" ]] 
			then
				FOUND=1
		fi
	done

	if [ $FOUND -eq 0 ] 
		then 
			print_generic_error_if_needed
			log_n_move "`echo "$MSG_ERR_INVALID_STATE_CODE" | sed "s/%STATE%/$STATE_CODE/"`" "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
			let "EXIT_CODE = 2"
	fi
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
	local M_DATE="`echo "$1" | sed "s/^ejecutado_.*_.*_//" | sed "s/\..*$//"`"

    local BUDGET_START_DATE_INDEX=$(($CURRENT_BUDGET_YEAR_INDEX+$BUDGET_SIZE))
    local BUDGET_END_DATE_INDEX=$(($CURRENT_BUDGET_YEAR_INDEX+$BUDGET_SIZE+$BUDGET_SIZE))

    # Uncomment the one you need. -d is Linux distro / -j -f OS X
    #local BUDGET_START_DATE="`date -d "${BUDGET_DATA[$BUDGET_START_DATE_INDEX]} +"%Y%m%d"`"
    local BUDGET_START_DATE="`date -j -f "%d/%m/%Y" "${BUDGET_DATA[$BUDGET_START_DATE_INDEX]}" +"%Y%m%d"`"

    # Uncomment the one you need. -d is Linux distro / -j -f OS X
    #local BUDGET_END_DATE="`echo "${BUDGET_DATA[$BUDGET_END_DATE_INDEX]}" | sed -r "s/(.{2}).(.{2}).(.{4})/\3-\2-\1/" | date -d +"%Y%m%d"`"
    local BUDGET_END_DATE="`date -j -f "%d/%m/%Y" "${BUDGET_DATA[$BUDGET_END_DATE_INDEX]}" +"%Y%m%d"`"

	if [ $M_DATE -lt $BUDGET_START_DATE ]; then
		print_generic_error_if_needed
		log_n_move "`echo "$MSG_ERR_OUTOFBOUNDS_DATE" | sed "s/%DATE%/$M_DATE/"`" "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
		let "EXIT_CODE = 2"
		return
	fi
	
	if [ $M_DATE -gt $BUDGET_END_DATE ]; then
		print_generic_error_if_needed
		log_n_move "`echo "$MSG_ERR_OUTOFBOUNDS_DATE" | sed "s/%DATE%/$M_DATE/"`" "$TYPE_ERROR" "$DIR_NEWS/$1" "$DIR_REJECTED"
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
    parse_budget_dates
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
					$sh_log -c "Demonep" -m "`echo "$MSG_INFO_PROCESS_RUNNING" | sed "s/%PID%/$PID_PROCESS/"`" -t "$TYPE_INFO"
				else
					$sh_log -c "Demonep" -m "$MSG_INFO_PROCESS_POSTPONED" -t "$TYPE_INFO"
			fi
	fi

	sleep "$TIME_SLEEP"
done
