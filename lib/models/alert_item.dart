enum AlertSeverity { critical, high, medium }

class AlertItem {
  final String title;
  final String location;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isActive;

  const AlertItem({
    required this.title,
    required this.location,
    required this.severity,
    required this.timestamp,
    this.isActive = true,
  });
}
