class Budget {
  final String id;
  final int amount;
  final String month; // "2026-04"

  const Budget({
    required this.id,
    required this.amount,
    required this.month,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      amount: int.parse(map['amount'] as String),
      month: map['month'] as String,
    );
  }

  static String monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
}