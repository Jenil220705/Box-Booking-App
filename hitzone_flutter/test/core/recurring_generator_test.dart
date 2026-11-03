import 'package:flutter_test/flutter_test.dart';
import 'package:hitzone_flutter/core/utils/recurring_generator.dart';

// 2026-11-03 is a Tuesday; 2026-11-01 a Sunday.
List<String> gen(String start, List<int> days, int weeks) =>
    RecurringGenerator.generate(startDate: start, days: days, weeks: weeks);

void main() {
  test('single weekday on a later day of the week', () {
    // First Monday on/after Tue 3 Nov is 9 Nov.
    expect(gen('2026-11-03', [1], 3), [
      '2026-11-09',
      '2026-11-16',
      '2026-11-23',
    ]);
  });

  test('start date on the selected weekday is included', () {
    expect(gen('2026-11-03', [2], 3), [
      '2026-11-03',
      '2026-11-10',
      '2026-11-17',
    ]);
  });

  test('Sunday is day 0', () {
    expect(gen('2026-11-01', [0], 2), ['2026-11-01', '2026-11-08']);
    expect(gen('2026-11-03', [0], 1), ['2026-11-08']);
  });

  test('multiple days are generated week by week in selection order', () {
    expect(gen('2026-11-03', [2, 4], 2), [
      '2026-11-03',
      '2026-11-05',
      '2026-11-10',
      '2026-11-12',
    ]);
    expect(gen('2026-11-03', [4, 2], 1), ['2026-11-05', '2026-11-03']);
  });

  test('Mon + Wed for 4 weeks creates 8 bookings (README example)', () {
    expect(gen('2026-11-02', [1, 3], 4), hasLength(8));
  });

  test('count is days x weeks', () {
    expect(gen('2026-11-03', [0, 1, 2, 3, 4, 5, 6], 52), hasLength(364));
  });

  test('crosses month and year boundaries', () {
    // Wed 30 Dec 2026 -> next Sunday is 3 Jan 2027.
    expect(gen('2026-12-30', [0], 2), ['2027-01-03', '2027-01-10']);
  });

  test('handles leap-day February', () {
    // Mon 28 Feb 2028 -> weekly Mondays across the leap day.
    expect(gen('2028-02-28', [1], 2), ['2028-02-28', '2028-03-06']);
    expect(gen('2028-02-26', [2], 1), ['2028-02-29']);
  });

  test('duplicate weekdays produce no duplicate dates', () {
    expect(gen('2026-11-03', [2, 2, 2], 2), ['2026-11-03', '2026-11-10']);
  });

  test('empty selection or zero weeks produces nothing', () {
    expect(gen('2026-11-03', [], 4), isEmpty);
    expect(gen('2026-11-03', [1], 0), isEmpty);
  });

  test(
    'all generated dates are unique and sorted within a single day pattern',
    () {
      final dates = gen('2026-11-03', [3], 10);
      expect(dates.toSet(), hasLength(10));
      expect([...dates]..sort(), dates);
    },
  );
}
