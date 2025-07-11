import 'package:flutter/material.dart';
import 'package:carboneye/models/alert_item.dart'; // FIXED: Import the corrected model.

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
        title: 'Deforestation Detected',
        location: 'Lat: ${center['latitude'].toStringAsFixed(3)}, Lon: ${center['longitude'].toStringAsFixed(3)}',
        date: DateTime.now(),
        severity: severity,
        isArchived: false,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<AlertItem> alerts = _transformDetectionsToAlerts();
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('All Alerts'),
        backgroundColor: Colors.grey[850],
        elevation: 0,
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Text(
                'No alerts found.\nRun an analysis to see results.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(alert);
              },
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
      default:
        return Colors.yellow.shade400;
    }
  }

  Widget _buildAlertCard(AlertItem alert) {
    return Card(
      color: alert.isArchived ? Colors.grey.shade800 : Colors.grey[850], // FIXED: Correct shade syntax.
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: _getSeverityColor(alert.severity),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: alert.isArchived ? Colors.grey.shade400 : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey.shade400, size: 16),
                const SizedBox(width: 4),
                Text(
                  alert.location,
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${alert.date.day}/${alert.date.month}/${alert.date.year}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSeverityColor(alert.severity).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Severity: ${alert.severity.name}', // Use .name to get the string from enum
                style: TextStyle(
                  color: _getSeverityColor(alert.severity),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
