#!/bin/bash

RETURN_PTR=0

# 1. Verify if env has been initialized

function check_previous_init() {
	if pgrep -x "budget_scheduler" > /dev/null
	then
		echo "Ambiente ya inicializado, para reiniciar termine la sesin e ingrese nuevamente."
		#TODO Log msg with Logep ¿?¿?¿? COMO
		exit 1
	fi
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

	while read -r line
		do
			case $line in
				BIN=*) extract_dir BIN_DIR $line;;
				MAE=*) extract_dir MAE_DIR $line;;
				REC=*) extract_dir REC_DIR $line;;
				OK=*) extract_dir OK_DIR $line;;
				PROC=*) extract_dir PROC_DIR $line;;
				INFO=*) extract_dir INFO_DIR $line;;
				LOG=*) extract_dir LOG_DIR $line;;
				NOK=*) extract_dir NOK_DIR $line;;
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
# TODO

check_previous_init
init_environment
export_environment
