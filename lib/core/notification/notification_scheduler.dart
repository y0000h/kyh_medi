import '../../features/parent/slot/domain/time_slot.dart';

class NotificationIdEncoder {
  /// slotId(UUID 문자열) → 0~999_999 범위의 안정적 정수 해시
  static int hashSlotId(String slotId) {
    int h = 0;
    for (final c in slotId.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return h % 1000000;
  }

  static int encode({
    required int slotHash,
    required int dayOffset,
    required int retryIndex,
  }) {
    assert(slotHash >= 0 && slotHash < 1000000);
    assert(dayOffset >= 0 && dayOffset < 100);
    assert(retryIndex >= 0 && retryIndex < 10);
    return slotHash * 1000 + dayOffset * 10 + retryIndex;
  }

  static List<int> idsForSlotInstance({
    required int slotHash,
    required int dayOffset,
  }) {
    final base = encode(slotHash: slotHash, dayOffset: dayOffset, retryIndex: 0);
    return [base, base + 1, base + 2];
  }
}

class NotificationScheduler {
  static const retryOffsetsMinutes = [0, 10, 20];

  static List<DateTime> computeFireTimes(DateTime base) {
    return retryOffsetsMinutes.map((m) => base.add(Duration(minutes: m))).toList();
  }

  static List<DateTime> next7DaysFor({
    required TimeSlot slot,
    required DateTime from,
  }) {
    final result = <DateTime>[];
    for (int offset = 0; offset < 7; offset++) {
      final d = from.add(Duration(days: offset));
      // weekday: 월=1 ~ 일=7. 비트마스크: 월=1, 화=2, 수=4, 목=8, 금=16, 토=32, 일=64
      final bit = 1 << (d.weekday - 1);
      if ((slot.daysOfWeek & bit) != 0) {
        result.add(DateTime(d.year, d.month, d.day, slot.hour, slot.minute));
      }
    }
    return result;
  }
}
