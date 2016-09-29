#!/bin/bash

export GRUPO="Grupo6"

# Dirs
DIRCONF="$GRUPO/dirconf"
DIRBIN="$GRUPO/bin"
DIRMAE="$GRUPO/mae"
DIRREC="$GRUPO/nov"
DIROK="$GRUPO/ok"
DIRPROC="$GRUPO/imp"
DIRINFO="$GRUPO/rep"
# Temporarly create log files in the default location, if the user specifies
# another, this script should move it accordingly
export DIRLOG="$GRUPO/log"
DIRNOK="$GRUPO/nok"
# I dont know if this dict will be updated after the users sets the directories
declare -A DIRS=(["dirconf"]=$DIRCONF ["DIRBIN"]=$DIRBIN ["DIRMAE"]=$DIRMAE 
["DIRREC"]=$DIRREC ["DIROK"]=$DIROK ["DIRPROC"]=$DIRPROC ["DIRINFO"]=$DIRINFO 
["DIRLOG"]=$DIRLOG ["DIRNOK"]=$DIRNOK)


# Commands
INITEP="Initep.sh"
DEMONEP="Demonep.sh"
LOGEP="Logep.sh"
MOVEP="Movep.sh"
#declare -A COMMANDS=(["Demonep"]=)
DATASIZE=100

#######################################
#Lets the user choose a name for the input_directory, if he enters an invalid
#name or none address at all, a default one is used instead.
# Globals:
#   GRUPO
# Arguments:
#   Default directory
# Returns:
#   0
#######################################
function input_directory {
read directory

if [ "$directory" == "dirconf" ] || [[ -z "${directory// }" ]]; then
  echo "El directorio "$GRUPO/dirconf", un nombre de directorio que contiene 
  solo espacios o es vacio son directorios invalidos. Ingrese otro nombre: "
  input_directory $1 #Ask the user again for another directory name
else
  local dir=$1
  set -- "$GRUPO/$directory" "$1"
  DIRS["$dir"]=$1
fi

#if [[ ! -z "${directory// }" ]] && [ "$directory" != "dirconf" ]; then
#  local dir=$1
#  set -- "$GRUPO/$directory" "$1"
#  DIRS["$dir"]=$1
#  echo "NUEVO DIR: ${!DIRS[$dir]} -  ${DIRS[$dir]}"
#fi


return 0
}

#######################################
#Lets the user choose a name for all the directories the EPLAM program uses,
#if he enters an invalid name or none address at all, a default one is used
# instead.
# Globals:
#   DIRBIN, DIRMAE, DIRREC, DIROK, DIRPROC, DIRINFO, DIRLOG, DIRNOK
# Arguments:
#   None
# Returns:
#   0
#######################################
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

#######################################
#Checks if the system has been already installed.
# Globals:
#   GRUPO
# Arguments:
#   None
# Returns:
#   0 if True, 1 if False
#######################################
function system_already_installed {
if [[ -d /$GRUPO/ ]] && [[ ! -f /$GRUPO/Instalep.conf ]]; then
  return 0 #True
else
  return 1 #False
fi
}

#######################################
#Sets the size for new archives, the size is stored as megabytes.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0
#######################################
function set_news_size {
local SYSTEM_SIZE=""
SYSTEM_SIZE_M=$(df -BM . | tail -1 | awk '{print $4}')
SYSTEM_SIZE="`echo $SYSTEM_SIZE_M | sed "s/M$//"`"

echo "Defina espacio minimo libre para la recepcion de archivos en Mbytes (100): "
read size

if [[ $size -gt $SYSTEM_SIZE ]]; then
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

#######################################
#Shows the values that had been defined for the directories, lets the user
#answer if they are OK.
# Globals:
#   GROUPO, DIRBIN, DIRMAE, DIRREC, DIROK, DIRPROC, DIRINFO, DIRLOG, DIRNOK
# Arguments:
#   None
# Returns:
#   0 if the values are OK, 1 if not.
#######################################
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
if [ "$answer" == "si" ]; then
  return 0
else
  return 1
fi
}

#######################################
#Ask the user to confirm the instalation
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   0 if the user confirms, 1 if not.
#######################################
function instalation_confirm {
echo "Iniciando Instalacion. Esta Ud. seguro? (Si – No/Otra cosa)"
read answer
answer="${answer,,[SI]}"
if [ "$answer" == "si" ]; then
  return 0 #True
else
  return 1 #False
fi
}

#######################################
#Installs the program.
# Globals:
#   GROUPO, DIRBIN, DIRMAE, DIRREC, DIROK, DIRPROC, DIRINFO, DIRLOG, DIRNOK
# Arguments:
#   None
# Returns:
#   None
#######################################
function installation {
#create directories
#move archives, execs and functions.
  # Iterate over the ht values
  mkdir $GRUPO
  for i in "${DIRS[@]}"; do
    echo $i
    mkdir $i
  done
  bash $LOGEP -c instalep -m "Creando Estructuras de directorio ..."

  bash $LOGEP -c instalep -m "Instalando Programas y Funciones"
  shopt -s nullglob
  for file in *.sh; do
    mv $file "$DIRBIN/$file"
    if [[ "$file" == "Logep.sh" ]]; then
      LOGEP="$DIRBIN/$file"
    fi
  done
  bash $LOGEP -c instalep -m "Instalando Archivos Maestros y Tablas"
  #shopt -s nullglob
  for file in actividades.csv sancionado-2016.csv centros.csv provincias.csv tabla-AxC.csv trimestres.csv; do
    mv $file "$DIRMAE/$file"
  done
}

#######################################
#Creates the Instalep.conf archive.
# Globals:
#   GROUPO, DIRBIN, DIRMAE, DIRREC, DIROK, DIRPROC, DIRINFO, DIRLOG, DIRNOK
# Arguments:
#   None
# Returns:
#   None
#######################################
function create_conf_archive {
#create Instalep.conf
#write log
  bash $LOGEP -c instalep -m "Actualizando la configuracion del sistema"
  local conf_file="${DIRS["dirconf"]}/instalep.conf"
  touch $conf_file
  for i in "${!DIRS[@]}"; do
    local value=${DIRS[$i]}
    echo "$i=$value=$USER=`date -u`" >> $conf_file
  done
  bash $LOGEP -c instalep -m "Instalacion CONCLUIDA."
}

#######################################
#Ends the installation process.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function end_process {
#delete temporary archives.
#write log
  #bash $LOGEP -c instalep -m "Fin"
  echo "Fin"
}

#######################################
#Executes the installep
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function main {
#Call to log, begin process

if system_already_installed; then
  echo "Fin"
  return 0
fi

input_directories
set_news_size
#Go back to the beginning if the user don't confirms the values
#maybe it would be better to change "show_values" name.

if ! show_values; then
  main
fi

if instalation_confirm; then
  installation
  create_conf_archive
fi
bash $LOGEP -c instalep -m "Fin"
}

main
