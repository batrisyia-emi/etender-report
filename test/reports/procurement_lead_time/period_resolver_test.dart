import 'package:etender_reports/reports/procurement_lead_time/models/period_preset.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/period_resolver.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

/// 'dd.MM.yyyy' to a date.
DateTime _d(String text) {
  final [day, month, year] = text.split('.').map(int.parse).toList();
  return DateTime(year, month, day);
}

/// One spec line: as of [today], [preset] covers [from] to [to].
void _expectRange(
  String today,
  PeriodPreset preset,
  String from,
  String to, {
  int fyStartMonth = 1,
}) {
  test('today $today, ${preset.name} -> $from to $to', () {
    final range = PeriodResolver.resolve(
      preset,
      today: _d(today),
      fyStartMonth: fyStartMonth,
    )!;
    expect(
      '${formatDottedDate(range.start)} to ${formatDottedDate(range.end)}',
      '$from to $to',
    );
  });
}

void main() {
  group('fyStartMonth = 1', () {
    _expectRange(
      '19.10.2026',
      PeriodPreset.lastMonth,
      '01.09.2026',
      '30.09.2026',
    );
    _expectRange(
      '19.10.2026',
      PeriodPreset.thisMonth,
      '01.10.2026',
      '19.10.2026',
    );
    _expectRange(
      '19.10.2026',
      PeriodPreset.lastQuarter,
      '01.07.2026',
      '30.09.2026',
    );
    _expectRange(
      '19.10.2026',
      PeriodPreset.thisQuarter,
      '01.10.2026',
      '19.10.2026',
    );
    _expectRange(
      '19.10.2026',
      PeriodPreset.yearToDate,
      '01.01.2026',
      '19.10.2026',
    );
    _expectRange(
      '19.10.2026',
      PeriodPreset.last12Months,
      '01.10.2025',
      '30.09.2026',
    );
    _expectRange(
      '15.01.2027',
      PeriodPreset.lastMonth,
      '01.12.2026',
      '31.12.2026',
    );
    _expectRange(
      '15.01.2027',
      PeriodPreset.lastQuarter,
      '01.10.2026',
      '31.12.2026',
    );
    _expectRange(
      '15.01.2027',
      PeriodPreset.yearToDate,
      '01.01.2027',
      '15.01.2027',
    );
    // Leap year.
    _expectRange(
      '10.03.2028',
      PeriodPreset.lastMonth,
      '01.02.2028',
      '29.02.2028',
    );
    // Single day.
    _expectRange(
      '01.10.2026',
      PeriodPreset.thisMonth,
      '01.10.2026',
      '01.10.2026',
    );
    _expectRange(
      '31.03.2026',
      PeriodPreset.lastMonth,
      '01.02.2026',
      '28.02.2026',
    );
  });

  group('fyStartMonth = 4', () {
    void expectFy4(String today, PeriodPreset preset, String from, String to) =>
        _expectRange(today, preset, from, to, fyStartMonth: 4);

    expectFy4(
      '19.10.2026',
      PeriodPreset.yearToDate,
      '01.04.2026',
      '19.10.2026',
    );
    expectFy4(
      '19.10.2026',
      PeriodPreset.thisQuarter,
      '01.10.2026',
      '19.10.2026',
    );
    expectFy4(
      '19.10.2026',
      PeriodPreset.lastQuarter,
      '01.07.2026',
      '30.09.2026',
    );
    expectFy4(
      '15.02.2027',
      PeriodPreset.yearToDate,
      '01.04.2026',
      '15.02.2027',
    );
    expectFy4(
      '15.02.2027',
      PeriodPreset.lastQuarter,
      '01.10.2026',
      '31.12.2026',
    );
    expectFy4(
      '10.04.2027',
      PeriodPreset.lastQuarter,
      '01.01.2027',
      '31.03.2027',
    );
  });

  group('edge rules', () {
    test('custom has no range', () {
      expect(
        PeriodResolver.resolve(PeriodPreset.custom, today: _d('19.10.2026')),
        isNull,
      );
    });

    test('time of day is stripped', () {
      final range = PeriodResolver.resolve(
        PeriodPreset.thisMonth,
        today: DateTime(2026, 10, 19, 23, 59),
      )!;
      expect(range.end, DateTime(2026, 10, 19));
    });

    test('fyStartMonth outside 1–12 is rejected', () {
      expect(
        () => PeriodResolver.resolve(
          PeriodPreset.yearToDate,
          today: _d('19.10.2026'),
          fyStartMonth: 13,
        ),
        throwsArgumentError,
      );
    });
  });
}
