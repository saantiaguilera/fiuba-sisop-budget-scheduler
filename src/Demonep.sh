#!/bin/bash

#For testing purposes:
export GRUPO="Grupo5"
#----
FILESDIR="$GRUPO/DIRREC"

#Step1, check the env is running

if ! [ pgrep "my_program" >/dev/null ]
	then
		echo "El entorno no se encuentra en ejecucion. Para correr el daemon es necesario tener un entorno activo"
		exit 1;
fi

#Step2, save a cycle counter

CICLE_COUNT=1

#Step3, Check if there are files at the dir.

for current_file in $FILESDIR/*
	do
		echo "Archivo detectado: $current_file"

		#Step4, check its a text file
		mime_type=($(file -i "$current_file" | cut -d' ' -f2)) #Get the info from the current file, pipe it to the stdin of cut and extract the second field delimited by a space

		if ! [ $mime_type == text/* ] && ! [ $mime_type == regular ]
			then
				echo "Archivo rechazado, motivo: no es un archivo de texto"
				exit 1 #Later see to where send him if it fails
		fi

		#Step5, check the file has size >0

		if ! [ -s $current_file ]
			then 
				echo "Archivo rechazado, motivo: archivo vacio"
				exit 1 #Same
		fi

		#Step6, check the format of the file is 'ejecutado_:year_:provcode_:yyyy:mm:dd.csv

		#TODO

done
