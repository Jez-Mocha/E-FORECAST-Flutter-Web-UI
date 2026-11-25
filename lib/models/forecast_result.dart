/// The result of a forecast, as returned by the backend (POST /api/forecasts).
class ForecastResult {
  /// The id of the forecast saved on the server.
  final int forecastId;

  /// Predicted electricity use in kWh for the forecast month.
  final double predictedKwh;

  /// Estimated bill in PHP for that predicted use.
  final double estimatedBill;
  final DateTime? month;
  final String? provider;
  final double? ratePerKwh;
  final DateTime? rateEffectiveDate;
  final bool? rateIsForForecastMonth;
  final String? rateMessage;

  const ForecastResult({
    required this.forecastId,
    required this.predictedKwh,
    required this.estimatedBill,
    this.month,
    this.provider,
    this.ratePerKwh,
    this.rateEffectiveDate,
    this.rateIsForForecastMonth,
    this.rateMessage,
  });

  /// Creates a ForecastResult from the backend response.
  /// Numbers can arrive as whole numbers (10) or decimals (10.15), so they
  /// are converted safely.
  factory ForecastResult.fromJson(Map<String, dynamic> json) {
    return ForecastResult(
      forecastId:
          _toInt(json['forecast_id']) ??
          (throw const FormatException('Missing forecast ID')),
      predictedKwh:
          _toDouble(json['predicted_consumption_kwh']) ??
          (throw const FormatException('Missing forecast consumption')),
      estimatedBill:
          _toDouble(json['estimated_bill']) ??
          (throw const FormatException('Missing estimated bill')),
      month: DateTime.tryParse('${json['forecast_month']}-01'),
      provider: json['provider'] as String?,
      ratePerKwh: _toDouble(json['rate_per_kwh']),
      rateEffectiveDate: DateTime.tryParse('${json['rate_effective_date']}'),
      rateIsForForecastMonth: json['rate_is_for_forecast_month'] as bool?,
      rateMessage: json['rate_message'] as String?,
    );
  }

  /// Turns a JSON number (or a numeric string) into a double.
  /// Returns null if the value is missing or not a number.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  /// Turns a JSON number (or a numeric string) into an int.
  /// Returns null if the value is missing or not a number.
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
