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

for CURRENT_FILE in $FILESDIR/*
	do
		echo "Archivo detectado: $CURRENT_FILE"

		#Step4, check its a text file
		MIME_TYPE=($(file -i "$CURRENT_FILE" | cut -d' ' -f2)) #Get the info from the current file, pipe it to the stdin of cut and extract the second field delimited by a space

		if ! [ $MIME_TYPE == text/* ] && ! [ $MIME_TYPE == regular ]
			then
				echo "Archivo rechazado, motivo: no es un archivo de texto"
				exit 1 #Later see to where send him if it fails
		fi

		#Step5, check the file has size >0

		if ! [ -s $CURRENT_FILE ]
			then 
				echo "Archivo rechazado, motivo: archivo vacio"
				exit 1 #Same
		fi

		#Step6, check the format of the file is 'ejecutado_:year_:provcode_:yyyy:mm:dd.csv

		local DATE=`date +%y`
		#The regex currently checks the mm/dd as 2 digits, which can be day 62. Fix this TODO
		if ! [ $CURRENT_FILE =~ ^ejecutado_($DATE)_([3-9]|1[0-9]?|2[0-4]?)_$DATE\/[\d]{1,2}\/[\d]{1,2}\.csv$ ]
			then
				echo "Archivo rechazado, motivo: formato de nombre incorrecto"
				
				#Step7

				if [ $CURRENT_FILE =~ ^ejecutado_(^$DATE).* ]
					then
						echo "Archivo rechazado, motivo: a;o ${BASH_REMATCH[1]} incorrecto."
				fi

				#Step8

				if [ $CURRENT_FILE =~ ^ejecutado_($DATE)_^([3-9]|1[0-9]?\2[0-4]?).* ]
					then
						echo "Archivo rechazado, motivo: provincia ${BASH_REMATCH[2]} incorrecta."
				fi

				#Step9

				#TODO

		fi

done
