#!/bin/bash

GRUPO="Grupo6"
#CONF_FILE="$GRUPO/dirconf/EPLAM.conf"
CONF_FILE="$GRUPO/dirconf/instalep.conf"

#### Messages ####
TYPE_INF="INF"
TYPE_ERR="ERR"
TYPE_WAR="WAR"
MSG_ENV_INITIALIZED="Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente."
MSG_UNKNOWN_ENV_VAR="Se encontró una variable de entorno desconocida en \"EPLAM.config\". Vuelva a ejecutar Installep.sh e intente nuevamente."
MSG_MISSING_ENV_VAR="No se encontraron todas las variables requeridas en \"EPLAM.config\". Vuelva a ejecutar Installep.sh e intente nuevamente."
MSG_SCRIPT_WITHOUT_PERMISSIONS_WAR="El script %SCRIPT% no tiene permisos para ser ejecutado. Se intenta configurarlos."
MSG_SCRIPT_WITHOUT_PERMISSIONS_ERR="El script %SCRIPT% no tiene permisos para ser ejecutado. No se pudo efectuar la corrección."
MSG_FILE_WITHOUT_PERMISSIONS_WAR="El archivo %FILE% no tiene permisos de lectura. Se intenta configurarlos."
MSG_FILE_WITHOUT_PERMISSIONS_ERR="El archivo %FILE% no tiene permisos de lectura. No se pudo efectuar la corrección."
MSG_SYSTEM_INITIALIZED="Estado del Sistema: INICIALIZADO"
MSG_ASK_DEMONEP_ACTIVATION="¿Desea efectuar la activación de Demonep? (S/n)"
MSG_DEMONEP_ACTIVATED="El proceso Demonep ha sido activado."
MSG_DEMONEP_PID="Demonep corriendo bajo el no.: %PID%."
MSG_DEMONEP_MANUAL_STOP="Para detener manualmente al proceso Demonep utilice el comando \"kill %PID%\"."
MSG_DEMONEP_MANUAL_ACTIVATION="Para activar al demonio manualmente puede ingresar \"bash Demonep.sh &\"."
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
	bash "$DIRBIN/Logep.sh" -c "Initep" -m "$1" -t "$2"
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
	
	if [ ${ENV-0} -eq 1 ]
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
#   1 if successful, 0 if not.
#######################################
function init_environment() {
	EXIT_CODE=0

	DIRBIN=""
	DIRMAE=""
	DIRREC=""
	DIROK=""
	DIRPROC=""
	DIRINFO=""
	DIRLOG=""
	DIRNOK=""

	while read -r LINE; do
		case $LINE in
			DIRBIN*) extract_dir DIRBIN $LINE;;
			DIRMAE*) extract_dir DIRMAE $LINE;;
			DIRREC*) extract_dir DIRREC $LINE;;
			DIROK*) extract_dir DIROK $LINE;;
			DIRPROC*) extract_dir DIRPROC $LINE;;
			DIRINFO*) extract_dir DIRINFO $LINE;;
			DIRLOG*) extract_dir DIRLOG $LINE;;
			DIRNOK*) extract_dir DIRNOK $LINE;;
			dirconf*) ;;
			*)
				log_message "$MSG_UNKNOWN_ENV_VAR" "$TYPE_ERR"
				echo "$MSG_UNKNOWN_ENV_VAR"
				EXIT_CODE=1
				return $EXIT_CODE
			;;
		esac
	done < $CONF_FILE

	if [[ -z $GRUPO || -z $DIRBIN || -z $DIRMAE || -z $DIRREC || -z $DIROK || \
	-z $DIRPROC || -z $DIRINFO || -z $DIRLOG || -z $DIRNOK ]]; then
		log_message "$MSG_MISSING_ENV_VAR" "$TYPE_ERR"
		echo "$MSG_MISSING_ENV_VAR"
		EXIT_CODE=1
	fi

	export GRUPO
	export DIRBIN
	export DIRMAE
	export DIRREC
	export DIROK
	export DIRPROC
	export DIRINFO
	export DIRLOG
	export DIRNOK

	ENV=1
	export ENV

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
	
	shopt -s nullglob
	for SCRIPT in $DIRBIN/*
		do
			if [ ! -x "$SCRIPT" ]; then
				log_message "`echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_WAR | sed "s@%SCRIPT%@$SCRIPT@"`" "$TYPE_WAR"
				echo `echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_WAR | sed "s@%SCRIPT%@$SCRIPT@"`
				chmod +x $SCRIPT
			fi
			
			if [ ! -x "$SCRIPT" ]; then
				log_message "`echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_ERR | sed "s@%SCRIPT%@$SCRIPT@"`" "$TYPE_ERR"
				echo `echo $MSG_SCRIPT_WITHOUT_PERMISSIONS_ERR | sed "s@%SCRIPT%@$SCRIPT@"`
				EXIT_CODE=1
			fi
	done
	
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

	shopt -s nullglob	
	for FILE in $DIRMAE/*
		do
			if [ ! -r "$FILE" ]; then
				log_message "`echo $MSG_FILE_WITHOUT_PERMISSIONS_WAR | sed "s@%FILE%@$FILE@"`" "$TYPE_WAR"
				echo `echo $MSG_FILE_WITHOUT_PERMISSIONS_WAR | sed "s@%FILE%@$FILE@"`
				chmod +r $FILE
			fi
			
			if [ ! -r "$FILE" ]; then
				log_message "`echo $MSG_FILE_WITHOUT_PERMISSIONS_ERR | sed "s@%FILE%@$FILE@"`" "$TYPE_ERR"
				echo `echo $MSG_FILE_WITHOUT_PERMISSIONS_ERR | sed "s@%FILE%@$FILE@"`
				EXIT_CODE=1
			fi
	done
	
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
	while [ "$ANSWER" != "s" -a "$ANSWER" != "n" ]; do
		echo "$MSG_ASK_DEMONEP_ACTIVATION"
		log_message "$MSG_ASK_DEMONEP_ACTIVATION" "$TYPE_INF"
		read ANSWER
		log_message "$ANSWER" "$TYPE_INF"
		ANSWER="$(echo $ANSWER | tr '[:upper:]' '[:lower:]')"
		case $ANSWER in
			"s")
				log_message "$MSG_DEMONEP_ACTIVATED" "$TYPE_INF"
				echo "$MSG_DEMONEP_ACTIVATED"
				
				bash "$DIRBIN/Demonep.sh" &
				
				PROCESS_ID=$(pgrep "Demonep")
				log_message "`echo $MSG_DEMONEP_PID | sed "s@%PID%@$PROCESS_ID@"`" "$TYPE_INF"
				echo `echo $MSG_DEMONEP_PID | sed "s@%PID%@$PROCESS_ID@"`
				
				log_message "`echo $MSG_DEMONEP_MANUAL_STOP | sed "s@%PID%@$PROCESS_ID@"`" "$TYPE_INF"
				echo `echo $MSG_DEMONEP_MANUAL_STOP | sed "s@%PID%@$PROCESS_ID@"`
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
	unset DIRBIN
	unset DIRMAE
	unset DIRREC
	unset DIROK
	unset DIRPROC
	unset DIRINFO
	unset DIRLOG
	unset DIRNOK
	
	unset ENV
}


function main() {
	# 1. Verify if environment has been initialized
	echo "1"
	check_previous_init
	if [ $? -eq 1 ]; then
		return 1
	fi
	
	# 2. Initialize environment variables
	echo "2"
	init_environment
	if [ $? -eq 1 ]; then
		destroy_environment
		return 2
	fi
	
	# 3. Check permissions
	echo "3.1"
	check_script_permissions
	if [ $? -eq 1 ]; then
		destroy_environment
		return 3
	fi

	echo "3.2"
	check_file_permissions
	if [ $? -eq 1 ]; then
		destroy_environment
		return 4
	fi

	echo "4"
	log_message "$MSG_SYSTEM_INITIALIZED" "$TYPE_INF"
	echo "$MSG_SYSTEM_INITIALIZED"
	
	# 4-6. Ask to release the DEMONIO
	echo "5"
	start_demonep
	
	# 7. Close Log
	echo "7"
	log_message "$MSG_INITEP_FINISHED" "$TYPE_INF"
	echo "$MSG_INITEP_FINISHED"
}

main
