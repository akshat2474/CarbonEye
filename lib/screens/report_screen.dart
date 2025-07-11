import 'package:carboneye/models/report_data.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatelessWidget {
  final ReportData reportData;

  const ReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Impact Report'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Export feature is not yet implemented.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummaryMetrics(),
            const SizedBox(height: 24),
            _buildSeverityChart(),
            const SizedBox(height: 24),
            _buildCriticalDetectionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deforestation Analysis for ${reportData.region.name}',
          style: kSectionTitleStyle.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Report Period: ${DateFormat.yMMMd().format(reportData.startDate)} - ${DateFormat.yMMMd().format(reportData.endDate)}',
          style: kSecondaryBodyTextStyle,
        ),
      ],
    );
  }

  Widget _buildSummaryMetrics() {
    return Column(
      children: [
        _buildMetricCard(
            'Total Detections', reportData.totalDetections.toString()),
        const SizedBox(height: 12),
        _buildMetricCard(
            'Critical Alerts', reportData.criticalAlerts.toString(),
            color: Colors.red.shade300),
        const SizedBox(height: 12),
        _buildMetricCard('High Alerts', reportData.highAlerts.toString(),
            color: Colors.orange.shade300),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: kSecondaryBodyTextStyle.copyWith(fontSize: 15)),
          Text(
            value,
            style: kStatValueStyle.copyWith(
                fontSize: 24, color: color ?? kWhiteColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detections by Severity',
              style: kBodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildBar('Critical', reportData.criticalAlerts, Colors.red.shade400),
          const SizedBox(height: 12),
          _buildBar('High', reportData.highAlerts, Colors.orange.shade400),
          const SizedBox(height: 12),
          _buildBar('Medium', reportData.mediumAlerts, Colors.yellow.shade400),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color) {
    final double total = reportData.totalDetections > 0
        ? reportData.totalDetections.toDouble()
        : 1;
    final double fraction = value / total;
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label, style: kSecondaryBodyTextStyle)),
        Expanded(
          child: Tooltip(
            message: '$value detections',
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4))),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 40, child: Text(' $value', style: kBodyTextStyle)),
      ],
    );
  }

  Widget _buildCriticalDetectionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Most Significant Detections',
            style: kSectionTitleStyle.copyWith(fontSize: 20)),
        const SizedBox(height: 12),
        if (reportData.mostSevereDetections.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: kCardColor, borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text('No significant detections in this period.',
                    style: kSecondaryBodyTextStyle)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reportData.mostSevereDetections.length,
            itemBuilder: (context, index) {
              final detection = reportData.mostSevereDetections[index];
              final center = detection['center_coordinates'];
              final severity = detection['severity']?.toString() ?? 'Medium';
              double areaValue = 0.0;
              if (detection['area_ha'] != null && detection['area_ha'] is num) {
                areaValue = detection['area_ha'];
              }

              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                    color: kCardColor, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Severity: $severity',
                              style: kBodyTextStyle.copyWith(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                              'Location: ${center['latitude'].toStringAsFixed(4)}, ${center['longitude'].toStringAsFixed(4)}',
                              style: kSecondaryBodyTextStyle,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (areaValue > 0)
                      Text(
                        '${areaValue.toStringAsFixed(2)} ha',
                        style: kBodyTextStyle.copyWith(
                            color: kAccentColor, fontWeight: FontWeight.bold),
                      )
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          ),
      ],
    );
  }
}
