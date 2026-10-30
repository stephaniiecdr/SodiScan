import 'package:flutter_test/flutter_test.dart';
import 'package:sodiscan/core/utils/date_format.dart';

void main() {
  test('memformat tanggal dalam Bahasa Indonesia', () {
    expect(formatDateId(DateTime(2026, 10, 1)), 'Kamis, 1 Okt 2026');
    expect(formatDateId(DateTime(2026, 9, 27)), 'Minggu, 27 Sep 2026');
  });
}
