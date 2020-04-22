# Script para el ejercicio 2

#!/bin/bash

# compilar los ficheros
make clean
make

# inicializar variables
P=10 # P = (41 mod 7) + 4 = 6 + 4 = 10
Ninicio=$[2000+512*$P]
Nfinal=$[2000+512*($P+1)]
Npaso=64
cache=(1024 2048 4096 8192)
tamCache=8388608 # 8 MB = 2^23 B = 8388608
associativity=1
line_size=64
contador=0

echo -e "\nvalor de P: "$P
echo Inicio: $Ninicio
echo Final: $Nfinal
echo Tamaño de la cache de nivel superior: $tamCache

fLECTURA=cache_lectura.png
fESCRITURA=cache_escritura.png
fSLOW=slow_cachegrind.dat
fFAST=fast_cachegrind.dat

# borrar los ficheros DAT y los ficheros PNG
rm -f $fLECTURA $fESCRITURA *.dat

echo -e "\nRunning slow and fast for exercise 2 ... \n"

# bucle para N desde el numero inicial hasta el numero final
for ((N=$Ninicio ; N<=$Nfinal ; N+=$Npaso)); do
	echo "N: $N / $Nfinal..."
	# bucle para cada tamaño de la cache
	for ((i=0;i<${#cache[*]};i++)); do

		echo -e "\nTamaño de la cache de primer nivel = " ${cache[$i]}

		# ejecutamos la utilidad cachegrind de valgrind
		CACHEGRIND="valgrind --tool=cachegrind --LL="$tamCache","$associativity","$line_size" --I1="${cache[$i]}","$associativity","$line_size" --D1="${cache[$i]}","$associativity","$line_size""
		$CACHEGRIND --cachegrind-out-file=$fSLOW ./slow $N
		$CACHEGRIND --cachegrind-out-file=$fFAST ./fast $N

		# para el SLOW
		D1mr_slow[$contador]=$(cg_annotate $fSLOW | head -n 22 | grep 'PROGRAM TOTALS' | awk '{print $5}' | sed -e 's/,//g')
		D1mw_slow[$contador]=$(cg_annotate $fSLOW | head -n 22 | grep 'PROGRAM TOTALS' | awk '{print $8}' | sed -e 's/,//g')

		# para el FAST
		D1mr_fast[$contador]=$(cg_annotate $fFAST | head -n 22 | grep 'PROGRAM TOTALS' | awk '{print $5}' | sed -e 's/,//g')
		D1mw_fast[$contador]=$(cg_annotate $fFAST | head -n 22 | grep 'PROGRAM TOTALS' | awk '{print $8}' | sed -e 's/,//g')

		# Guardamos en el fichero cache_<tamCache>.dat los resultados obtenidos
		echo "$N ${D1mr_slow[$contador]} ${D1mw_slow[$contador]} ${D1mr_fast[$contador]} ${D1mw_fast[$contador]}" >> cache_${cache[$i]}.dat

		((contador++))
	done
done

echo "Generating plot 1: Fallos de lectura"
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Ejercicio 2 - Fallos de lectura de la cache"
set ylabel "Fallos"
set xlabel "Tamaño de la matriz"
set key right bottom
set grid
set term png
set output "$fLECTURA"
plot "cache_1024.dat" using 1:2 with lines lw 2 title "slow 1024", \
     "cache_1024.dat" using 1:4 with lines lw 2 title "fast 1024", \
		 "cache_2048.dat" using 1:2 with lines lw 2 title "slow 2048", \
		 "cache_2048.dat" using 1:4 with lines lw 2 title "fast 2048", \
		 "cache_4096.dat" using 1:2 with lines lw 2 title "slow 4096", \
		 "cache_4096.dat" using 1:4 with lines lw 2 title "fast 4096", \
		 "cache_8192.dat" using 1:2 with lines lw 2 title "slow 8192", \
		 "cache_8192.dat" using 1:4 with lines lw 2 title "fast 8192"
replot
quit
END_GNUPLOT

echo "Generating plot 2: Fallos de escritura"
# llamar a gnuplot para generar el gráfico y pasarle directamente por la entrada
# estándar el script que está entre "<< END_GNUPLOT" y "END_GNUPLOT"
gnuplot << END_GNUPLOT
set title "Ejercicio 2 - Fallos de escritura de la cache"
set ylabel "Fallos"
set xlabel "Tamaño de la matriz"
set key right bottom
set grid
set term png
set output "$fESCRITURA"
plot "cache_1024.dat" using 1:3 with lines lw 2 title "slow 1024", \
     "cache_1024.dat" using 1:5 with lines lw 2 title "fast 1024", \
		 "cache_2048.dat" using 1:3 with lines lw 2 title "slow 2048", \
		 "cache_2048.dat" using 1:5 with lines lw 2 title "fast 2048", \
		 "cache_4096.dat" using 1:3 with lines lw 2 title "slow 4096", \
		 "cache_4096.dat" using 1:5 with lines lw 2 title "fast 4096", \
		 "cache_8192.dat" using 1:3 with lines lw 2 title "slow 8192", \
		 "cache_8192.dat" using 1:5 with lines lw 2 title "fast 8192",
replot
quit
END_GNUPLOT

# eliminar ficheros temporales
rm -rf slow fast slow_cachegrind.dat fast_cachegrind.dat
