import 'package:flutter/material.dart';

import '../theme/landing_colors.dart';
import 'landing_chart.dart';
import 'landing_widgets.dart';

/// Illustrative values only. They are labelled "Sample data" in the UI and are
/// not produced by a real model or backend.
const List<LandingChartPoint> _history = [
  LandingChartPoint('Dec', 1090),
  LandingChartPoint('Jan', 1130),
  LandingChartPoint('Feb', 1100),
  LandingChartPoint('Mar', 1180),
  LandingChartPoint('Apr', 1210),
  LandingChartPoint('May', 1250),
  LandingChartPoint('Jun', 1400),
  LandingChartPoint('Jul', 1380),
];

class LandingDashboardSection extends StatelessWidget {
  const LandingDashboardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LandingSection(
      child: Column(
        children: [
          const LandingSectionHeader(
            tag: 'Preview',
            title: 'Your Household Energy, Made Clear',
            subtitle:
                'Explore how consumption records, usage trends, and forecasting insights can come together in one place.',
          ),
          const SizedBox(height: 48),
          const _DashboardMock(),
        ],
      ),
    );
  }
}

class _DashboardMock extends StatelessWidget {
  const _DashboardMock();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      color: LandingColors.backgroundSoft,
      radius: 28,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 640 ? 14 : 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final statColumns = constraints.maxWidth >= 720 ? 4 : 2;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DashboardHeader(),
              const SizedBox(height: 20),
              LandingGrid(
                columns: statColumns,
                spacing: 14,
                children: const [
                  LandingStatTile(
                    label: 'Previous Reading',
                    value: '1,250 kWh',
                    caption: 'Meter, last cycle',
                  ),
                  LandingStatTile(
                    label: 'Current Reading',
                    value: '1,400 kWh',
                    caption: 'Meter, this cycle',
                  ),
                  LandingStatTile(
                    label: 'Recorded Consumption',
                    value: '150 kWh',
                    caption: 'Current − previous',
                  ),
                  LandingStatTile(
                    label: 'Forecast Next Cycle',
                    value: '1,400 kWh',
                    caption: 'XGBoost model output',
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (wide)
                const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _HistoryCard()),
                      SizedBox(width: 18),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ComparisonCard(),
                            SizedBox(height: 18),
                            Expanded(child: _BillCard()),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HistoryCard(),
                    SizedBox(height: 18),
                    _ComparisonCard(),
                    SizedBox(height: 18),
                    _BillCard(),
                  ],
                ),
              const SizedBox(height: 16),
              Text(
                'All figures on this page are illustrative sample data for demonstration. '
                'They are not real measurements or a real forecast.',
                style: TextStyle(color: LandingColors.textSecondary, fontSize: 12, height: 1.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Selected household',
          style: TextStyle(
            color: LandingColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: LandingColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LandingColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Main Residence',
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: LandingColors.textSecondary),
            ],
          ),
        ),
        const SampleDataChip(),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      shadow: false,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Consumption history (kWh / month)',
                style: TextStyle(
                  color: LandingColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ChartLegend(),
            ],
          ),
          SizedBox(height: 12),
          LandingLineChart(
            points: _history,
            forecastStart: 6,
            height: 220,
            semanticLabel:
                'Illustrative sample chart: actual monthly usage December to May, forecast June and July',
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard();

  @override
  Widget build(BuildContext context) {
    return LandingCard(
      shadow: false,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forecast comparison',
            style: TextStyle(
              color: LandingColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          _CompareBar(
            label: 'Current cycle',
            valueText: '1,250 kWh',
            fraction: 1250 / 1400,
            color: LandingColors.secondary,
          ),
          SizedBox(height: 14),
          _CompareBar(
            label: 'Forecast next cycle',
            valueText: '1,400 kWh',
            fraction: 1.0,
            color: LandingColors.primary,
          ),
        ],
      ),
    );
  }
}

class _CompareBar extends StatelessWidget {
  final String label;
  final String valueText;
  final double fraction;
  final Color color;

  const _CompareBar({
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: LandingColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                color: LandingColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 12,
            color: LandingColors.periwinkleTint,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LandingColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated bill · next cycle',
            style: TextStyle(
              color: Color(0xDDFFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '₱2,800',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Based on forecast usage and configured billing logic',
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
