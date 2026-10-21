/// A household registered by the user (shown on SCR-03, created on SCR-04,
/// opened on SCR-05).
/// It is held in memory for now. There is no backend or database yet.
class Household {
  final String name;
  final String street; // Street / Barangay
  final String city; // City / Municipality
  final int occupants;
  final String provider;
  final double ratePerKwh; // Pesos per kWh
  final int billingCycleDay; // Day of the month, 1 to 31

  /// True only for the built-in demo households (placeholder values).
  final bool isSample;

  const Household({
    required this.name,
    required this.street,
    required this.city,
    required this.occupants,
    required this.provider,
    required this.ratePerKwh,
    required this.billingCycleDay,
    this.isSample = false,
  });

  /// One-line address for display, for example on a HouseholdCard.
  String get address => '$street, $city';
}
