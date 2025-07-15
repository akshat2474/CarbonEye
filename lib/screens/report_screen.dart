import 'package:carboneye/models/report_data.dart';
import 'package:carboneye/services/pdf_generator.dart'; // Import the new service
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/neu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget { // Convert to StatefulWidget
  final ReportData reportData;

  const ReportScreen({super.key, required this.reportData});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> { // Create State
  bool _isGeneratingPdf = false;

  Future<void> _handlePdfGeneration() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfGenerator.generateAndShareReport(widget.reportData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Impact Report'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        actions: [
          // New Download PDF Button
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: kWhiteColor,
                      strokeWidth: 2.0,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Download as PDF',
            onPressed: _isGeneratingPdf ? null : _handlePdfGeneration,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Share feature is not yet implemented.')),
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
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  // --- All other build methods remain the same ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deforestation Analysis for ${widget.reportData.region.name}',
          style: kSectionTitleStyle.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'Report Period: ${DateFormat.yMMMd().format(widget.reportData.startDate)} - ${DateFormat.yMMMd().format(widget.reportData.endDate)}',
          style: kSecondaryBodyTextStyle,
        ),
      ],
    );
  }

  Widget _buildSummaryMetrics() {
    return Column(
      children: [
        _buildMetricCard(
            'Total Detections', widget.reportData.totalDetections.toString()),
        const SizedBox(height: 12),
        _buildMetricCard(
            'Critical Alerts', widget.reportData.criticalAlerts.toString(),
            color: Colors.red.shade300),
        const SizedBox(height: 12),
        _buildMetricCard('High Alerts', widget.reportData.highAlerts.toString(),
            color: Colors.orange.shade300),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, {Color? color}) {
    return NeuCard(
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
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detections by Severity',
              style: kBodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildBar('Critical', widget.reportData.criticalAlerts, Colors.red.shade400),
          const SizedBox(height: 12),
          _buildBar('High', widget.reportData.highAlerts, Colors.orange.shade400),
          const SizedBox(height: 12),
          _buildBar('Medium', widget.reportData.mediumAlerts, Colors.yellow.shade400),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, Color color) {
    final double total = widget.reportData.totalDetections > 0
        ? widget.reportData.totalDetections.toDouble()
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
              clipBehavior: Clip.antiAlias,
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
        if (widget.reportData.mostSevereDetections.isEmpty)
          NeuCard(
            child: Center(
                child: Text('No significant detections in this period.',
                    style: kSecondaryBodyTextStyle)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.reportData.mostSevereDetections.length,
            itemBuilder: (context, index) {
              final detection = widget.reportData.mostSevereDetections[index];
              final center = detection['center_coordinates'];
              final severity = detection['severity']?.toString() ?? 'Medium';
              double areaValue = 0.0;
              if (detection['area_ha'] != null && detection['area_ha'] is num) {
                areaValue = detection['area_ha'];
              }

              return NeuCard(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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