import 'package:flutter_test/flutter_test.dart';
import 'package:spendo/core/utils/export_service.dart';

void main() {
  group('fileSlug', () {
    test('strips Vietnamese marks and joins words with underscores', () {
      expect(fileSlug('Ví tiền mặt'), 'vi_tien_mat');
      expect(fileSlug('Thẻ Techcombank'), 'the_techcombank');
      expect(fileSlug('Đầu tư — ổn định'), 'dau_tu_on_dinh');
      expect(fileSlug('Ưu đãi ếch ộp ỹ'), 'uu_dai_ech_op_y');
    });

    test('never comes back empty, and never runs long', () {
      expect(fileSlug('   '), 'vi');
      expect(fileSlug('★★★'), 'vi');
      expect(fileSlug('a' * 40).length, 24);
    });
  });
}
