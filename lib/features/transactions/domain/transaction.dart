class Transaction {
  final String id;
  final int amount;
  final String type;
  final String categoryId;
  final String? note;
  final DateTime createdAt;
  final String? walletId;
  final String source; // 'manual' | 'sepay'

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.note,
    required this.createdAt,
    this.walletId,
    this.source = 'manual',
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isAutomatic => source == 'sepay';

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
      walletId: map['wallet_id'] as String?,
      source: map['source'] as String? ?? 'manual',
    );
  }
}
