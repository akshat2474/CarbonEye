enum AlertSeverity {
  critical,
  high,
  medium,
  low,
}
class AlertItem {
  final String id;
  final String title;
  final String location;
  final DateTime date;
  final AlertSeverity severity;
  final bool isArchived;

  AlertItem({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.severity,
    this.isArchived = false,
  });
}
