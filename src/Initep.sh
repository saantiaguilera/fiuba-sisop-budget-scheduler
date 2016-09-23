#!/bin/bash

RETURN_PTR=0

# 1. Verify if env has been initialized

if pgrep -x "budget_scheduler" > /dev/null
	then
		echo "Ambiente ya inicializado, para reiniciar termine la sesin e ingrese nuevamente."
		#TODO Log msg with Logep
		exit 1
fi

# 2. Initialize env variables

export GRUPO="Grupo5"
CONF_FILE="$GRUPO/dirconf/EPLAM.conf"
export BIN_DIR=""
export MAE_DIR=""
export REC_DIR=""
export OK_DIR=""
export PROC_DIR=""
export INFO_DIR=""
export LOG_DIR=""
export NOK_DIR=""

while read -r line
	do
		case $line in
			BIN=*) BIN_DIR=$line;;
			MAE=*) MAE_DIR=$line;;
			REC=*) REC_DIR=$line;;
			OK=*) OK_DIR=$line;;
			PROC=*) PROC_DIR=$line;;
			INFO=*) INFO_DIR=$line;;
			LOG=*) LOG_DIR=$line;;
			NOK=*) NOK_DIR=$line;;
	esac
done < $CONF_FILE

LOG="$LOG_DIR/Initep.log"
#TODO Check for success, log if necessary

# 3. Check permissions
