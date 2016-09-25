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


#Lets the user choose a name for the input_directory, if he enters an invalid
#name or none address at all, a default one (bin) is used instead.
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

function system_already_installed {
  if [ ! -f */$GRUPO/Instalep.config ] #Not sure if it works like this...
  then
    return 0 #True
  else
    return 1 #False
  fi
}
