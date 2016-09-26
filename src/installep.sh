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

#Sets the size for new archives, the size is stored as megabytes.
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

#Shows the values that had been defined for the directories, lets the user
#answer if they are OK, returning 0 in that case, 1 if not.
function show_values {
	echo "Directorio de Configuracion: $GRUPO/dirconf"
	#listar Archivos
	echo "Directorio de Ejecutables: $DIRBIN"
  #listar Archivos
	echo "Directorio de Maestros y Tablas: $DIRMAE"
	#listar archivos
	echo "Directorio de Recepcion de Novedades: $DIRREC"
	echo "Directorio de Archivos Aceptados: $DIROK"
	echo "Directorio de Archivos Procesados: $DIRPROC"
	echo "Directorio de Archivos de Reportes: $DIRINFO"
	echo "Directorio de Archivos de Log: $DIRLOG"
	echo "Directorio de Archivos Rechazados: $DIRNOK"
	echo "Estado de la instalacion: LISTA."
	echo "Desea continuar con la instalacion? (Si – No/Otra cosa)"

	read answer
	answer="${answer,,[SI]}"
	if [ "$answer" == "si" ]
	then
		return 0
	else
		return 1
	fi
}

function instalation_confirm {
  echo "Iniciando Instalacion. Esta Ud. seguro? (Si – No/Otra cosa)"

	read answer
	answer="${answer,,[SI]}"
	if [ "$answer" == "si" ]
	then
		return 0 #True
	else
		return 1 #False
	fi
}

function instalation {
  #create directories
  #move archives, execs and functions.
}

function create_conf_archive {
  #create Instalep.conf
  #write log
}

function end_process {
  #delete temporary archives.
  #write log
}


function main {
  #Call to log, begin process
  if system_already_installed
  then
    end_process
    return 0
  fi

  input_directories
  set_news_size

  if show_values #Go back to the beginning if the user don't confirms the values
  then           #maybe it would be better to change "show_values" name.
    main
  fi

  if [ ! instalation_confirm ]
  then
    end_process
    return 0
  fi

  instalation
  create_conf_archive
  end_process

  return 0
}
