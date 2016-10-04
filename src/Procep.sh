MSG_ENV_NOT_INITIALIZED="Ambiente no inicializado, ejecute Initep.sh."
CANT_TO_PROC="Cantidad de archivos a procesar:"
DUPL_FILE_MSG="Archivo Duplicado. Se rechaza el archivo "

TYPE_ERR="ERR"
TYPE_INF="INF"
TYPE_WAR="WAR"

function log_message() {
  bash "$DIRBIN/Logep.sh" -c "Procep" -m "$1" -t "$2"
}

function check_previous_init(){
  EXIT_CODE=0
  if [ ${ENV-0} -ne 1 ]; then
      echo "$MSG_ENV_NOT_INITIALIZED"
      EXIT_CODE=1
  fi
  
return $EXIT_CODE
}

function count_files() {
  return $(ls -1 $1 | wc -l)
}

function check_for_duplicates() {
  for f in "$1"/*".csv"; do
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`" #TODO: arreglar esta negrada
    if [ -e  "$2"/"$file" ]; then
      log_message "$DUPL_FILE_MSG $f" "TYPE_ERR"
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

  # 3. Create DIRPROC/proc if not created, make this prettier
  if [ ! -e "$DIRPROC/proc" ]; then
    mkdir "$DIRPROC/proc"
  fi

  # 4. Check for duplicate files
  check_for_duplicates "$DIROK" "$DIRPROC/proc"

  # 5. Verify file format
  #verify_file_format "$DIROK"

}

main