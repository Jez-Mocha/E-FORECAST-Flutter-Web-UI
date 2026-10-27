import 'package:flutter/material.dart';

/// The kind of message. Each kind gets its own small icon and label.
enum MessageCategory {
  billReminder,
  meterReading,
  savingTip,
  providerAdvisory,
  consumption,
  system,
}

extension MessageCategoryInfo on MessageCategory {
  IconData get icon {
    switch (this) {
      case MessageCategory.billReminder:
        return Icons.receipt_long_outlined;
      case MessageCategory.meterReading:
        return Icons.speed_outlined;
      case MessageCategory.savingTip:
        return Icons.lightbulb_outline_rounded;
      case MessageCategory.providerAdvisory:
        return Icons.campaign_outlined;
      case MessageCategory.consumption:
        return Icons.bolt_outlined;
      case MessageCategory.system:
        return Icons.info_outline_rounded;
    }
  }

  String get label {
    switch (this) {
      case MessageCategory.billReminder:
        return 'Bill reminder';
      case MessageCategory.meterReading:
        return 'Meter reading';
      case MessageCategory.savingTip:
        return 'Saving tip';
      case MessageCategory.providerAdvisory:
        return 'Provider advisory';
      case MessageCategory.consumption:
        return 'Consumption';
      case MessageCategory.system:
        return 'E-FORECAST';
    }
  }
}

/// One message in the Messages panel.
class DashboardMessage {
  final MessageCategory category;
  final String title;
  final String body;
  final String timeLabel; // Plain text for now, for example "Today"
  final bool isUnread;

  const DashboardMessage({
    required this.category,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isUnread = false,
  });
}

/// SAMPLE MESSAGES ONLY. These are written by us to preview the layout.
/// They are not from a backend and not real notifications.
const List<DashboardMessage> sampleMessages = [
  DashboardMessage(
    category: MessageCategory.billReminder,
    title: 'Check your upcoming bill date',
    body:
        'Your billing day is set per household. Open a household to '
        'review its billing cycle.',
    timeLabel: 'Today',
    isUnread: true,
  ),
  DashboardMessage(
    category: MessageCategory.meterReading,
    title: 'Meter reading reminder',
    body:
        'Note your meter reading around your billing day so it is easy '
        'to compare with your bill.',
    timeLabel: 'Today',
    isUnread: true,
  ),
  DashboardMessage(
    category: MessageCategory.savingTip,
    title: 'Saving tip: standby power',
    body:
        'Unplugging chargers and idle appliances can reduce small but '
        'constant power use.',
    timeLabel: 'Yesterday',
  ),
  DashboardMessage(
    category: MessageCategory.system,
    title: 'Welcome to E-FORECAST',
    body:
        'Messages here are samples. Real notifications will appear once '
        'the backend is connected.',
    timeLabel: 'This week',
  ),
];
