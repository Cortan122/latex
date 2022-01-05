float64_t x = 0;
float64_t tmpFactorial = 0;
float64_t tmpPow = 0;
float64_t tmpSquare = 0;
float64_t chres = 0;
float64_t prevchres = 0;

void hyperbolicCosine() {
  tmpSquare = tmpPow = x * x;
  chres = 1.0;
  tmpFactorial = 2.0;

  for (int i = 3; i < 10000;) {
    chres += tmpPow / tmpFactorial;

    if (chres == ∞) {
      chres = prevchres;
      return;
    }
    if (chres == prevchres) return;
    prevchres = chres;

    tmpPow *= tmpSquare;
    tmpFactorial *= i++;
    tmpFactorial *= i++;
  }
}
