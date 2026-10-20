import 'package:etender_reports/reports/procurement_lead_time/services/working_day_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkingDayCalculator (no holidays)', () {
    final calculator = WorkingDayCalculator();

    test('same working day counts as 1', () {
      expect(calculator.count(DateTime(2026, 11, 2), DateTime(2026, 11, 2)), 1);
    });

    test('Mon to Wed is 3', () {
      expect(calculator.count(DateTime(2026, 11, 2), DateTime(2026, 11, 4)), 3);
    });

    test('Thu to Tue skips the weekend: 4', () {
      expect(
        calculator.count(DateTime(2026, 11, 5), DateTime(2026, 11, 10)),
        4,
      );
    });

    test('Mon 2 Nov to Thu 12 Nov is 9', () {
      expect(
        calculator.count(DateTime(2026, 11, 2), DateTime(2026, 11, 12)),
        9,
      );
    });

    test('received on Saturday: Day 1 is the Monday', () {
      expect(calculator.count(DateTime(2026, 11, 7), DateTime(2026, 11, 9)), 1);
    });

    test('time of day is ignored', () {
      expect(
        calculator.count(
          DateTime(2026, 11, 2, 23, 59),
          DateTime(2026, 11, 3, 0, 1),
        ),
        2,
      );
    });

    test('received and published on the same weekend day is 0', () {
      expect(calculator.count(DateTime(2026, 11, 7), DateTime(2026, 11, 7)), 0);
    });
  });

  group('WorkingDayCalculator (with holidays)', () {
    test('a holiday on Tue 3 Nov makes Mon to Wed 2', () {
      final calculator = WorkingDayCalculator(
        holidays: {DateTime(2026, 11, 3)},
      );
      expect(calculator.count(DateTime(2026, 11, 2), DateTime(2026, 11, 4)), 2);
    });

    test('a holiday carrying a time still matches its date', () {
      final calculator = WorkingDayCalculator(
        holidays: {DateTime(2026, 11, 3, 8, 30)},
      );
      expect(calculator.isWorkingDay(DateTime(2026, 11, 3, 17)), isFalse);
    });
  });
}
