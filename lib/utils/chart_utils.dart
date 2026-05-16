// Y軸グリッドの見やすい間隔を返す
double niceYInterval(double range) {
  if (range <= 0) return 5;
  if (range <= 10) return 2.5;
  if (range <= 30) return 5;
  return 10;
}

// X軸ラベルの間隔をデータ数に応じて返す
double bottomXInterval(int count) {
  if (count <= 6) return 1;
  if (count <= 12) return 2;
  return (count / 6).ceilToDouble();
}
