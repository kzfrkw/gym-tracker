// Epley式による推定1RM計算
double epley(double weight, int reps) {
  if (reps <= 0) return weight;
  return weight * (1 + reps / 30);
}

// 複数セットから推定1RMの最大値を返す。自重種目など対象外の場合は null
double? best1RM(Iterable<({double? weight, int reps})> sets) {
  return sets
      .where((s) => s.weight != null && s.weight! > 0 && s.reps > 0)
      .map((s) => epley(s.weight!, s.reps))
      .fold<double?>(null, (best, v) => best == null || v > best ? v : best);
}
