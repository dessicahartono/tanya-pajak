import 'package:flutter_test/flutter_test.dart';
import 'package:tanyapajak/data/topics.dart';

void main() {
  test('Ada 10 topik di beranda', () {
    expect(topics.length, 10);
  });
}
