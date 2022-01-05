#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <assert.h>
#include <pthread.h>

typedef struct Matrix {
  int n;
  int m;
  double* mat;
} Matrix;

typedef struct MatrixThreadShuttle {
  Matrix* in;
  Matrix* out;
  int startIndex;
  int endIndex;
} MatrixThreadShuttle;

Matrix makeMatrix(int n, int m){
  Matrix r;
  r.n = n;
  r.m = m;
  r.mat = calloc(n*m*sizeof(double), 1);
  return r;
}

// печатает матрицу в JSON-подобном формате
void printMatrix(Matrix* m){
  printf("[\n");
  for(int i = 0; i < m->n; i++){
    printf("  [");
    for(int j = 0; j < m->m; j++){
      printf("%10.6g, ", m->mat[i*m->m + j]);
    }
    printf("],\n");
  }
  printf("]\n");
}

// находит минормую матрицу (делает копию)
Matrix minorMatrix(Matrix* m, int i_, int j_){
  Matrix matrix = makeMatrix(m->n - 1, m->n - 1);

  int i1 = 0;
  for(int i = 0; i < m->n; i++){
    if(i == i_)continue;
    int j1 = 0;
    for(int j = 0; j < m->m; j++){
      if(j == j_)continue;
      matrix.mat[i1*matrix.m + j1] = m->mat[i*m->m + j];
      j1++;
    }
    i1++;
  }

  return matrix;
}

// тут надо объявлять хедер для рекурсии
double det(Matrix* m);

// находит дополнительный минор
double minorDet(Matrix* m, int i, int j){
  Matrix t = minorMatrix(m, i, j);
  double r = det(&t);
  free(t.mat);
  return r;
}

// рекурсивно считаем определитель
double det(Matrix* m){
  assert(m->m == m->n);
  assert(m->n > 1);
  if(m->n == 2){
    return m->mat[0]*m->mat[3] - m->mat[1]*m->mat[2];
  }

  double r = 0;
  int delta = 1;
  for(int i = 0; i < m->m; i++){
    r += m->mat[i] * minorDet(m, 0, i) * delta;
    delta *= -1;
  }
  return r;
}

// находит алгебраическое дополнение
double adjunct(Matrix* m, int i, int j){
  return minorDet(m, i, j) * ((i+j) % 2? -1 : 1);
}

// считывает матрицу из файла
Matrix readMatrix(char* filename){
  FILE* file = fopen(filename, "r");
  if(!file){
    perror(filename);
    exit(1);
  }

  int n,m;
  fscanf(file, "%d %d", &n, &m);
  Matrix matrix = makeMatrix(n,m);
  for(int i = 0; i < n*m; i++){
    fscanf(file, "%lf", matrix.mat + i);
  }

  fclose(file);
  return matrix;
}

void* threadFunction(void* mts){
  MatrixThreadShuttle* args = mts;

  for(int i = args->startIndex; i < args->endIndex; i++){
    args->out->mat[i] = adjunct(args->in, i / args->in->m, i % args->in->m);
  }

  free(args);
  return NULL;
}

// тут мы просто упаковываем все аргументы в поток в void*
pthread_t makeThread(Matrix* in, Matrix* out, int i, int j){
  printf("starting thread from %d to %d\n", i, j);

  MatrixThreadShuttle* arg = malloc(sizeof(MatrixThreadShuttle));
  arg->startIndex = i;
  arg->endIndex = j;
  arg->in = in;
  arg->out = out;
  pthread_t res;
  pthread_create(&res, NULL, threadFunction, arg);
  return res;
}

pthread_t* makeThreads(int n, int m, int threadCount, Matrix* in, Matrix* out){
  pthread_t* threads = malloc(threadCount*sizeof(pthread_t));
  int threadIndex = 0;

  // тут мы пытаемся поровну распределить елементы матрицы по потокам
  double delta = n*m/(double)threadCount;
  double acc = 0;
  int i = -1;
  for(int j = 0; j < n*m; j++){
    acc += 1;
    if(acc >= delta){
      acc -= delta;
      threads[threadIndex++] = makeThread(in, out, i+1, j+1);
      i = j;
    }
  }
  // тут нам надо в конце проверять использовали ли мы все елементы
  if(i+1 != n*m){
    threads[threadIndex++] = makeThread(in, out, i+1, n*m);
  }

  return threads;
}

int main(int argc, char** argv){
  if(argc == 1){
    // формат командный строки для тех кому лень читать ПЗ
    fprintf(stderr, "./matrix numberOfThreads [infile]\n");
    return 1;
  }

  int threadCount = atoi(argv[1]);

  char* infile = "/dev/fd/0";
  if(argc > 2){
    infile = argv[2];
  }else{
    fprintf(stderr, "readring stdin...\n");
  }

  Matrix matrix = readMatrix(infile);
  if(matrix.n != matrix.m){
    fprintf(stderr, "we need a square matrix\n");
    free(matrix.mat);
    return 1;
  }else if(matrix.n > 10){
    fprintf(stderr, "this matrix is SO big.... and i think i cant handle it\n");
    free(matrix.mat);
    return 1;
  }
  Matrix outmatrix = makeMatrix(matrix.n, matrix.m);

  printf("Inputted matrix:\n");
  printMatrix(&matrix);
  printf("\n");

  if(threadCount > matrix.n*matrix.m){
    printf("we have a little too many threads; we cant use all of them a once\n");
    threadCount = matrix.n*matrix.m;
  }

  pthread_t* threads = makeThreads(matrix.n, matrix.m, threadCount, &matrix, &outmatrix);
  for(int i = 0; i < threadCount; i++){
    pthread_join(threads[i], NULL);
  }
  free(threads);

  printf("Resulting matrix:\n");
  printMatrix(&outmatrix);

  free(matrix.mat);
  free(outmatrix.mat);
  return 0;
}
