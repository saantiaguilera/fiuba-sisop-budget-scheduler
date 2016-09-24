#!/bin/bash

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
	bash logep.sh -c Initep -m $1 -t $2
}


#######################################
# Check previous environment initialization
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1 if initialized, 0 if don't.
#######################################
function check_previous_init() {
	EXIT_CODE=0
	
	if pgrep -x "budget_scheduler" > /dev/null
	then
		log_message "Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente." "ERR"
		echo "Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente."
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
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function init_environment() {
	EXIT_CODE=0
	
	GRUPO="Grupo5"
	CONF_FILE="$GRUPO/dirconf/EPLAM.conf"

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
	
	eval $1="$LOG_DIR/Initep.log" # Pa' q necesito esto jaja slds
	
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
	
	return $EXIT_CODE
}

#######################################
# Check scripts execute permissions
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   1 if denied, 0 if don't.
#######################################
function check_script_permissions() {
	EXIT_CODE=0
	cd $BIN_DIR
	
	for SCRIPT in *
		do
			if [ ! -x $SCRIPT ]
				then
					log_message "El script $SCRIPT no tiene permisos para ser ejecutado. Se intenta configurarlos." "WAR"
					echo "El script $SCRIPT no tiene permisos para ser ejecutado. Se intenta configurarlos."
					chmod +x $SCRIPT
			fi
			
			if [ ! -x $SCRIPT ]
				then
					log_message "El script $SCRIPT no tiene permisos para ser ejecutado. No se pudo efectuar la corrección." "ERR"
					echo "El script $SCRIPT no tiene permisos para ser ejecutado. No se pudo efectuar la corrección."
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
#   1 if denied, 0 if don't.
#######################################
function check_file_permissions() {
	EXIT_CODE=0
	cd $MAE_DIR
	
	for FILE in *
		do
			if [ ! -r $FILE ]
				then
					log_message "El archivo $FILE no tiene permisos de lectura. Se intenta configurarlos." "WAR"
					echo "El archivo $FILE no tiene permisos de lectura. Se intenta configurarlos."
					chmod +r $FILE
			fi
			
			if [ ! -r $FILE ]
				then
					log_message "El archivo $FILE no tiene permisos de lectura. No se pudo efectuar la corrección." "ERR"
					echo "El archivo $FILE no tiene permisos de lectura. No se pudo efectuar la corrección."
					EXIT_CODE=1
			fi
	done
	
	cd ..
	return $EXIT_CODE
}

#######################################
# 
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function system_init() {
	log_message "Estado del Sistema: INICIALIZADO" "INF"
	echo "Estado del Sistema: INICIALIZADO"
}

#######################################
# 
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
			log_message "¿Desea efectuar la activación de Demonep? (S/N)" "INF"
			echo "¿Desea efectuar la activación de Demonep? (S/N)"
			read ANSWER
			log_message ANSWER "INF"
			ANSWER="$(echo $ANSWER | tr '[:upper:]' '[:lower:]')"
			case $ANSWER in
				"s")
					log_message "El proceso Demonep ha sido activado" "INF"
					#TODO activate demonio & print/log process id
				;;
				"n")
					log_message "Para activar al demonio manualmente puede ingresar \"bash Demonep.sh\"" "INF"
					echo "Para activar al demonio manualmente puede ingresar \"bash Demonep.sh\""
				;; 
				*) echo "Responda por Sí (S) o por No (N)";;
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
	log_message "Proceso Initep finalizado" "INF"
	#TODO
	return
}

#######################################
# Unset environtment variables
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
}

function main() {
	LOG=""
	
	# 1. Verify if environment has been initialized
	check_previous_init
	if [ -z $? ]; then
		return 1;
	fi
	
	# 2. Initialize environment variables
	init_environment LOG
		if [ -z $? ]; then
		return 2;
	fi
	
	# 3. Check permissions
	check_script_permissions LOG
	if [ -z $? ]; then
		return 3;
	fi
		
	check_file_permissions LOG
	if [ -z $? ]; then
		return 4;
	fi
		
	system_init LOG
	
	# 4-6. Ask to release the DEMONIO
	start_demonep LOG
	
	# 7. Close Log
	close_log LOG
	
	# 8. Destroy environment
	destroy_environment
}

main
