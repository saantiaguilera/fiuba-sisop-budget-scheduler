#!/bin/bash

#Cambiarle este nombre? por ese que pide el enunciado para instalarlo qcyo

#Global variables.

export GRUPO="Grupo5" #Maybe instead of having them as env, we should have them locally? I guess this will be required by most of scripts, so its better to have it in the console already exported
BINDIR="$GRUPO/bin"

#Instalation

STEP_CURRENT=0
STEP_LAST=1

STEP_VERIFY_NOT_INSTALLED=0

while [ $STEP_CURRENT -lt $STEP_LAST ] ;do 
	case $STEP_CURRENT in
		$STEP_VERIFY_NOT_INSTALLED) echo "use use use use your imagineiiiiiiiiishon"
		;;

	esac
done
