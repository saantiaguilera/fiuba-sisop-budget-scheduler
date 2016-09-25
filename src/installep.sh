#!/bin/bash

export GRUPO="Grupo5"
BINDIR="$GRUPO/bin"

#Lets the user choose a name for the input_directory, if he enters an invalid
#name or none address at all, a default one (bin) is used instead.
function input_directory {
	echo "Defina el directorio de ejecutables($GRUPO/bin): "
  read directory
  if [[ $directory != "" ]] || [ "$directory" != "dirconf" ]
  then
    BINDIR="$GRUPO/$directory"
  fi

  if [ "$directory" == "dirconf" ]
  then
    echo "El directorio "$GRUPO/dirconf" es un directorio invalido."
    input_directory #Ask the user again for another directory name
  fi
}

function system_already_installed {
  if [ ! -f */$GRUPO/Instalep.config ] #Not sure if it works like this...
  then
    return 0 #True
  else
    return 1 #False
  fi
}
