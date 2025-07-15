import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/neu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AllAlertsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> detections;

  const AllAlertsScreen({super.key, required this.detections});

  List<AlertItem> _transformDetectionsToAlerts() {
    return detections.map((d) {
      final center = d['center_coordinates'];
      final severityString = d['severity']?.toString().toLowerCase() ?? 'medium';

      AlertSeverity severity;
      switch (severityString) {
        case 'critical':
          severity = AlertSeverity.critical;
          break;
        case 'high':
          severity = AlertSeverity.high;
          break;
        case 'low':
          severity = AlertSeverity.low;
          break;
        case 'medium':
        default:
          severity = AlertSeverity.medium;
      }

      return AlertItem(
        id: d['id']?.toString() ?? UniqueKey().toString(),
        title: 'Deforestation Event',
        location: 'Lat: ${center['latitude'].toStringAsFixed(4)}, Lon: ${center['longitude'].toStringAsFixed(4)}',
        date: DateTime.now(),
        severity: severity,
        area: (d['area_ha'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<AlertItem> alerts = _transformDetectionsToAlerts();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('All Alerts'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: kSectionTitleStyle.copyWith(fontSize: 22),
      ),
      body: alerts.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(alert)
                    .animate()
                    .fadeIn(delay: (100 * index).ms, duration: 400.ms)
                    .slideX(begin: 0.2, curve: Curves.easeOut);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_moon_outlined, size: 80, color: kSecondaryTextColor),
          const SizedBox(height: 16),
          Text(
            'No Alerts Found',
            style: kSectionTitleStyle.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Run an analysis to detect new events.',
            textAlign: TextAlign.center,
            style: kSecondaryBodyTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final Color severityColor = _getSeverityColor(alert.severity);

    return NeuCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          border: Border(left: BorderSide(color: severityColor, width: 6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    alert.severity.name.toUpperCase(),
                    style: kBodyTextStyle.copyWith(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (alert.area > 0)
                    Text(
                      '${alert.area.toStringAsFixed(2)} ha',
                      style: kBodyTextStyle.copyWith(
                        color: kAccentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const Divider(color: kBackgroundColor, height: 24),
              Text(
                alert.title,
                style: kBodyTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: kSecondaryTextColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(alert.location, style: kSecondaryBodyTextStyle, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: kSecondaryTextColor, size: 16),
                  const SizedBox(width: 8),
                  Text(DateFormat.yMMMd().add_jm().format(alert.date), style: kSecondaryBodyTextStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red.shade400;
      case AlertSeverity.high:
        return Colors.orange.shade400;
      case AlertSeverity.medium:
      case AlertSeverity.low:
        return Colors.yellow.shade400;
    }
  }
}

enum AlertSeverity { critical, high, medium, low }

class AlertItem {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final AlertSeverity severity;
  final bool isArchived;
  final double area;

  AlertItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.severity,
    this.isArchived = false,
    this.area = 0.0,
  });
}