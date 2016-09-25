#!/bin/bash

export GRUPO="Grupo5"

DIRBIN="$GRUPO/bin"
DIRMAE="$GRUPO/mae"
DIRREC="$GRUPO/nov"
DIROK="$GRUPO/ok"
DIRPROC="$GRUPO/imp"
DIRINFO="$GRUPO/rep"
DIRLOG="$GRUPO/log"
DIRNOK="$GRUPO/nok"

DATASIZE=100

#Lets the user choose a name for the input_directory, if he enters an invalid
#name or none address at all, a default one is used instead.
function input_directory {
  read directory

  if [[ $directory != "" ]] || [ "$directory" != "dirconf" ]
  then
		set -- "$GRUPO/$directory" "$1"
  fi

  if [ "$directory" == "dirconf" ]
  then
    echo "El directorio "$GRUPO/dirconf" es un directorio invalido. Ingrese otro nombre: "
    input_directory #Ask the user again for another directory name
  fi

	return 0
}

#Lets the user choose a name for all the directories the EPLAM program uses,
#if he enters an invalid name or none address at all, a default one is used
# instead.
function input_directories {
	echo "Defina el directorio de ejecutables ($GRUPO/bin): "
	input_directory DIRBIN

	echo "Defina el directorio de Maestros y Tablas ($GRUPO/mae): "
	input_directory DIRMAE

	echo "Defina el directorio de recepcion de novedades ($GRUPO/nov): "
	input_directory DIRREC

	echo "Defina el directorio de Archivos Aceptados ($GRUPO/ok): "
	input_directory DIROK

	echo "Defina el directorio de Archivos Procesados ($GRUPO/imp): "
	input_directory DIRPROC

	echo "Defina el directorio de Reportes($GRUPO/rep): "
	input_directory DIRINFO

	echo "Defina el directorio de log ($GRUPO/log): "
	input_directory DIRLOG

	echo "Defina el directorio de rechazador ($GRUPO/nok): "
	input_directory DIRNOK

	return 0
}

#Checks if the system has been already installed, returning an 0 in that case
#and a 1 if not.
function system_already_installed {
  if [ ! -f */$GRUPO/Instalep.config ] #Not sure if it works like this...
  then
    return 0 #True
  else
    return 1 #False
  fi
}

function set_news_size {
	local SYSTEM_SIZE=""
	SYSTEM_SIZE_M=$(df -BM . | tail -1 | awk '{print $4}')
	SYSTEM_SIZE="`echo $SYSTEM_SIZE_M | sed "s/M$//"`"

	echo "Defina espacio minimo libre para la recepcion de archivos en Mbytes (100): "
	read size

	if [[ $size -gt $SYSTEM_SIZE ]]
	then
		echo "Insuficiente espacio en disco."
		echo "Espacio disponible: $SYSTEM_SIZE Mb."
		echo "Espacio requerido $size Mb."
		echo "Intentelo nuevamente."
		set_news_size
	else
		echo "Suficiente espacio en disco."
		echo "Espacio disponible: $SYSTEM_SIZE Mb."
		echo "Espacio requerido $size Mb."
		echo "De enter para continuar."
		read enter
	fi

	return 0
}

set_news_size
