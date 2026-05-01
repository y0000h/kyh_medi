import 'package:flutter_test/flutter_test.dart';
import 'package:kyh_medi/core/notification/notification_scheduler.dart';
import 'package:kyh_medi/features/parent/slot/domain/time_slot.dart';

void main() {
  group('NotificationIdEncoder', () {
    test('encodes slotIdHash × 1000 + day_offset × 10 + retry_index', () {
      expect(NotificationIdEncoder.encode(slotHash: 5, dayOffset: 1, retryIndex: 1), 5011);
      expect(NotificationIdEncoder.encode(slotHash: 1, dayOffset: 0, retryIndex: 0), 1000);
      expect(NotificationIdEncoder.encode(slotHash: 9, dayOffset: 6, retryIndex: 2), 9062);
    });

    test('idsForSlotInstance returns 3 IDs (retry 0/1/2)', () {
      final ids = NotificationIdEncoder.idsForSlotInstance(slotHash: 5, dayOffset: 1);
      expect(ids, [5010, 5011, 5012]);
    });

    test('hashSlotId is stable and bounded', () {
      final h1 = NotificationIdEncoder.hashSlotId('slot-uuid-1');
      final h2 = NotificationIdEncoder.hashSlotId('slot-uuid-1');
      expect(h1, h2);                       // 같은 입력 → 같은 출력
      expect(h1, lessThan(1000000));        // < 1M
      expect(h1, greaterThanOrEqualTo(0));
    });
  });

  group('NotificationScheduler.computeFireTimes', () {
    test('returns 3 fire times: scheduled, +10min, +20min', () {
      final base = DateTime(2026, 5, 1, 8, 0);
      final times = NotificationScheduler.computeFireTimes(base);
      expect(times, [
        DateTime(2026, 5, 1, 8, 0),
        DateTime(2026, 5, 1, 8, 10),
        DateTime(2026, 5, 1, 8, 20),
      ]);
    });

    test('next7DaysFor everyday returns 7 dates', () {
      final from = DateTime(2026, 5, 1);
      final all = NotificationScheduler.next7DaysFor(
        slot: TimeSlot(id: 'x', label: 'x', hour: 8, minute: 0, daysOfWeek: TimeSlot.everyday),
        from: from,
      );
      expect(all, hasLength(7));
    });

    test('next7DaysFor skips days not in bitmask', () {
      // 월(1) + 수(4) + 금(16) = 21
      final from = DateTime(2026, 5, 1); // 5/1은 금요일 (weekday=5)
      final result = NotificationScheduler.next7DaysFor(
        slot: TimeSlot(id: 'x', label: 'x', hour: 8, minute: 0, daysOfWeek: 21),
        from: from,
      );
      // 5/1 금, 5/4 월, 5/6 수 → 3개
      expect(result, hasLength(3));
    });
  });
}
