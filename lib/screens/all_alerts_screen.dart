import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:carboneye/models/alert_item.dart';
import 'package:carboneye/utils/constants.dart';

class AllAlertsScreen extends StatelessWidget {
   AllAlertsScreen({super.key});

  final List<AlertItem> _alerts = [
    AlertItem(title: "Unusual Canopy Loss Detected", location: "Amazonas, Brazil", severity: AlertSeverity.critical, timestamp: DateTime(2025, 7, 7)),
    AlertItem(title: "Potential Illegal Logging", location: "Borneo, Indonesia", severity: AlertSeverity.high, timestamp: DateTime(2025, 7, 5)),
    AlertItem(title: "Minor Vegetation Change", location: "Congo Basin, DRC", severity: AlertSeverity.medium, timestamp: DateTime(2025, 7, 2)),
    AlertItem(title: "Historical Canopy Loss", location: "Siberian Taiga", severity: AlertSeverity.high, timestamp: DateTime(2025, 6, 28), isActive: false),
    AlertItem(title: "Fire Scar Detected", location: "Daintree, Australia", severity: AlertSeverity.critical, timestamp: DateTime(2025, 6, 25), isActive: false),
  ];

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red.shade400;
      case AlertSeverity.high:
        return Colors.orange.shade400;
      case AlertSeverity.medium:
      return Colors.yellow.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("All Alerts", style: kAppTitleStyle),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20.0),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return _buildAlertCard(alert);
        },
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border(
          left: BorderSide(
            color: _getSeverityColor(alert.severity),
            width: 5.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alert.severity.name.toUpperCase(),
                style: kBodyTextStyle.copyWith(
                  color: _getSeverityColor(alert.severity),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (!alert.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSecondaryTextColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Archived", style: kSecondaryBodyTextStyle.copyWith(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.title, style: kBodyTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: kSecondaryTextColor, size: 16),
              const SizedBox(width: 4),
              Text(alert.location, style: kSecondaryBodyTextStyle),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: kSecondaryTextColor, size: 16),
              const SizedBox(width: 4),
              Text(DateFormat.yMMMd().format(alert.timestamp), style: kSecondaryBodyTextStyle),
            ],
          ),
        ],
      ),
    );
  }
}
