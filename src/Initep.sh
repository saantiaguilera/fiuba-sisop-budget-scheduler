#!/bin/bash

RETURN_PTR=0

# 1. Verify if env has been initialized

if ! [ pgrep -x "budget_scheduler" > /dev/null ]
	then
		echo "Ambiente ya inicializado, para reiniciar termine la sesin e ingrese nuevamente."
		#TODO Log msg with Logep
		exit 1
fi

# 2. Initialize env variables

export GRUPO="Grupo5"
CONF_FILE="$GRUPO/dirconf/EPLAM.conf"

#TODO Read variables below from CONF_FILE
export LOG_DIR="$GRUPO/DIRLOG"
LOG="$LOG_DIR/Initep.log"
export BIN_DIR=""
export MAE_DIR=""
export REC_DIR=""
export OK_DIR=""
export PROC_DIR=""
export INFO_DIR=""
