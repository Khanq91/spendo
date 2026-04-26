class Transaction {
  final String id;
  final int amount;
  final String type;
  final String categoryId;
  final String? note;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.createdAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      amount: int.parse(map['amount'] as String),
      type: map['type'] as String,
      categoryId: map['category_id'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        int.parse(map['created_at'] as String),
      ),
    );
  }
}