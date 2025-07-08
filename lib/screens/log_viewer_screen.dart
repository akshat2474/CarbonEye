import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/utils/file_helper.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  String _logContent = "Loading log data...";

  @override
  void initState() {
    super.initState();
    _loadLogFile();
  }

  Future<void> _loadLogFile() async {
    final content = await FileHelper.readEmailLog();
    if (mounted) {
      setState(() {
        _logContent = content;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Email Log Viewer", style: kAppTitleStyle),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          _logContent,
          style: kSecondaryBodyTextStyle.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
