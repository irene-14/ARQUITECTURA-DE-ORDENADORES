// Este programa realiza la multiplicacion traspuesta entre dos matrices
// e imprime el resultado por pantalla.

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "arqo3.h"

void mult_trans (tipo **m1, tipo **m2, tipo **m, int tam) {
	int i = 0, j = 0, k = 0;

	for (i = 0; i < tam; i++) {
		for (j = 0; j < tam; j++) {
			m[i][j] = 0;
			for (k = 0; k < tam; k++) m[i][j] += m1[i][k] * m2[k][j];
		}
	}
}

void calculate_trans (tipo **original, tipo **transpuesta, int tam) {
  int i = 0, j = 0;

  for (i = 0; i < tam; i++) {
    for (j = 0; j < tam; j++) transpuesta[j][i] = original[i][j];
  }
}

int main (int argc, char *argv[]) {

	int N = 0;
	struct timeval t_ini, t_fin;
	tipo **matrix1 = NULL;
  tipo **matrix2 = NULL;
  tipo **matrix2_trans = NULL;
  tipo **matrix = NULL;

	if (argc != 2) {
		printf("\nDebe introducir el tamaño de matriz como argumento\n\n");
		return -1;
	} else N = atoi(argv[1]); /* Guardamos el tamaño leido de teclado.*/


	/* Inicializamos las dos matrices que vamos a multiplicar.*/
	matrix1 = generateMatrix(N);
  matrix2 = generateMatrix(N);

  /* Inicializamos la matriz transpuesta vacía.*/
	matrix2_trans = generateEmptyMatrix(N);

	/* Inicializamos la matriz resultado vacía.*/
	matrix = generateEmptyMatrix(N);

  /* SE EMPIEZA A MEDIR EL TIEMPO.*/
	gettimeofday(&t_ini,NULL);

  /* Calculamos la matriz transpuesta de B.*/
  calculate_trans(matrix2, matrix2_trans, N);

	/* Realizamos la multiplicación de las matrices.*/
	mult_trans(matrix1, matrix2_trans, matrix, N);

  /* SE DEJA DE MEDIR EL TIEMPO.*/
	gettimeofday(&t_fin,NULL);

	/* Imprimimos el tiempo de ejecucion.*/
	printf("time: %f\n", ((t_fin.tv_sec*1000000+t_fin.tv_usec)-(t_ini.tv_sec*1000000+t_ini.tv_usec))*1.0/1000000.0);

	freeMatrix(matrix1);
  freeMatrix(matrix2);
  freeMatrix(matrix2_trans);
  freeMatrix(matrix);
	return 0;
}
