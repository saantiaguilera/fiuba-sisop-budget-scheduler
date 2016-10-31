# EPLAM - Grupo 6

### Integrantes
* Agustina Barbetta (96528)
* Ana Czarnitzki (96812)
* Francisco Ordoñez (96478)
* Manuel Porto (96587)
* Santiago Aguilera (95795)

### Requerimientos para instalación/ejecución
* Sistema Operativo Linux
* Bash v4 o superior
* Perl v5.10.0 o superior

### Descarga del paquete
El paquete EPLAM-6.tar.gz se puede descargar desde el repositorio `https://github.com/saantiaguilera/fiuba-sisop-budget-scheduler`

### Instrucciones de instalación
* Descomprimir el paquete: `tar -zxf EPLAM-6.tar.gz`. A partir de esta descompresión, se creará dentro del directorio actual, un subdirectorio *EPLAM-6* en el cual se encuentra; *Grupo6/* (carpeta en donde realizará la instalación) con un subdirectorio *dirconf/* (que contendrá el archivo de configuración del sistema) y todos los .sh escritos y .csv provistos por la cátedra.
* `cd EPLAM-6`
* Otorgar permisos de ejecución a Installep: `chmod u+x Installep.sh`
* Ejecutar Installep: `. Installep.sh`
* Seguir los pasos de instalación indicados por salida estándar.

Esta instalación nos deja:
* Directorio de Configuración: Donde se econtrarán los archivos con las configuraciones predefinidas por el usuario.
* Directorio de Ejecutables: Donde se encontrarán los scripts a usar por el sistema y archivos duplicados en caso de ser generados.
* Directorio de Maestros y Tablas: Donde se encontrarán los assets a ser utilizados por el sistema.
* Directorio de Recepción de Novedades:  Donde se encontrarán las novedades a ser verificadas por el daemon.
* Directorio de Archivos Aceptados: Donde se encontrarán las novedades verificadas correctamente por el daemon.
* Directorio de Archivos Procesados: Donde se encontrarán las novedades procesadas por el Procep.
* Directorio de Archivos de Reportes: No hay.
* Directorio de Archivos de Log: Donde se encontrarán los logs producidos por cada script del sistema.
* Directorio de Archivos Rechazados: Donde se encontrarán las novedades verificadas incorrectamente por el daemon.

### Ejecución del sistema
Luego de la instalación, se debe ejecutar el comando Initep. El mismo creará las variables de entorno del sistema según la configuración indicada por el usuario durante la ejecución de Installep, verificará permisos y brindará indicaciones para la ejecución del comando Demonep.  
Para ejecutar Initep se debe utilizar el comando (En caso de haber hecho la instalación por default, de otro modo, el directorio será el elegido en la instalación): `. Grupo6/bin/Initep.sh` .  
Si desea limpiar las variables de entorno generadas por el sistema, simplemente cierre la terminal donde está trabajando actualmente.

### Ejecución y detención de comandos

#### Logep
Se ejecuta con `bash Logep.sh -c comando -m 'Mensaje' -t tipo de mensaje`

#### Demonep
Se ejecuta con `bash Demonep.sh &`  
Se detiene con `kill PID`. Para obtener el `PID` de Demonep.sh ejecute `pgrep Demonep`

#### Movep
Se ejecuta con `bash Movep.sh -c comando -o origen -d destino`

#### Procep
Se ejecuta con `bash Procep.sh`
Demonep.sh es el encargado de ejecutarlo.

#### Listep
Se ejecuta con `perl Listep.pl --[ejec|sanc|ctrl] -[ct|tc] -[act|act_all] -[trim|trim-all] -[cent|cent-all]`
