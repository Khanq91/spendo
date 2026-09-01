import '../../../core/db/powersync_db.dart';

/// Starter notes per category icon, used until a category has a history.
const kDefaultNotes = <String, List<String>>{
  'restaurant': [
    'Ăn sáng',
    'Ăn trưa',
    'Ăn tối',
    'Cà phê',
    'Trà sữa',
    'Đi ăn',
    'Bia',
    'Đặt đồ ăn',
  ],
  'directions_car': ['Xăng xe', 'Grab', 'Taxi', 'Gửi xe', 'Sửa xe', 'Gojek', 'Be'],
  'school': [
    'Học phí',
    'Sách giáo khoa',
    'Khóa học online',
    'Văn phòng phẩm',
    'Udemy',
  ],
  'shopping_bag': [
    'Shopee',
    'Lazada',
    'Tiki',
    'Siêu thị',
    'Quần áo',
    'Giày dép',
    'Mỹ phẩm',
  ],
  'favorite': ['Thuốc', 'Khám bệnh', 'Gym', 'Spa', 'Vitamin', 'Bệnh viện'],
  'sports_esports': [
    'Netflix',
    'Spotify',
    'Game',
    'Phim rạp',
    'CGV',
    'Karaoke',
    'Steam',
  ],
  'work': ['Lương tháng', 'Thưởng', 'Lương thưởng', 'Phụ cấp'],
  'laptop': ['Freelance', 'Dự án', 'Hợp đồng', 'Thu nhập thêm'],
  'storefront': ['Bán hàng', 'Doanh thu', 'Hàng bán được'],
  'card_giftcard': ['Quà sinh nhật', 'Tiền mừng', 'Quà tặng', 'Lì xì'],
  'home': ['Tiền nhà', 'Điện', 'Nước', 'Internet', 'Sửa nhà'],
  'flight': ['Vé máy bay', 'Khách sạn', 'Du lịch', 'Visa'],
  'movie': ['Phim', 'Rạp chiếu', 'Streaming'],
  'fitness_center': ['Gym', 'Thể dục', 'Yoga', 'Chạy bộ'],
  'pets': ['Thức ăn thú cưng', 'Thú y', 'Phụ kiện thú cưng'],
  'more_horiz': ['Chi tiêu khác', 'Linh tinh', 'Khác'],
};

/// The notes already written against [categoryId], most used first.
///
/// Returns an empty list rather than throwing when the query fails: a missing
/// suggestion is a non-event, and the caller has defaults to fall back on.
Future<List<String>> loadNoteHistory(String categoryId) async {
  try {
    final rows = await db.getAll(
      'SELECT note, COUNT(*) as cnt FROM transactions '
      "WHERE category_id = ? AND note IS NOT NULL AND note != '' "
      'GROUP BY note ORDER BY cnt DESC LIMIT 20',
      [categoryId],
    );
    return rows.map((r) => r['note'] as String).toList();
  } catch (_) {
    return const [];
  }
}

/// History first (what this user actually writes), then the starter notes,
/// deduplicated case-insensitively and filtered by [query].
List<String> mergeNoteSuggestions({
  required List<String> history,
  required String? iconName,
  String query = '',
}) {
  final defaults = iconName == null
      ? const <String>[]
      : (kDefaultNotes[iconName] ?? const <String>[]);

  final merged = <String>[];
  final seen = <String>{};
  for (final note in [...history, ...defaults]) {
    if (seen.add(note.toLowerCase())) merged.add(note);
  }

  final needle = query.toLowerCase().trim();
  if (needle.isEmpty) return merged;
  return merged.where((s) => s.toLowerCase().contains(needle)).toList();
}
