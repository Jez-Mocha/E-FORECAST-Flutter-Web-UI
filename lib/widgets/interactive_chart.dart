import 'package:flutter/material.dart';
import '../models/energy_models.dart';
import '../theme/app_colors.dart';
import 'chart_painter.dart';

class InteractiveEnergyDashboard extends StatefulWidget {
  const InteractiveEnergyDashboard({super.key});

  @override
  State<InteractiveEnergyDashboard> createState() => _State();
}

class _State extends State<InteractiveEnergyDashboard> {
  TimeframeOption _tf = TimeframeOption.week;

  final Map<TimeframeOption, List<EnergyDataPoint>> _data = {
    TimeframeOption.day: const [
      EnergyDataPoint(label: '00', actual: 1.2, predicted: 1.1),
      EnergyDataPoint(label: '06', actual: 2.4, predicted: 2.2),
      EnergyDataPoint(label: '12', actual: 3.8, predicted: 3.6),
      EnergyDataPoint(label: '18', actual: 4.2, predicted: 4.0),
      EnergyDataPoint(label: '23', actual: 2.1, predicted: 2.0),
    ],
    TimeframeOption.week: const [
      EnergyDataPoint(label: 'Mon', actual: 18.2, predicted: 17.5),
      EnergyDataPoint(label: 'Tue', actual: 19.4, predicted: 18.9),
      EnergyDataPoint(label: 'Wed', actual: 16.8, predicted: 17.0),
      EnergyDataPoint(label: 'Thu', actual: 22.1, predicted: 21.5),
      EnergyDataPoint(label: 'Fri', actual: 24.6, predicted: 23.8),
      EnergyDataPoint(label: 'Sat', actual: 28.0, predicted: 27.2),
      EnergyDataPoint(label: 'Sun', actual: 25.3, predicted: 24.9),
    ],
    TimeframeOption.month: const [
      EnergyDataPoint(label: 'W1', actual: 140, predicted: 135),
      EnergyDataPoint(label: 'W2', actual: 155, predicted: 150),
      EnergyDataPoint(label: 'W3', actual: 148, predicted: 160),
      EnergyDataPoint(label: 'W4', actual: 162, predicted: 158),
    ],
    TimeframeOption.year: const [
      EnergyDataPoint(label: 'Q1', actual: 420, predicted: 410),
      EnergyDataPoint(label: 'Q2', actual: 560, predicted: 550),
      EnergyDataPoint(label: 'Q3', actual: 510, predicted: 500),
      EnergyDataPoint(label: 'Q4', actual: 440, predicted: 430),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final points = _data[_tf]!;
    final latest = points.last;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildHeader(latest),
        Container(
          height: 160,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomPaint(painter: SmoothChartPainter(data: points), child: const SizedBox.expand()),
        ),
        const SizedBox(height: 12),
        _buildPills(latest),
      ]),
    );
  }

  Widget _buildHeader(EnergyDataPoint latest) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI TELEMETRY & FORECAST',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text('${latest.actual.toStringAsFixed(1)} kWh',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        _buildTimeframePicker(),
      ]),
    );
  }

  Widget _buildTimeframePicker() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: TimeframeOption.values.map((tf) {
          final active = _tf == tf;
          return InkWell(
            onTap: () => setState(() => _tf = tf),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.surfaceElevated : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(tf.name.toUpperCase(),
                  style: TextStyle(
                      color: active ? AppColors.textPrimary : AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPills(EnergyDataPoint latest) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(children: [
        _pill('Model Accuracy', '98.4%', AppColors.emerald),
        const SizedBox(width: 8),
        _pill('XGBoost Pred.', '${latest.predicted.toStringAsFixed(1)} kWh', AppColors.electricBlue),
        const SizedBox(width: 8),
        _pill('Optimization', 'Active', AppColors.purple),
      ]),
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10), maxLines: 1),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1),
        ]),
      ),
    );
  }
}
