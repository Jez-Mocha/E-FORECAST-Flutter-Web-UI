import 'package:e_forecast/models/billing_cycle.dart';
import 'package:e_forecast/models/consumption_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clamps the 31st and crosses the year boundary', () {
    final leap = BillingCycle.current(DateTime(2024, 2, 29), 31);
    expect(leap.start, DateTime.utc(2024, 2, 29));
    expect(leap.end, DateTime.utc(2024, 3, 30));
    final january = BillingCycle.current(DateTime(2026, 1, 10), 31);
    expect(january.start, DateTime.utc(2025, 12, 31));
    expect(january.nextStart, DateTime.utc(2026, 1, 31));
  });

  test(
    'prorates crossing and overlapping reads and projects from covered days',
    () {
      final today = DateTime(2026, 11, 28);
      final cycle = BillingCycle.current(today, 15);
      final usage = cycle.measuredUsage([
        ConsumptionRecord(
          date: DateTime(2026, 11, 20),
          previousReadingDate: DateTime(2026, 11, 10),
          kwh: 50,
        ),
        ConsumptionRecord(
          date: DateTime(2026, 11, 24),
          previousReadingDate: DateTime(2026, 11, 18),
          kwh: 30,
        ),
        ConsumptionRecord(
          date: DateTime(2026, 12, 1),
          previousReadingDate: DateTime(2026, 11, 24),
          kwh: 70,
        ),
      ], today);
      expect(usage.kwh, 50);
      expect(usage.coveredDays, 10);
      expect(usage.projectedKwh(cycle), 150);
    },
  );

  test('only infers a legacy previous date from matching meter values', () {
    final today = DateTime(2026, 11, 27);
    final cycle = BillingCycle.current(today, 1);
    final first = ConsumptionRecord(
      date: DateTime(2026, 11, 3),
      kwh: 8,
      meterCurrent: 105,
    );
    final withoutBaseline = cycle.measuredUsage([first], today);
    expect(withoutBaseline.projectedKwh(cycle), isNull);
    expect(withoutBaseline.hasUndatedReadings, isTrue);
    final usage = cycle.measuredUsage([
      first,
      ConsumptionRecord(
        date: DateTime(2026, 11, 5),
        kwh: 10,
        meterPrevious: 105,
        meterCurrent: 115,
      ),
      ConsumptionRecord(
        date: DateTime(2026, 11, 7),
        kwh: 6,
        meterPrevious: 110,
        meterCurrent: 116,
      ),
    ], today);
    expect(usage.kwh, 10);
    expect(usage.coveredDays, 2);
    expect(usage.hasUndatedReadings, isTrue);
  });
}
