import 'package:a3traf/core/utils/slot_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a unique priest-date-time id', () {
    final id = SlotId.build(
      priestId: 'p_botros',
      date: DateTime(2025, 9, 6),
      time: const TimeOfDayLike(17, 0),
    );
    expect(id, 'p_botros_20250906_1700');
  });

  test('pads hours and minutes', () {
    final id = SlotId.build(
      priestId: 'p_mina',
      date: DateTime(2025, 1, 2),
      time: const TimeOfDayLike(3, 5),
    );
    expect(id, 'p_mina_20250102_0305');
  });
}
