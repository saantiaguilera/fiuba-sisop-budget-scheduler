#!/bin/bash

# 1. Verify if environment has been initialized

function check_previous_init() {
	EXIT_CODE=0
	
	if pgrep -x "budget_scheduler" > /dev/null
	then
		#TODO Log msg with Logep ¿? cómo si no se cual es el log_dir aca :s
		echo "Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente."
		EXIT_CODE=1
	fi
	
	return $EXIT_CODE
}

# 2. Initialize environment variables

function extract_dir() {
	eval $1=$(echo $2 | cut -d '=' -f 2)
}

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
	
	eval $1="$LOG_DIR/Initep.log"
	
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

# 3. Check permissions

function check_script_permissions() {
	EXIT_CODE=0
	cd $BIN_DIR
	
	for SCRIPT in *
		do
			if [ ! -x $SCRIPT ]
				then
					#TODO log warning with Logep
					echo "El script $SCRIPT no tiene permisos para ser ejecutado. Se intenta configurarlos."
					chmod +x $SCRIPT
			fi
			
			if [ ! -x $SCRIPT ]
				then 
					#TODO log error with Logep
					echo "El script $SCRIPT no tiene permisos para ser ejecutado. No se pudo efectuar la corrección."
					EXIT_CODE=1
			fi
	done
	
	cd ..
	return $EXIT_CODE
}

function check_file_permissions() {
	EXIT_CODE=0
	cd $MAE_DIR
	
	for FILE in *
		do
			if [ ! -r $FILE ]
				then
					#TODO log warning with Logep
					echo "El archivo $FILE no tiene permisos de lectura. Se intenta configurarlos."
					chmod +r $FILE
			fi
			
			if [ ! -r $FILE ]
				then 
					#TODO log error with Logep
					echo "El archivo $FILE no tiene permisos de lectura. No se pudo efectuar la corrección."
					EXIT_CODE=1
			fi
	done
	
	cd ..
	return $EXIT_CODE
}

function system_init() {
	#TODO log msg with Logep
	echo "Estado del Sistema: INICIALIZADO"
}

# 4. Ask to release the DEMONIO

function start_demonep() {
	ANSWER=""
	while [ "$ANSWER" != "s" -a "$ANSWER" != "n" ]
		do
			echo "¿Desea efectuar la activación de Demonep? (S/N)"
			read ANSWER
			ANSWER="$(echo $ANSWER | tr '[:upper:]' '[:lower:]')"
			case $ANSWER in
				# 5. Start Demonep
				"s")
					# log
					#TODO activate demonio
				;;
				# 6. Don't start Demonep
				"n")
					# log
					echo "Para activar al demonio manualmente puede ingresar \"bash Demonep.sh\""
				;; 
				*) echo "Responda por Sí (S) o por No (N)";;
			esac
	done
}

# 7. Close Log

function close_log() {
	#TODO
}

# 8. Destroy environment

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
	
	check_previous_init
	if [ -z $? ]; then
		return 1;
	fi
	
	init_environment LOG
		if [ -z $? ]; then
		return 2;
	fi
	
	check_script_permissions LOG
	if [ -z $? ]; then
		return 3;
	fi
		
	check_file_permissions LOG
	if [ -z $? ]; then
		return 4;
	fi
		
	system_init LOG
	
	start_demonep LOG
	
	close_log LOG
	
	destroy_environment
}

main
