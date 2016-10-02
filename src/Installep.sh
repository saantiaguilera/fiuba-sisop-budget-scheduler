#!/bin/bash

export GRUPO="Grupo6"

# Dirs
# TODO: use absolute paths
DIRCONF="$GRUPO/dirconf"
DIRBIN="$GRUPO/bin"
DIRMAE="$GRUPO/mae"
DIRREC="$GRUPO/nov"
DIROK="$GRUPO/ok"
DIRPROC="$GRUPO/imp"
DIRINFO="$GRUPO/rep"
DIRNOK="$GRUPO/nok"
DIRLOG="$GRUPO/log"

declare -A DIRS=(["DIRBIN"]=$DIRBIN ["DIRMAE"]=$DIRMAE
["DIRREC"]=$DIRREC ["DIROK"]=$DIROK ["DIRPROC"]=$DIRPROC ["DIRINFO"]=$DIRINFO
["DIRLOG"]=$DIRLOG ["DIRNOK"]=$DIRNOK)

declare -A DESCS=(["DIRBIN"]="ejecutables" ["DIRMAE"]="Maestros y Tablas"
["DIRREC"]="recepcion de novedades" ["DIROK"]="Archivos Aceptados"
["DIRPROC"]="Archivos Procesados" ["DIRINFO"]="Reportes" ["DIRLOG"]="Log"
["DIRNOK"]="Archivos Rechazados")

# Commands
# Temporarly create log files in the dirconf location, if the user specifies
# another, this script should move it accordingly
export DIRLOG="$GRUPO/dirconf"
LOGEP="Logep.sh"
DATASIZE=100

#######################################
#Checks if a directory exists inside of the system files.
# Globals:
#   GRUPO
# Arguments:
#   Name of a directory
# Returns:
#   0 if True, 1 if False
#######################################
function directory_already_exists {
  for dir in "${!DIRS[@]}"; do
    if [ "$dir" == "$GRUPO/$1" ]; then
      return 0
    fi
  done

  if [[ -d $PWD/$GRUPO/ ]] && [[ -f $PWD/$GRUPO/$1 ]]; then
    return 0 #True
  else
    return 1 #False
  fi
}

#######################################
#Lets the user choose a name for the input_directory, if he enters an invalid
#name or none address at all, a default one is used instead.
# Globals:
#   GRUPO
# Arguments:
#   Default directory1
# Returns:
#   0
#######################################
function input_directory {
read directory

if [ "$directory" == "dirconf" ] || [[ -z "${directory// }" ]] || directory_already_exists $directory; then
  echo "El directorio "$GRUPO/dirconf", un nombre de directorio que contiene
  solo espacios, un directorio ya existente o que es vacio son directorios
  invalidos. Ingrese otro nombre: "
  input_directory $1 #Ask the user again for another directory name
else
  local dir=$1
  #set -- "$GRUPO/$directory" "$1"
  DIRS["$dir"]="$GRUPO/$directory"
fi

#if [[ ! -z "${directory// }" ]] && [ "$directory" != "dirconf" ]; then
#  local dir=$1
#  set -- "$GRUPO/$directory" "$1"
#  DIRS["$dir"]=$1
#  echo "NUEVO DIR: ${!DIRS[$dir]} -  ${DIRS[$dir]}"
#fi
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

for desc in "${!DESCS[@]}"; do
  echo "Defina el directorio de ${DESCS[$desc]} (${DIRS[$desc]}):"
  input_directory $desc
done
#echo "Defina el directorio de ejecutables ($GRUPO/bin): "
#input_directory DIRBIN
#
#echo "Defina el directorio de Maestros y Tablas ($GRUPO/mae): "
#input_directory DIRMAE
#
#echo "Defina el directorio de recepcion de novedades ($GRUPO/nov): "
#input_directory DIRREC
#
#echo "Defina el directorio de Archivos Aceptados ($GRUPO/ok): "
#input_directory DIROK
#
#echo "Defina el directorio de Archivos Procesados ($GRUPO/imp): "
#input_directory DIRPROC
#
#echo "Defina el directorio de Reportes($GRUPO/rep): "
#input_directory DIRINFO
#
#echo "Defina el directorio de log ($GRUPO/log): "
#input_directory DIRLOG
#
##echo "Defina el directorio de rechazador ($GRUPO/nok): "
##input_directory DIRNOK

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
  if [[ -d /$GRUPO/ ]] && [[ -f /$GRUPO/instalep.conf ]]; then
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

digits='^[0-9]+$'
if ! [[ $size =~ $digits ]]; then
  echo "Debe ingresar un numero entero positivo."
  set_news_size
  return 0
fi

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
for desc in "${!DESCS[@]}"; do
  echo "Directorio de ${DESCS[$desc]} ${DIRS[$desc]}"
done
#echo "Directorio de Configuracion: $GRUPO/dirconf"
#echo "Directorio de Ejecutables: $DIRBIN"
#echo "Directorio de Maestros y Tablas: $DIRMAE"
#echo "Directorio de Recepcion de Novedades: $DIRREC"
#echo "Directorio de Archivos Aceptados: $DIROK"
#echo "Directorio de Archivos Procesados: $DIRPROC"
#echo "Directorio de Archivos de Reportes: $DIRINFO"
#echo "Directorio de Archivos de Log: $DIRLOG"
#echo "Directorio de Archivos Rechazados: $DIRNOK"
echo "Estado de la instalacion: LISTA."
echo "Desea continuar con la instalacion? (Si - No/Otra cosa)"

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
  echo "Iniciando Instalacion. Esta Ud. seguro? (Si - No/Otra cosa)"
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
  for i in "${DIRS[@]}"; do
    echo $i
    mkdir $i
  done
  bash $LOGEP -c instalep -m "Creando Estructuras de directorio ..."

  bash $LOGEP -c instalep -m "Instalando Programas y Funciones"
  shopt -s nullglob
  bash Movep.sh -c "Instalep" -o "*.sh" -d "$PWD/$DIRBIN"
  #for file in *.sh; do
  #  if [[ "$file" != "Installep.sh" ]]; then
  #    mv $file "${DIRS["DIRBIN"]}/$file"
  #  fi
  #  if [[ "$file" == "Logep.sh" ]]; then
  #    LOGEP="${DIRS["DIRBIN"]}/$file"
  #  fi
  #done
  #bash $LOGEP -c instalep -m "Instalando Archivos Maestros y Tablas"
  bash Movep.sh -c "Instalep" -o "*(^[0-9]).csv" -d "$PWD/$DIRMAE"
  bash Movep.sh -c "Instalep" -o "*.csv" -d "$PWD/$DIRNOV"
  #for file in actividades.csv sancionado-2016.csv centros.csv provincias.csv tabla-AxC.csv trimestres.csv; do
  #  mv $file "${DIRS["DIRMAE"]}/$file"
  #done
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
  bash $LOGEP -c instalep -m "Actualizando la configuracion del sistema"
  local conf_file="$GRUPO/dirconf/instalep.conf"
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
