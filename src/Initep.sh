#!/bin/bash

# 1. Verify if env has been initialized

function check_previous_init() {
	EXIT_CODE=0
	
	if pgrep -x "budget_scheduler" > /dev/null
	then
		#TODO Log msg with Logep
		echo "Ambiente ya inicializado, para reiniciar termine la sesión e ingrese nuevamente."
		EXIT_CODE=1
	fi
	
	return $EXIT_CODE
}

# 2. Initialize env variables

function extract_dir() {
	eval $1=$(echo $2 | cut -d '=' -f 2)
}

function init_environment() {
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
			case $line in
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
	
	LOG="$LOG_DIR/Initep.log"
	
	#TODO Check for success, log if necessary
}

function export_environment() {
	export GRUPO
	export BIN_DIR
	export MAE_DIR
	export REC_DIR
	export OK_DIR
	export PROC_DIR
	export INFO_DIR
	export LOG_DIR
	export NOK_DIR
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
	#TODO log init with Logep
	echo "Estado del Sistema: INICIALIZADO"
}

# 4. Ask to release the DEMONIO



function main() {
	check_previous_init
	if [ ! -z $? ]; then
		return 1;
	
	init_environment
	
	export_environment
	
	check_script_permissions
	if [ ! -z $? ]; then
		return 2;
		
	check_file_permissions
	if [ ! -z $? ]; then
		return 3;
		
	system_init
	
}

main
