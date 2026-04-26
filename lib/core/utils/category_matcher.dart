/// Map keyword → icon_name của category.
/// icon_name dùng để match với category trong DB thay vì hardcode id.
const _rules = <String, String>{
  // Ăn uống
  'ăn': 'restaurant', 'uống': 'restaurant', 'cơm': 'restaurant',
  'bún': 'restaurant', 'phở': 'restaurant', 'bánh': 'restaurant',
  'trà': 'restaurant', 'cafe': 'restaurant', 'cà phê': 'restaurant',
  'coffee': 'restaurant', 'bò': 'restaurant', 'gà': 'restaurant',
  'lẩu': 'restaurant', 'pizza': 'restaurant', 'burger': 'restaurant',
  'sushi': 'restaurant', 'kem': 'restaurant', 'chè': 'restaurant',
  'nước': 'restaurant', 'beer': 'restaurant', 'bia': 'restaurant',
  'milk tea': 'restaurant', 'trà sữa': 'restaurant',

  // Di chuyển
  'grab': 'directions_car', 'taxi': 'directions_car', 'xe': 'directions_car',
  'xăng': 'directions_car', 'petrol': 'directions_car', 'bus': 'directions_car',
  'xe buýt': 'directions_car', 'uber': 'directions_car', 'gojek': 'directions_car',
  'be ': 'directions_car', 'bãi xe': 'directions_car', 'vé': 'directions_car',
  'tàu': 'directions_car', 'máy bay': 'directions_car', 'parking': 'directions_car',

  // Học tập
  'học': 'school', 'khóa': 'school', 'sách': 'school', 'course': 'school',
  'udemy': 'school', 'coursera': 'school', 'trường': 'school',
  'học phí': 'school', 'văn phòng phẩm': 'school', 'bút': 'school',

  // Giải trí
  'game': 'sports_esports', 'phim': 'sports_esports', 'cinema': 'sports_esports',
  'cgv': 'sports_esports', 'lotte': 'sports_esports', 'karaoke': 'sports_esports',
  'spotify': 'sports_esports', 'netflix': 'sports_esports', 'youtube': 'sports_esports',
  'steam': 'sports_esports', 'billiard': 'sports_esports', 'bida': 'sports_esports',

  // Sức khoẻ
  'thuốc': 'favorite', 'bệnh viện': 'favorite', 'khám': 'favorite',
  'gym': 'favorite', 'spa': 'favorite', 'vitamin': 'favorite',
  'pharmacy': 'favorite', 'nhà thuốc': 'favorite', 'bác sĩ': 'favorite',

  // Mua sắm
  'shopee': 'shopping_bag', 'lazada': 'shopping_bag', 'tiki': 'shopping_bag',
  'quần': 'shopping_bag', 'áo': 'shopping_bag', 'giày': 'shopping_bag',
  'túi': 'shopping_bag', 'mua': 'shopping_bag', 'siêu thị': 'shopping_bag',
  'vinmart': 'shopping_bag', 'coopmart': 'shopping_bag', 'điện thoại': 'shopping_bag',
  'laptop': 'shopping_bag',
};

/// Trả về icon_name match với note, hoặc null nếu không match.
String? matchCategory(String note) {
  if (note.trim().isEmpty) return null;
  final lower = note.toLowerCase();

  // Ưu tiên match cụm từ dài trước (tránh "bò" match trước "bún bò")
  final sorted = _rules.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final keyword in sorted) {
    if (lower.contains(keyword)) {
      return _rules[keyword];
    }
  }
  return null;
}