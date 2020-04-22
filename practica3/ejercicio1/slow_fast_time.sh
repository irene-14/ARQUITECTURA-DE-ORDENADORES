# Script para el ejercicio 1

#!/bin/bash

# compilar los ficheros
make clean
make

# inicializar variables
P=10 # P = (41 mod 7) + 4 = 6 + 4 = 10
Ninicio=$[10000+1024*$P]
Nfinal=$[10000+1024*($P+1)]
Npaso=64

echo valor de P: $P
echo Inicio: $Ninicio
echo Final: $Nfinal

fDAT=slow_fast_time.dat
fPNG=slow_fast_time.png

# borrar el fichero DAT y el fichero PNG
rm -f $fDAT $fPNG

# generar el fichero DAT vacío
touch $fDAT

echo ¿Cuántas repeticiones quiere realizar?
read Nreps

echo "Running slow and fast for exercise 1 ..."

# bucle para repetir las pruebas n veces
contadorPruebas=0

while [ $contadorPruebas -lt $Nreps ]; do

	echo "El contador es" $contadorPruebas

	# bucle para N desde el numero inicial hasta el numero final
	for ((N=$Ninicio ; N<=$Nfinal ; N+=$Npaso)); do
		echo "N: $N / $Nfinal..."
		# ejecutar los programas slow y fast consecutivamente con tamaño de matriz N
		# para cada uno, filtrar la línea que contiene el tiempo y seleccionar la
		# tercera columna (el valor del tiempo). Dejar los valores en variables
		# para poder imprimirlos en la misma línea del fichero de datos
		slowTime=$(./slow $N | grep 'time' | awk '{print $3}')
		fastTime=$(./fast $N | grep 'time' | awk '{print $3}')

		echo "$N	$slowTime	$fastTime" >> $fDAT
	done

	((contadorPruebas++)) # incrementamos en 1 el contador
done

# calcular la media y guardarla en un fichero
cat temp_rep_* > all.dat
awk -v Nrep="$Nreps" '{n_slow[$1] = n_slow[$1] + $2; n_fast[$1] = n_fast[$1] + $3;} END{for(valor in n_slow) print valor" "(n_slow[valor]/Nrep)" "(n_fast[valor]/Nrep);}' all.dat | sort -nk1

echo "Generating plot..."
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Ejercicio 1 - Tiempo de ejecución"
set ylabel "Tiempo de ejecución en segundos"
set xlabel "Tamaño de la matriz"
set key right bottom
set grid
set term png
set output "$fPNG"
plot "$fDAT" using 1:2 with lines lw 2 title "slow", \
     "$fDAT" using 1:3 with lines lw 2 title "fast"
replot
quit
END_GNUPLOT

# eliminar ficheros temporales
rm -rf slow fast all.dat temp_rep_*
