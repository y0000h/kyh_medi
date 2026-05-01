import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:kyh_medi/core/time/timezone_init.dart';

void main() {
  test('initializeTimezone sets local to Asia/Seoul', () {
    initializeTimezone();
    expect(tz.local.name, equals('Asia/Seoul'));
  });
}
