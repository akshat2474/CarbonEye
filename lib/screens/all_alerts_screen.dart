import 'package:flutter/material.dart';

class AllAlertsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> detections;

  const AllAlertsScreen({Key? key, required this.detections}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Alerts"),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Container(
        color: Colors.grey.shade900,
        child: detections.isEmpty
            ? const Center(
                child: Text(
                  "No alerts to display.",
                  style: TextStyle(color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: detections.length,
                itemBuilder: (context, index) {
                  final alert = detections[index];
                  final position = alert['position'];
                  final severity = alert['severity']?.toString().toLowerCase() ?? 'moderate';
                  final color = severity == 'critical'
                      ? Colors.red.shade400
                      : Colors.orange.shade400;

                  return Card(
                    color: Colors.grey.shade800,
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: color),
                      title: Text(
                        'Alert #${index + 1}: ${severity.toUpperCase()}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Position: (${position['lat']}, ${position['lon']})',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      onTap: () {
                        // Optional: Add functionality to show details or navigate
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}