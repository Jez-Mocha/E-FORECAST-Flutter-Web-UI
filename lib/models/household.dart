/// A household registered by the user.
class Household {
  final int? id;
  final String name;
  final String street;
  final String city;
  final int? numberOfAppliances;
  final String provider;
  final double? ratePerKwh;
  final int? billingCycleDay;
  final String? meterNumber;
  final bool isSample;

  const Household({
    this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.numberOfAppliances,
    required this.provider,
    required this.ratePerKwh,
    required this.billingCycleDay,
    this.meterNumber,
    this.isSample = false,
  });

  /// One-line address for display.
  String get address => city.isEmpty ? street : '$street, $city';

  /// Creates a Household from the backend response.
  factory Household.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] ?? '').toString();
    final parts = address.split(',');

    return Household(
      id: int.tryParse('${json['household_id'] ?? ''}'),
      name: (json['household_name'] ?? '').toString(),
      street: parts.first.trim(),
      city: parts.length > 1 ? parts.sublist(1).join(',').trim() : '',
      numberOfAppliances: int.tryParse('${json['number_of_appliances'] ?? ''}'),
      provider: (json['electricity_provider'] as String?)?.trim() ?? '',
      ratePerKwh: double.tryParse('${json['rate_per_kwh']}'),
      billingCycleDay: int.tryParse('${json['billing_cycle_day']}'),
      meterNumber: json['meter_number']?.toString(),
      isSample: false,
    );
  }
}
