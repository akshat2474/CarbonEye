import 'package:carboneye/models/report_data.dart';
import 'package:carboneye/models/watchlist_item.dart';

class ReportGenerator {
  static ReportData generateReport({
    required WatchlistItem region,
    required List<Map<String, dynamic>> detections,
  }) {
    int criticalAlerts = 0;
    int highAlerts = 0;
    int mediumAlerts = 0;
    double totalAreaHa = 0.0;

    for (var detection in detections) {
      totalAreaHa += (detection['area_ha'] ?? 0.0);
      final severity = detection['severity']?.toString().toLowerCase();
      switch (severity) {
        case 'critical':
          criticalAlerts++;
          break;
        case 'high':
          highAlerts++;
          break;
        case 'medium':
        default:
          mediumAlerts++;
          break;
      }
    }

    final sortedDetections = List<Map<String, dynamic>>.from(detections);

    sortedDetections.sort((a, b) {
      const severityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
      
      final severityA = severityOrder[a['severity']?.toString().toLowerCase()] ?? 99;
      final severityB = severityOrder[b['severity']?.toString().toLowerCase()] ?? 99;

      if (severityA != severityB) {
        return severityA.compareTo(severityB);
      }
      return (b['area_ha'] ?? 0.0).compareTo(a['area_ha'] ?? 0.0);
    });

    return ReportData(
      region: region,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
      totalDetections: detections.length,
      totalAreaHa: totalAreaHa,
      criticalAlerts: criticalAlerts,
      highAlerts: highAlerts,
      mediumAlerts: mediumAlerts,
      mostSevereDetections: sortedDetections.take(5).toList(),
    );
  }
}
