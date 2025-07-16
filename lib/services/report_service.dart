import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  Future<void> generateReport(
    String watchlistItemName,
    List<Map<String, dynamic>> detections,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Deforestation Alert Report'),
              ),
              pw.Paragraph(
                text: 'Watchlist Item: $watchlistItemName',
              ),
              pw.SizedBox(height: 20),
              pw.Text('Detected Alerts:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...detections.map(
                (alert) {
                  final position = alert['position'];
                  final severity =
                      alert['severity']?.toString().toLowerCase() ?? 'moderate';
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Severity: ${severity.toUpperCase()}'),
                        pw.Text(
                            'Position: Lat: ${position['lat']}, Lon: ${position['lon']}'),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/deforestation_report.pdf");
    await file.writeAsBytes(await pdf.save());
  }
}