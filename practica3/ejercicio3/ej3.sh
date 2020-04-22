# Script para el ejercicio 3

#!/bin/bash

# compilar los ficheros
make clean
make

# inicializar variables
P=10 # P = (41 mod 7) + 4 = 6 + 4 = 10
Ninicio=$[256+256*$P]
Nfinal=$[256+256*($P+1)]
Npaso=16 # incremento en saltos de 16 unidades

echo -e "\nvalor de P: "$P
echo Inicio: $Ninicio
echo Final: $Nfinal
echo Valor del paso: $Npaso

fMULT=mult.dat
fCACHE=mult_cache.png # grafica con los fallos de cache
fTIME=mult_time.png # grafica con el tiempo de ejecucion

# borrar los ficheros DAT y los ficheros PNG
rm -f *.png *.dat *.txt

# generar el fichero DAT vacío
touch $fMULT

echo ¿Cuántas repeticiones quiere realizar?
read Nreps

echo -e "\nRunning exercise 3 ... \n"

echo -e "\n1. Calculando tiempos de ejecución ... \n"

# bucle para repetir las pruebas n veces
contadorPruebas=0

while [ $contadorPruebas -lt $Nreps ]; do

	echo "El contador es" $contadorPruebas

	# bucle para N desde el numero inicial hasta el numero final
	for ((N=$Ninicio ; N<=$Nfinal ; N+=$Npaso)); do
		echo "N: $N / $Nfinal..."

		mult_tiempo=$(./mult $N | grep 'time' | awk '{print $2}')
		mult_trans_tiempo=$(./mult_trans $N | grep 'time' | awk '{print $2}')
		echo "$N $mult_tiempo $mult_trans_tiempo" >> tiempo.txt
	done
	((contadorPruebas++)) # incrementamos en 1 el contador
done

echo -e "\n2. Calculando fallos de caché ... \n"

# bucle para N desde el numero inicial hasta el numero final
for ((N=$Ninicio ; N<=$Nfinal ; N+=$Npaso)); do
	echo "N: $N / $Nfinal..."

	valgrind -q --tool=cachegrind --cachegrind-out-file=mult.txt ./mult $N > valgrind.txt
	valgrind -q --tool=cachegrind --cachegrind-out-file=mult_trans.txt ./mult_trans $N > valgrind.txt

	# para la multiplicacion normal
	D1mr_mult=$(cg_annotate mult.txt | grep 'PROGRAM TOTALS' | awk '{print $5}' | tr -d ',')
	D1mw_mult=$(cg_annotate mult.txt | grep 'PROGRAM TOTALS' | awk '{print $8}' | tr -d ',')

	# para la multiplicacion transpuesta
	D1mr_mult_trans=$(cg_annotate mult_trans.txt | grep 'PROGRAM TOTALS' | awk '{print $5}' | tr -d ',')
	D1mw_mult_trans=$(cg_annotate mult_trans.txt | grep 'PROGRAM TOTALS' | awk '{print $8}' | tr -d ',')

	# Guardamos en el fichero mult.dat los resultados obtenidos
	grep "^$N" tiempo.txt | awk -v nP=$Nreps -v n=$N -v D1mr=$D1mr_mult -v D1mw=$D1mw_mult -v D1mr_t=$D1mr_mult_trans -v D1mw_t=$D1mw_mult_trans '{t=t+$2;t=t+$3}END{print n"	"t/nP"	"D1mr"	"D1mw"	"t/nP"	"D1mr_t"	"D1mw_t}' >> $fMULT

done

echo "Generating plot 1: Fallos de cache"
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Ejercicio 3 - Fallos de cache"
set ylabel "Fallos"
set xlabel "Tamaño de la matriz"
set key right bottom
set grid
set term png
set output "$fCACHE"
plot "$fMULT" using 1:3 with lines lw 2 title "lectura normal", \
     "$fMULT" using 1:6 with lines lw 2 title "lectura transpuesta", \
		 "$fMULT" using 1:4 with lines lw 2 title "escritura normal", \
		 "$fMULT" using 1:7 with lines lw 2 title "escritura transpuesta"
replot
quit
END_GNUPLOT

echo "Generating plot 2: Tiempo de ejecución"
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Ejercicio 3 - Tiempo de ejecución"
set ylabel "Tiempo de ejecución (s)"
set xlabel "Tamaño de la matriz"
set key right bottom
set grid
set term png
set output "$fTIME"
plot "$fMULT" using 1:2 with lines lw 2 title "normal", \
		 "$fMULT" using 1:5 with lines lw 2 title "transpuesta"
replot
quit
END_GNUPLOT

# eliminar ficheros temporales
rm -rf mult mult_trans #*.txt
