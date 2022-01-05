float cosh(float x) {
  float delta = 1.0;
  float res = 1.0;
  for (int i = 1; i < 10000; i++) {
    delta *= x / i;
    if (i % 2 == 0) res += delta;
    if (abs(delta / res) < 0.001) return res;
  }
  return res;
}
