/// One electricity company shown in the Electricity Rates carousel.
///
/// IMPORTANT: no rate in this app is live. [ratePerKwh] is null until a
/// rate has been checked against the provider's official source. When it is
/// null, the UI shows "Rate unavailable" instead of a made-up number.
/// Later, your teammate's backend can fill these values in.
class ElectricityRate {
  final String provider; // Company name, for example "Davao Light"
  final String area; // Area the company serves
  final double? ratePerKwh; // Residential rate in PHP per kWh (null = unknown)
  final String? effectiveLabel; // For example "October 2026"
  final String? sourceLabel; // Where the rate came from

  const ElectricityRate({
    required this.provider,
    required this.area,
    this.ratePerKwh,
    this.effectiveLabel,
    this.sourceLabel,
  });

  /// True only when a verified rate has been provided.
  bool get hasRate => ratePerKwh != null;

  /// Text to show on the card.
  String get rateText {
    final rate = ratePerKwh;
    if (rate == null) return 'Rate unavailable';
    return '₱${rate.toStringAsFixed(2)} / kWh';
  }

  /// Text for the effective date line.
  String get effectiveText => effectiveLabel ?? 'Effective date not available';

  /// Text for the source line.
  String get sourceText => sourceLabel ?? 'Source not yet verified';
}

/// The three providers for the carousel.
/// All rates are intentionally empty for now. We will check official sources
/// in a later step and only fill in numbers we can confirm.
const List<ElectricityRate> electricityRates = [
  ElectricityRate(provider: 'ANECO', area: 'Agusan del Norte'),
  ElectricityRate(provider: 'Davao Light', area: 'Davao City area'),
  ElectricityRate(provider: 'DORECO', area: 'Davao Oriental'),
];
