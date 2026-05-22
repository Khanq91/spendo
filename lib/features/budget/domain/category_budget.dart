class CategoryBudget {
  final String id;
  final String categoryId;
  final int amount;

  const CategoryBudget({
    required this.id,
    required this.categoryId,
    required this.amount,
  });

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: int.parse(map['amount'] as String),
    );
  }
}