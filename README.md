# EPLAM
## Grupo 6
---

### Integrantes
* Agustina Barbetta (96528)
* Ana Czarnitzki (96812)
* Francisco Ordoñez (96478)
* Manuel Porto (96587)
* Santiago Aguilera (95795)

### Requerimientos para instalación/ejecución
* Sistema Operativo Linux
* Bash v4 o superior

### Descarga del paquete
El paquete EPLAM.tar.gz se puede descargar desde el repositorio `https://github.com/saantiaguilera/fiuba-sisop-budget-scheduler`

### Instrucciones de instalación
* Descomprimir el instalador: `tar -zxf EPLAM.tar.gz`. A partir de esta descompresión, se creará dentro del directorio actual, un subdirectorio *EPLAM-6* en el cual se encuentra; bin/ carpeta con los .sh escritos, mae/ carpeta con los archivos maestros provistos por la cátedra, nov/ carpeta con los archivos novedades provistos por la cátedra.
* `cd EPLAM-6`
* Otorgar permisos de ejecución a Installep: `chmod u+x Installep.sh`
* Ejecutar Installep: `. Installep.sh`
* Seguir los pasos de instalación indicados por salida estándar

Esta instalación nos deja: *COMPLETAR*
* Directorio de Configuración:
* Directorio de Ejecutables: 
* Directorio de Maestros y Tablas:
* Directorio de Recepción de Novedades: 
* Directorio de Archivos Aceptados:
* Directorio de Archivos Procesados: 
* Directorio de Archivos de Reportes:
* Directorio de Archivos de Log:
* Directorio de Archivos Rechazados: 

### Ejecución del sistema
Luego de la instalación, se debe ejecutar el comando Initep. El mismo creará las variables de entorno del sistema según la configuración indicada por el usuario durante la ejecución de Instalep, verificará permisos y brindará indicaciones para la ejecución del comando Demonep.
Para ejecutar Initep se debe utilizar el comando: `. Initep.sh` 

### Ejecución y detención de comandos
#### Installep
Se ejecuta con `bash Installep.sh`

#### Initep
Se ejecuta con `bash Initep.sh`

#### Logep
Se ejecuta con `bash Logep.sh -c comando -m 'Mensaje' -t tipo de mensaje`

#### Demonep
Se ejecuta con `bash Demonep.sh &`
Se detiene con *COMPLETAR*

#### Movep
Se ejecuta con *COMPLETAR*

### Aclaraciones
* El comando Initep se debe correr una única vez por sesión.
*COMPLETAR*
