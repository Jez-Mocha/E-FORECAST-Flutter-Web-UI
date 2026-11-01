/// A household registered by the user.
class Household {
  final int? id;
  final String name;
  final String street;
  final String city;
  final int occupants;
  final String provider;
  final double ratePerKwh;
  final int billingCycleDay;
  final String? meterNumber;
  final bool isSample;

  const Household({
    this.id,
    required this.name,
    required this.street,
    required this.city,
    required this.occupants,
    required this.provider,
    required this.ratePerKwh,
    required this.billingCycleDay,
    this.meterNumber,
    this.isSample = false,
  });

  /// One-line address for display.
  String get address => '$street, $city';

  /// Creates a Household from the backend response.
  factory Household.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] ?? '').toString();
    final parts = address.split(',');

    return Household(
      id: int.tryParse('${json['household_id'] ?? ''}'),
      name: (json['household_name'] ?? '').toString(),
      street: parts.first.trim(),
      city: parts.length > 1 ? parts.sublist(1).join(',').trim() : '',
      occupants: 0,
      provider: '',
      ratePerKwh: 0.0,
      billingCycleDay: 1,
      meterNumber: json['meter_number']?.toString(),
      isSample: false,
    );
  }
}
