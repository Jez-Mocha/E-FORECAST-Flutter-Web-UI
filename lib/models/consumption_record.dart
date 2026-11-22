
/// One saved meter reading for a household, as returned by the backend
/// (GET /api/consumption/history).
class ConsumptionRecord {
  /// The day the reading was recorded.
  final DateTime date;

  /// The date of the previous meter reading.
  /// Null for older records without a saved previous reading date.
  final DateTime? previousReadingDate;

  /// kWh used, as calculated by the backend (current - previous).
  final double kwh;

  /// Meter readings. The database allows these to be empty.
  final double? meterPrevious;
  final double? meterCurrent;

  const ConsumptionRecord({
    required this.date,
    required this.kwh,
    this.previousReadingDate,
    this.meterPrevious,
    this.meterCurrent,
  });

  /// Builds a record from one item of the backend's "records" list.
  static ConsumptionRecord? tryParse(Map<dynamic, dynamic> json) {
    final date = DateTime.tryParse('${json['date'] ?? ''}');
    if (date == null) return null;

    final previousDate = DateTime.tryParse(
      '${json['previous_reading_date'] ?? ''}',
    );

    final previous = _toDouble(json['meter_previous']);
    final current = _toDouble(json['meter_current']);

    double? kwh = _toDouble(json['kwh']);

    if (kwh == null && previous != null && current != null) {
      kwh = current - previous;
    }

    if (kwh == null) return null;

    return ConsumptionRecord(
      date: DateTime(date.year, date.month, date.day),
      previousReadingDate: previousDate == null
          ? null
          : DateTime(
              previousDate.year,
              previousDate.month,
              previousDate.day,
            ),
      kwh: kwh,
      meterPrevious: previous,
      meterCurrent: current,
    );
  }

  /// Turns a JSON number (or numeric string) into a double.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
