
/// The result of a monthly electricity forecast,
/// as returned by the backend (POST /api/forecasts).
class ForecastResult {
  /// The id of the forecast saved on the server.
  final int forecastId;

  /// The target billing month in YYYY-MM format.
  final String forecastMonth;

  /// Predicted electricity consumption for the next billing month.
  final double predictedKwh;

  /// Estimated electricity bill in PHP for the next billing month.
  final double estimatedBill;

  const ForecastResult({
    required this.forecastId,
    required this.forecastMonth,
    required this.predictedKwh,
    required this.estimatedBill,
  });

  /// Creates a ForecastResult from the backend response.
  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    return ForecastResult(
      forecastId: _toInt(json['forecast_id']) ?? 0,
      forecastMonth: json['forecast_month']?.toString() ?? '',
      predictedKwh:
          _toDouble(json['predicted_consumption_kwh']) ?? 0.0,
      estimatedBill: _toDouble(json['estimated_bill']) ?? 0.0,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
