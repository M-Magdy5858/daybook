enum Priority {
  low(1),
  medium(2),
  high(3);

  const Priority(this.weight);

  /// Used for sorting: higher comes first.
  final int weight;
}
