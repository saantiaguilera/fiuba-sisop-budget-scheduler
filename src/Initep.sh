#!/bin/bash

GRUPO="Grupo5"
CONF_FILE="$GRUPO/dirconf/EPLAM.conf"

#### Messages ####
TYPE_INF="INF"
TYPE_ERR="ERR"
TYPE_WAR="WAR"
MSG_ENV_INITIALIZED="Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente."
MSG_SCRIPT_WITHOUT_PERMISSIONS_WAR="El script %SCRIPT% no tiene permisos para ser ejecutado. Se intenta configurarlos."
MSG_SCRIPT_WITHOUT_PERMISSIONS_ERR="El script %SCRIPT% no tiene permisos para ser ejecutado. No se pudo efectuar la corrección."
MSG_FILE_WITHOUT_PERMISSIONS_WAR="El archivo %FILE% no tiene permisos de lectura. Se intenta configurarlos."
MSG_FILE_WITHOUT_PERMISSIONS_ERR="El archivo %FILE% no tiene permisos de lectura. No se pudo efectuar la corrección."
MSG_SYSTEM_INITIALIZED="Estado del Sistema: INICIALIZADO"
MSG_ASK_DEMONEP_ACTIVATION="¿Desea efectuar la activación de Demonep? (S/n)"
MSG_DEMONEP_ACTIVATED="El proceso Demonep ha sido activado"
MSG_DEMONEP_PID="Demonep corriendo bajo el no.: %PID%"
MSG_DEMONEP_MANUAL_ACTIVATION="Para activar al demonio manualmente puede ingresar \"bash Demonep.sh\"."
MSG_ANSWER_FAILURE="Responda por Sí (S) o por No (N)"
MSG_INITEP_FINISHED="Proceso Initep finalizado exitosamente."

#######################################
# Write log message
# Globals:
#   None
# Arguments:
#   message type_of_message
# Returns:
#   None
#######################################
function log_message() {
	. ./"$BIN_DIR/logep.sh" -c "Initep" -m $1 -t $2
}


#######################################
# Check previous environment initialization
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1 if initialized, 0 if not.
#######################################
function check_previous_init() {
	EXIT_CODE=0
	
	if [ ${ENVIRONMENT-0} -eq 1 ]
		then
			log_message "$MSG_ENV_INITIALIZED" "$TYPE_ERR"
			echo "$MSG_ENV_INITIALIZED"
			EXIT_CODE=1
	fi
	
	return $EXIT_CODE
}

#######################################
# Extract directory out of configuration file line
# Globals:
#   None
# Arguments:
#   dir_variable line
# Returns:
#   None
#######################################
function extract_dir() {
	eval $1=$(echo $2 | cut -d '=' -f 2)
}

#######################################
# Initialize environment variables
# Globals:
#   GRUPO, BIN_DIR, MAE_DIR, REC_DIR, OK_DIR, PROC_DIR,
#   INFO_DIR, LOG_DIR, NOK_DIR, ENVIRONMENT
# Arguments:
#   None
# Returns:
#   None
#######################################
function init_environment() {
	EXIT_CODE=0

	BIN_DIR=""
	MAE_DIR=""
	REC_DIR=""
	OK_DIR=""
	PROC_DIR=""
	INFO_DIR=""
	LOG_DIR=""
	NOK_DIR=""

	while read -r LINE
		do
			case $LINE in
				BIN=*) extract_dir BIN_DIR $LINE;;
				MAE=*) extract_dir MAE_DIR $LINE;;
				REC=*) extract_dir REC_DIR $LINE;;
				OK=*) extract_dir OK_DIR $LINE;;
				PROC=*) extract_dir PROC_DIR $LINE;;
				INFO=*) extract_dir INFO_DIR $LINE;;
				LOG=*) extract_dir LOG_DIR $LINE;;
				NOK=*) extract_dir NOK_DIR $LINE;;
			esac
	done < $CONF_FILE
	
	#TODO Check for success¿?, log if necessary

	export GRUPO
	export BIN_DIR
	export MAE_DIR
	export REC_DIR
	export OK_DIR
	export PROC_DIR
	export INFO_DIR
	export LOG_DIR
	export NOK_DIR
	
	ENVIRONMENT=1
	export ENVIRONMENT
	
	return $EXIT_CODE
}

#######################################
# Check scripts execute permissions
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1 if denied, 0 if not.
#######################################
function check_script_permissions() {
	EXIT_CODE=0
	cd $BIN_DIR
	
	for SCRIPT in *
		do
			if [ ! -x $SCRIPT ]
				then
					log_message `echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_WAR | sed "s/%SCRIPT%/$SCRIPT/"` "$TYPE_WAR"
					echo `echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_WAR | sed "s/%SCRIPT%/$SCRIPT/"`
					chmod +x $SCRIPT
			fi
			
			if [ ! -x $SCRIPT ]
				then
					log_message `echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_ERR | sed "s/%SCRIPT%/$SCRIPT/"` "$TYPE_ERR"
					echo `echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_ERR | sed "s/%SCRIPT%/$SCRIPT/"`
					EXIT_CODE=1
			fi
	done
	
	cd ..
	return $EXIT_CODE
}

#######################################
# Check files read permissions
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1 if denied, 0 if not.
#######################################
function check_file_permissions() {
	EXIT_CODE=0
	cd $MAE_DIR
	
	for FILE in *
		do
			if [ ! -r $FILE ]
				then
					log_message `echo $MSG_FILE_WITHOUT_PERMISSIONS_WAR | sed "s/%FILE%/$FILE/"` "$TYPE_WAR"
					echo `echo $MSG_FILE_WITHOUT_PERMISSIONS_WAR | sed "s/%FILE%/$FILE/"`
					chmod +r $FILE
			fi
			
			if [ ! -r $FILE ]
				then
					log_message `echo $MSG_FILE_WITHOUT_PERMISSIONS_ERR | sed "s/%FILE%/$FILE/"` "$TYPE_ERR"
					echo `echo $MSG_FILE_WITHOUT_PERMISSIONS_ERR | sed "s/%FILE%/$FILE/"`
					EXIT_CODE=1
			fi
	done
	
	cd ..
	return $EXIT_CODE
}

#######################################
# Ask user to start Demonep.sh
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function start_demonep() {
	ANSWER=""
	while [ "$ANSWER" != "s" -a "$ANSWER" != "n" ]
		do
			log_message "$MSG_ASK_DEMONEP_ACTIVATION" "$TYPE_INF"
			echo "$MSG_ASK_DEMONEP_ACTIVATION"
			read ANSWER
			log_message ANSWER "$TYPE_INF"
			ANSWER="$(echo $ANSWER | tr '[:upper:]' '[:lower:]')"
			case $ANSWER in
				"s")
					log_message "$MSG_DEMONEP_ACTIVATED" "$TYPE_INF"
					echo "$MSG_DEMONEP_ACTIVATED"
					
					#TODO activate demonio & manual stop instructions
					#"$BIN_DIR/Demonep.sh"
					
					PROCESS_ID=$(pgrep "Demonep")
					log_message `echo $MSG_DEMONEP_PID | sed "s/%PID%/$PROCESS_ID/"` "$TYPE_INF"
					echo `echo $MSG_DEMONEP_PID | sed "s/%PID%/$PROCESS_ID/"`
				;;
				"n")
					log_message "$MSG_DEMONEP_MANUAL_ACTIVATION" "$TYPE_INF"
					echo "$MSG_DEMONEP_MANUAL_ACTIVATION"
				;;
				*) echo "$MSG_ANSWER_FAILURE";;
			esac
	done
}

#######################################
# Close log file
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function close_log() {
	#TODO
	return
}

#######################################
# Unset environment variables
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function destroy_environment() {
	unset GRUPO
	unset BIN_DIR
	unset MAE_DIR
	unset REC_DIR
	unset OK_DIR
	unset PROC_DIR
	unset INFO_DIR
	unset LOG_DIR
	unset NOK_DIR
	
	unset ENVIRONMENT
}


function main() {
	# 1. Verify if environment has been initialized
	check_previous_init
	if [ $? -eq 1 ]; then
		return 1
	fi
	
	# 2. Initialize environment variables
	init_environment
	if [ $? -eq 1 ]; then
		destroy_environment
		return 2
	fi
	
	# 3. Check permissions
	check_script_permissions
	if [ $? -eq 1 ]; then
		destroy_environment
		return 3
	fi
		
	check_file_permissions
	if [ $? -eq 1 ]; then
		destroy_environment
		return 4
	fi
		
	log_message "$MSG_SYSTEM_INITIALIZED" "$TYPE_INF"
	echo "$MSG_SYSTEM_INITIALIZED"
	
	# 4-6. Ask to release the DEMONIO
	start_demonep
	
	# 7. Close Log
	log_message "$MSG_INITEP_FINISHED" "$TYPE_INF"
	echo "$MSG_INITEP_FINISHED"
	close_log
}

main
