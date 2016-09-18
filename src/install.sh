#!/bin/bash

#Cambiarle este nombre? por ese que pide el enunciado para instalarlo qcyo

#Global variables.

export GRUPO="Grupo5" #Maybe instead of having them as env, we should have them locally? I guess this will be required by most of scripts, so its better to have it in the console already exported
RETURN_PTR="" #Used as return variable to avoid using stdout or shared variables
BINDIR="$GRUPO/bin"


#Instalation

#Utils

# Lets the user input a particular directory inside $GRUPO 
# else picks a default which is passed as param.
# Return value is stored iniside RETURN_PTR
function input_directory {
	local dir_name=""
	read -p "Defina el directorio de ejecutables ($GRUPO/$1): " dir_name
	if [ -z "$dir_name" ]
		then
			RETURN_PTR=$1
		else
			RETURN_PTR=$dir_name
	fi
}

#Steps

STEP_CURRENT=0
STEP_LAST=1

STEP_VERIFY_NOT_INSTALLED=0

while [ $STEP_CURRENT -lt $STEP_LAST ] ;do 
	case $STEP_CURRENT in
		$STEP_VERIFY_NOT_INSTALLED) 
			echo "use use use use your imagineiiiiiiiiishon"

			let "STEP_CURRENT++"
		;;

	esac
done
