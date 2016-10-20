MSG_ENV_NOT_INITIALIZED="Ambiente no inicializado, ejecute Initep.sh."
CANT_TO_PROC="Cantidad de archivos a procesar:"
DUPL_FILE_MSG="Archivo Duplicado. Se rechaza el archivo"
BAD_FRMT_FILE="Estructura inesperada. Se rechaza el archivo"
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
  local result=$(grep -Fq "$center" "$DIRMAE/centros.csv")
  
  if [ "$result" ] ; then
    return 0 #True
  else
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
  local result=$(grep -Fq "$activity" "$DIRMAE/actividades.csv")
  
  if [ "$result" ]; then
    return 0 #True
  else
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
  local result=$(grep -Fq "$trimester" "$DIRMAE/trimestres.csv")
  
  if [ "$result" ]; then
    local year1=$(echo "$result" | cut -d ";" -f 1)
    local year2=$(echo "$trimester" | tail -c 4)
    if [ "$year1" -eq "$year2"  ]; then
      return 0 #True
    fi
  fi
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
    result=$(grep -F "$trimester" "$DIRMAE/trimestres.csv")

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
    if [ "$date" -ge "$start" -a "$date" -le "$finish" ]; then
      return 0 #True
    fi
  fi
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
  #local result="`echo "$expenses" > 0 | bc -l)`"
  #echo "$result"
  if [[ "$expenses" -ge 0 ]]; then
    return 0 #True
  else
    return 1 #False
  fi
}

#######################################
#Checks if there are any errors in the register
# Globals:
#   DIRMAE ERRORS
# Arguments:
#   array of possible errors
# Returns:
#   True or False
#######################################
function look_for_errors() {
  local let index=0
  local error_found=0
  for i in "${arr[@]}"; do
    if [ "$i" -eq 1 ]; then
      reg_errors+="${ERRORS[$index]}. "
      error_found=1
    fi
    let reg_val_ok+=1
    let index+=1
  done
  if [ "$error_found" -eq 0 ]; then
    return 0 #True
  else
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
function validate_fields() {
  local file reg_val_ok lines year
  for f in "$DIROK/"* ; do
    reg_val_ok=0
    reg_val_err=0
    reg_val_tot=0
    file="`echo "$f" | rev | cut -d "/" -f 1 | rev`"
    log_message "$FL_TO_PROC $file." "$TYPE_INF"
    lines=$(wc -l < $file)
    local i=0
    while read -r reg; do
      let i+=1
      if [ "$i" -eq 1 ]; then
        continue
      fi
      reg_errors=""
      arr=()
      let reg_val_tot+=6
      validate_center "$reg"
      arr+=("$?")
      validate_activity "$reg"
      arr+=("$?")
      validate_trimester "$reg"
      arr+=("$?")
      validate_date "$reg" "$f"
      arr+=("$?")
      validate_date_with_trimester "$reg" "$f"
      arr+=("$?")
      validate_expenses "$reg"
      arr+=("$?")
      #Done validating, now lets check if we have any errors
      look_for_errors
      local year=$(echo "$file" | cut -d "_" -f 2)
      if [ "$?" -eq 1 ]; then #There was an error
        let reg_val_err+=1
        write_to_rejected "$reg" "$reg_errors" "$DIRPROC/rechazado-$year"
      else  #Reg was ok
        write_to_accepted "$reg" "$DIRPROC/ejecutado-$year"
      fi
    done < "$f" #tail -n "$lines" "$file"
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
  validate_fields 
}

main
