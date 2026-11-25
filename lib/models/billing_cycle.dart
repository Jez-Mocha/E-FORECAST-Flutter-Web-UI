import 'consumption_record.dart';

/// Calendar dates use UTC midnight so a day is always exactly 24 hours.
class BillingCycle {
  const BillingCycle._(this.start, this.nextStart);

  final DateTime start;
  final DateTime nextStart;

  DateTime get end => nextStart.subtract(const Duration(days: 1));
  int get days => nextStart.difference(start).inDays;

  factory BillingCycle.current(DateTime today, int billingDay) {
    assert(billingDay >= 1 && billingDay <= 31);

    DateTime boundary(int month) {
      final monthEnd = DateTime.utc(today.year, month + 1, 0).day;
      return DateTime.utc(
        today.year,
        month,
        billingDay <= monthEnd ? billingDay : monthEnd,
      );
    }

    final thisMonth = boundary(today.month);
    return _calendarDate(today).isBefore(thisMonth)
        ? BillingCycle._(boundary(today.month - 1), thisMonth)
        : BillingCycle._(thisMonth, boundary(today.month + 1));
  }

  BillingUsage measuredUsage(
    Iterable<ConsumptionRecord> readings,
    DateTime today,
  ) {
    final through = _calendarDate(today);
    final ordered = readings.toList()..sort((a, b) => a.date.compareTo(b.date));
    var lastCovered = start.subtract(const Duration(days: 1));
    ConsumptionRecord? previousMeter;
    var kwh = 0.0;
    var coveredDays = 0;
    var hasUndatedReadings = false;

    for (final reading in ordered) {
      final date = _calendarDate(reading.date);
      if (date.isAfter(through) || !date.isBefore(nextStart)) break;
      final preceding = previousMeter;
      if (reading.meterCurrent != null) previousMeter = reading;
      if (date.isBefore(start)) continue;

      // Older rows may lack the date. A matching saved meter value anchors it.
      final previous =
          reading.previousReadingDate ??
          (preceding != null && reading.meterPrevious == preceding.meterCurrent
              ? preceding.date
              : null);
      if (previous == null || !_calendarDate(previous).isBefore(date)) {
        hasUndatedReadings = true;
        continue;
      }
      if (!reading.kwh.isFinite || reading.kwh < 0) continue;

      final previousDay = _calendarDate(previous);
      final firstUncovered = lastCovered.add(const Duration(days: 1));
      final firstDay = firstUncovered.isAfter(previousDay)
          ? firstUncovered
          : previousDay.add(const Duration(days: 1));
      if (firstDay.isAfter(date)) continue;

      // Count only cycle days covered by the reading and only count each once.
      final overlap = date.difference(firstDay).inDays + 1;
      kwh += reading.kwh * overlap / date.difference(previousDay).inDays;
      coveredDays += overlap;
      lastCovered = date;
    }
    return BillingUsage(
      kwh: kwh,
      coveredDays: coveredDays,
      hasUndatedReadings: hasUndatedReadings,
    );
  }

  static DateTime _calendarDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);
}

class BillingUsage {
  const BillingUsage({
    required this.kwh,
    required this.coveredDays,
    required this.hasUndatedReadings,
  });

  final double kwh;
  final int coveredDays;
  final bool hasUndatedReadings;

  double? projectedKwh(BillingCycle cycle) =>
      coveredDays == 0 ? null : kwh / coveredDays * cycle.days;
}
