#!/bin/bash

#Cambiarle este nombre? por ese que pide el enunciado para instalarlo qcyo

#Global variables.

export GRUPO="Grupo5" #Maybe instead of having them as env, we should have them locally? I guess this will be required by most of scripts, so its better to have it in the console already exported
RETURN_PTR="" #Used as return variable to avoid using stdout or shared variables
BINDIR="$GRUPO/bin" #Maybe we should ask here the bindir? kinda $GRUPO/`input_directory "bin"`
export CONFDIR="$GRUPO/dirconf" #Its protected. Do not change it!
DEF_DIRS=( "Configuracion" "Ejecutables" "Maestros y Tablas"\\
"Recepcion de Novedades" "Archivos Aceptados" "Archivos Procesados"\\ 
"Archivos de Reportes" "Archivos de Log" "Archivos Rechazados" )
#Instalation

#Utils

# Lets the user input a particular directory inside $GRUPO 
# else picks a default which is passed as param.
# Return value is stored iniside RETURN_PTR
function input_directory {
	local dir_name=""
    local msg="Defina el directorio de $1 ($GRUPO/$2): "
	read -p $msg dir_name
	if [ -z "$dir_name" ]
		then
            dir_name=$1
			RETURN_PTR=$1
		else
			RETURN_PTR=$dir_name
	fi
    sed -e "\$a$msg$dir_name" instalep.conf
}

function select_dirs {
    for ((i=0; i<${#DEF_DIRS[@]}; i+=2)); do
        input_directory ${#DEF_DIRS[i]} ${#DEF_DIRS[i+1]}
    done
}

#Steps

STEP_CURRENT=0
STEP_LAST=1

STEP_VERIFY_NOT_INSTALLED=0
STEP_SELECT_DIRS=1
while [ $STEP_CURRENT -lt $STEP_LAST ] ;do 
	case $STEP_CURRENT in
		$STEP_VERIFY_NOT_INSTALLED) 
			echo "use use use use your imagineiiiiiiiiishon"
			if [ -r "$CONFDIR/instalep.conf" ] 
				then 
					echo "Leer el .conf"
				else
					echo "recursamo"
			fi

			let "STEP_CURRENT++"
		;;

        $STEP_SELECT_DIRS)
            select_dirs            
        ;;

	esac
done
