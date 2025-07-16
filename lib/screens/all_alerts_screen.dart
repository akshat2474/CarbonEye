import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/neu_card.dart';
import 'package:flutter/material.dart';

class AllAlertsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> detections;

  const AllAlertsScreen({super.key, required this.detections});

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
      body: detections.isEmpty
          ? Center(
              child: Text(
                "No alerts to display.",
                style: kSecondaryBodyTextStyle,
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              itemCount: detections.length,
              itemBuilder: (context, index) {
                final alert = detections[index];
                final position = alert['position'];
                final severity =
                    alert['severity']?.toString().toLowerCase() ?? 'moderate';
                final color = severity == 'critical'
                    ? Colors.red.shade400
                    : Colors.orange.shade400;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: NeuCard(
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_rounded, color: color),
                      title: Text(
                        'Alert #${index + 1}: ${severity.toUpperCase()}',
                        style: kBodyTextStyle.copyWith(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Position: (${position['lat']}, ${position['lon']})',
                        style: kSecondaryBodyTextStyle,
                      ),
                      onTap: () {
                        // Optional: Add functionality to show details or navigate
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
