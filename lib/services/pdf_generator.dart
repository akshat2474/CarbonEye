import 'dart:io';

import 'package:carboneye/models/report_data.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<File> generateReportFile(ReportData reportData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(reportData),
          pw.SizedBox(height: 20),
          _buildSummary(reportData),
          pw.SizedBox(height: 20),
          _buildDetectionsTable(reportData),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        "${output.path}/CarbonEye_Report_${reportData.region.name.replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<void> generateAndPrintReport(ReportData reportData) async {
    final file = await generateReportFile(reportData);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => file.readAsBytes(),
    );
  }

  static pw.Widget _buildHeader(ReportData reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CarbonEye Impact Report',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Region: ${reportData.region.name}',
          style: const pw.TextStyle(fontSize: 18),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Period: ${DateFormat.yMMMd().format(reportData.startDate)} - ${DateFormat.yMMMd().format(reportData.endDate)}',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
        ),
        pw.Divider(height: 20),
      ],
    );
  }

  static pw.Widget _buildSummary(ReportData reportData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Summary',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem(
                'Total Detections:', reportData.totalDetections.toString()),
            _summaryItem('Critical Alerts:', reportData.criticalAlerts.toString(),
                color: PdfColors.red),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _summaryItem('High Alerts:', reportData.highAlerts.toString(),
                color: PdfColors.orange),
            _summaryItem('Medium Alerts:', reportData.mediumAlerts.toString(),
                color: PdfColors.amber),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryItem(String title, String value,
      {PdfColor color = PdfColors.black}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: const pw.TextStyle(color: PdfColors.grey700)),
        pw.Text(value,
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  static pw.Widget _buildDetectionsTable(ReportData reportData) {
    final headers = ['Severity', 'Location (Lat, Lon)'];

    final data = reportData.mostSevereDetections.map((item) {
      final center = item['position'];
      return [
        item['severity']?.toString() ?? 'N/A',
        '${center['lat'].toStringAsFixed(4)}, ${center['lon'].toStringAsFixed(4)}',
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 20),
        pw.Text('Most Significant Detections',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
          },
        ),
      ],
    );
  }
}