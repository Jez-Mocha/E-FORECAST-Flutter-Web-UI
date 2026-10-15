import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LiveEstimator extends StatefulWidget {
  const LiveEstimator({super.key});

  @override
  State<LiveEstimator> createState() => _LiveEstimatorState();
}

class _LiveEstimatorState extends State<LiveEstimator> {
  double _kwh = 350;

  String _formatCurrency(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final baseCost = _kwh * 11.50;
    final optimizedKwh = _kwh * 0.88;
    final optimizedCost = optimizedKwh * 11.50;
    final savings = baseCost - optimizedCost;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cyan.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.calculate_rounded, color: AppColors.cyan, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Electricity Bill Simulator',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Simulate XGBoost forecasting & managed savings',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Consumption',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_kwh.toInt()} kWh / mo',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.cyan,
                  inactiveTrackColor: AppColors.background,
                  thumbColor: Colors.white,
                  overlayColor: AppColors.cyan.withValues(alpha: 0.2),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                ),
                child: Slider(
                  value: _kwh,
                  min: 50,
                  max: 1500,
                  divisions: 29,
                  onChanged: (val) => setState(() => _kwh = val),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('50 kWh', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text('Avg: ~350 kWh', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  Text('1,500 kWh', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 22),
              if (isNarrow)
                Column(
                  children: [
                    _estCard('Standard Unmanaged Bill', '₱${_formatCurrency(baseCost)}', AppColors.textMuted, false),
                    const SizedBox(height: 10),
                    _estCard('XGBoost Forecasted & Managed', '₱${_formatCurrency(optimizedCost)}', AppColors.cyan, true),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _estCard('Standard Unmanaged Bill', '₱${_formatCurrency(baseCost)}', AppColors.textMuted, false),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _estCard('XGBoost Forecasted & Managed', '₱${_formatCurrency(optimizedCost)}', AppColors.cyan, true),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_down_rounded, color: AppColors.emerald, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Projected Monthly Savings: ₱${_formatCurrency(savings)} / month',
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _estCard(String title, String cost, Color accentColor, bool highlight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.surfaceElevated : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.cyan.withValues(alpha: 0.35) : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: highlight ? AppColors.cyan : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cost,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
