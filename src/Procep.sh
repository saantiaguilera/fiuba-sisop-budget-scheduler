MSG_ENV_NOT_INITIALIZED="Ambiente no inicializado, ejecute Initep.sh."
CANT_TO_PROC="Cantidad de archivos a procesar:"
DUPL_FILE_MSG="Archivo Duplicado. Se rechaza el archivo"
BAD_FRMT_FILE="Estructura inesperada. Se rechaza el archivo"

TYPE_ERR="ERR"
TYPE_INF="INF"
TYPE_WAR="WAR"
NUMBER_OF_FIELDS=6

function log_message() {
  bash "$DIRBIN/Logep.sh" -c "Procep" -m "$1" -t "$2"
}

function check_previous_init(){
  if [ ${ENV-0} -ne 1 ]; then
    echo "$MSG_ENV_NOT_INITIALIZED"
    return 1
  fi
return 0
}

function count_files() {
  return $(ls -1 $1 | wc -l)
}

#######################################
#Checks for duplicate files in DIROK, if found, moves them to DIRNOK.
# Globals:
#   DIRBIN, DIROK, DIRNOK
# Arguments:
#   DIRPROC/proc
# Returns:
#   None
#######################################
function check_for_duplicates() {
  local file
  for f in "$DIROK"/*".csv"; do
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`" #TODO: arreglar esta negrada
    if [ -e  "$1"/"$file" ]; then
      log_message "$DUPL_FILE_MSG $file" "TYPE_ERR"
      bash "$DIRBIN/Movep.sh" -c "Procep" -o "$DIROK/$file" -d "$DIRNOK"
    fi
  done
}

#######################################
#Checks the format of files in DIROK, if incorrect, moves them to DIRNOK.
# Globals:
#   DIRBIN, DIROK, DIRNOK
# Arguments:
#   None
# Returns:
#   None
#######################################
#TODO: not sure about last field, ask.
function verify_file_format() {
  local file fields_in_file
  for f in "$DIROK"/*"csv"; do
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`"
    fields_in_file=$(head "$file" -n 1 | grep -o ";" | wc -l)
    fields_in_file+=1
    if [ fields_in_file -ne NUMBER_OF_FIELDS ]; then
      log_message "$BAD_FRMT_FILE $file" "TYPE_ERR"
      bash "$DIRBIN/Movep.sh" -c "Procep" -o "$DIROK/$file" -d "$DIRNOK"
    fi
  done
}

function main() {
  
  # 1. Verify if environment has been initialized
  check_previous_init
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  # 2. Count number of files in DIROK
  count_files $DIROK
  log_message "$CANT_TO_PROC $?" "$TYPE_INF"

  # 3. Create DIRPROC/proc if not created. fix me.
  if [ ! -e "$DIRPROC/proc" ]; then
    mkdir "$DIRPROC/proc"
  fi

  # 4. Check for duplicate files
  check_for_duplicates "$DIRPROC/proc"

  # 5. Verify file format
  verify_file_format

}

main