import 'package:carboneye/models/watchlist_item.dart';

class ReportData {
  final WatchlistItem region;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDetections;
  final double totalAreaHa;
  final int criticalAlerts;
  final int highAlerts;
  final int mediumAlerts;
  final List<Map<String, dynamic>> mostSevereDetections;

  ReportData({
    required this.region,
    required this.startDate,
    required this.endDate,
    required this.totalDetections,
    required this.totalAreaHa,
    required this.criticalAlerts,
    required this.highAlerts,
    required this.mediumAlerts,
    required this.mostSevereDetections,
  });
}
