/// The last saved cumulative reading and its date.
typedef MeterReading = ({double value, DateTime date});

class ProviderRate {
  const ProviderRate({
    required this.id,
    required this.ratePerKwh,
    required this.effectiveDate,
    this.provider,
    this.sourceUrl,
    this.remarks,
    this.createdAt,
  });

  final int id;
  final String? provider;
  final double ratePerKwh;
  final DateTime effectiveDate;
  final String? sourceUrl;
  final String? remarks;
  final DateTime? createdAt;

  factory ProviderRate.fromJson(Map<String, dynamic> json) => ProviderRate(
    id: json['rate_id'] as int,
    ratePerKwh: (json['rate_per_kwh'] as num).toDouble(),
    effectiveDate: DateTime.parse(json['effective_date'] as String),
    provider: json['provider'] as String?,
    sourceUrl: json['source_url'] as String?,
    remarks: json['remarks'] as String?,
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
  );
}

class MonthlyConsumption {
  const MonthlyConsumption({required this.month, required this.kwh});

  final DateTime month;
  final double kwh;

  factory MonthlyConsumption.fromJson(Map<String, dynamic> json) =>
      MonthlyConsumption(
        month: DateTime.parse('${json['billing_month']}-01'),
        kwh: (json['consumption_kwh'] as num).toDouble(),
      );
}
