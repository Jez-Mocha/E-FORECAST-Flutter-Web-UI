import 'package:flutter/material.dart';

class FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final String badge;
  final Color accentColor;

  const FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.accentColor,
  });
}

class StepItem {
  final String step;
  final String title;
  final String description;
  final IconData icon;

  const StepItem({
    required this.step,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class EnergyDataPoint {
  final String label;
  final double actual;
  final double predicted;

  const EnergyDataPoint({
    required this.label,
    required this.actual,
    required this.predicted,
  });
}

enum TimeframeOption { day, week, month, year }
