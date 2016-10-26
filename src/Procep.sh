MSG_ENV_NOT_INITIALIZED="Ambiente no inicializado, ejecute Initep.sh."
CANT_TO_PROC="Cantidad de archivos a procesar:"
DUPL_FILE_MSG="Archivo Duplicado. Se rechaza el archivo"
BAD_FRMT_FILE="Estructura inesperada. Se rechaza el archivo"
BAD_FRMT_REG="Estructura inesperada. Se rechaza el registro"
FL_TO_PROC="Archivo a procesar"
CANT_REG_TOT="Cantidad de registros leidos: "
CANT_REG_OK="Cantidad de registros ok: "
CANT_REG_ERR="Cantidad de registros con errores: "

TYPE_ERR="ERR"
TYPE_INF="INF"
TYPE_WAR="WAR"
NUMBER_OF_FIELDS=5


declare -A ERRORS=(["0"]="centro inexistente" 
  ["1"]="Actividad inexistente"
  ["2"]="Trimestre invalido"
  ["3"]="Fecha invalida"
  ["4"]="La fecha no se corresponde con el trimestre indicado"
  ["5"]="Importe invalido")

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
  for f in "$DIROK/"* ; do
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`" #TODO: arreglar esta negrada
    if [ -e  "$1"/"$file" ]; then
      log_message "$DUPL_FILE_MSG $file" "$TYPE_ERR"
      bash "$DIRBIN/Movep.sh" -c "Procep" -o "$f" -d "$DIRNOK"
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
function verify_file_format() {
  local file fields_in_file
  for f in "$DIROK/"* ; do
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`"
    fields_in_file=$(head "$f" -n 1)
    local res="${fields_in_file//[^;]}"
    if [ "${#res}" -ne "$NUMBER_OF_FIELDS" ]; then
      log_message "$BAD_FRMT_FILE $file." "$TYPE_ERR"
      bash "$DIRBIN/Movep.sh" -c "Procep" -o "$f" -d "$DIRNOK"
    fi
  done
}

function write_to_rejected() {
  echo "$1;$2" >> "$3".csv
}

function write_to_accepted() {
  echo "$1" >> "$2".csv
}

#######################################
#Validates that the center exists
# Globals:
#   DIRMAE
# Arguments:
#   File register
# Returns:
#   True or False
#######################################
function validate_center() {
  local center=$(echo "$1" | cut -d ";" -f 3)
  local result=$(grep -F "$center" "$DIRMAE/centros.csv")
  
  if [ "$result" ] ; then
    return 0 #True
  else
    reg_errors+="${ERRORS[0]}. "
    return 1 #False
  fi
}
#######################################
#Validates that the activity exists
# Globals:
#   DIRMAE
# Arguments:
#   File register
# Returns:
#   True or False
#######################################
function validate_activity() {
  local activity=$(echo "$1" | cut -d ";" -f 4)
  local result=$(grep -F "$activity" "$DIRMAE/actividades.csv")
  
  if [ "$result" ]; then
    return 0 #True
  else
    reg_errors+="${ERRORS[1]}. "
    return 1 #False
  fi
}

#######################################
#Validates the trimester
# Globals:
#   DIRMAE
# Arguments:
#   File register
# Returns:
#   True or False
#######################################
function validate_trimester() {
  local trimester=$(echo "$1" | cut -d ";" -f 5)
  local result=$(fgrep "$trimester" "$DIRMAE/trimestres.csv")
  
  if [ "$result" ]; then
    local year1=$(echo "$result" | cut -d ";" -f 1)
    local year2=$(echo "$trimester" | tail -c 5)
    if [ "$year1" -eq "$year2"  ]; then
      return 0 #True
    fi
  fi
  reg_errors+="${ERRORS[2]}. "
  return 1 #False
}

#######################################
#Validates the date
# Globals:
#   DIRMAE
# Arguments:
#   File register
# Returns:
#   True or False
#######################################
function validate_date() {
  local date=$(echo "$1" | cut -d ";" -f 2)
  local file_date=$(echo "$2" | cut -d "_" -f 4 | cut -d "." -f 1)

  if [ "$date" -le "$file_date" ]; then
    return 0 #True
  fi
  reg_errors+="${ERRORS[3]}. "
  return 1 #False
}

#######################################
#Validates that the date exists in the trimester
# Globals:
#   DIRMAE
# Arguments:
#   File register
# Returns:
#   True or False
#######################################
function validate_date_with_trimester() {
  local trimester result start finish day month year
  local date=$(echo "$1" | cut -d ";" -f 2)
  local file_date=$(echo "$2" | cut -d "_" -f 4 | cut -d "." -f 1)

  if [ "$date" -le "$file_date" ]; then
    trimester=$(echo "$1" | cut -d ";" -f 5)
    result=$(fgrep "$trimester" "$DIRMAE/trimestres.csv")

    start=$(echo "$result" | cut -d ";" -f 3)
    day=$(echo "$start" | cut -d "/" -f 1)
    month=$(echo "$start" | cut -d "/" -f 2)
    year=$(echo "$start" | cut -d "/" -f 3)
    start="$year$month$day" #ready for comparison

    finish=$(echo "$result" | cut -d ";" -f 4)
    day=$(echo "$finish" | cut -d "/" -f 1)
    month=$(echo "$finish" | cut -d "/" -f 2)
    year=$(echo "$finish" | cut -d "/" -f 3)
    finish="$year""$month""$day" #ready for comparison
    
    if [ -z "$finish" -o -z "$start" ]; then  #Both strings need to be non empty in order to continue
      reg_errors+="${ERRORS[4]}. "
      return 1 #False
    fi

    if [ "$date" -ge "$start" -a "$date" -le "$finish" ]; then
      return 0 #True
    fi
  fi
  reg_errors+="${ERRORS[4]}. "
  return 1 #False
}

#######################################
#Validates that the expenses >= 0
# Globals:
#   DIRMAE
# Arguments:
#   File register
# Returns:
#   True or False
#######################################
function validate_expenses() {
  local expenses=$(echo "$1" | cut -d ";" -f 6)
  #echo "$expenses"
  if [[ "$expenses" -ge 0 ]]; then
    return 0 #True
  else
    reg_errors+="${ERRORS[5]}. "
    return 1 #False
  fi
}

#######################################
#Iterates over all the files on DIROK and checks each register
# for errors, if found writes to rechazado-$year else ejecutado-year.
# Moves files to DIRPROC/proc.
# Globals:
#   DIRMAE DIROK DIRBIN DIRPROC
# Arguments:
#   None
# Returns:
#   None
#######################################
function process_files() {
  local file reg_val_ok lines year
  for f in "$DIROK/"* ; do
    reg_val_ok=0
    reg_val_err=0
    reg_val_tot=0
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`"
    local year=$(echo "$file" | cut -d "_" -f 2)
    log_message "$FL_TO_PROC $file." "$TYPE_INF"
    local cont=0
    while read -r reg; do
      let cont+=1
      let reg_val_tot+=1
      if [[ "$cont" -eq 1 ]]; then
        continue
      fi
      
      local fields_in_reg="${reg//[^;]}"
      if [ "${#fields_in_reg}" -eq "$NUMBER_OF_FIELDS" ]; then  #If there are 6 fields, validate them
        reg_errors=""
        validate_center "$reg"
        validate_activity "$reg"
        validate_trimester "$reg"
        validate_date "$reg" "$f"
        validate_date_with_trimester "$reg" "$f"
        validate_expenses "$reg"

        #Done validating, now lets check if we have any errors
        if [ ! -z "$reg_errors" ]; then   #If reg_errors isn't empty there are errors
          let reg_val_err+=1
          write_to_rejected "$reg" "$reg_errors" "$DIRPROC/rechazado-$year"
        else  #Reg was ok
          let reg_val_ok+=1
          write_to_accepted "$reg" "$DIRPROC/ejecutado-$year"
        fi
      else  #There are less than 6 fields, reject the register without checking each field
        let reg_val_err+=1
        write_to_rejected "$reg" "$BAD_FRMT_REG" "$DIRPROC/rechazado-$year"
      fi
    done < "$f"
    #After proccesing, file is moved
    bash "$DIRBIN/Movep.sh" -c "Procep" -o "$f" -d "$DIRPROC/proc"

    log_message "$CANT_REG_TOT $reg_val_tot" "$TYPE_INF"
    log_message "$CANT_REG_OK $reg_val_ok" "$TYPE_INF"
    log_message "$CANT_REG_ERR $reg_val_err" "$TYPE_INF"
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

  # 6. Validate fields
  process_files 
}

main

