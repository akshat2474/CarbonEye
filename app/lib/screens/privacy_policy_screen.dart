import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Privacy Policy", style: kAppTitleStyle),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          '''Last updated: July 08, 2025

Your privacy is important to us. It is CarbonEye's policy to respect your privacy regarding any information we may collect from you across our application.

1. Information We Collect
Log Data: When you opt-in for email notifications, we collect the email address you provide. This information is stored in a local log file on your device and is not transmitted to our servers automatically.

2. Use of Information
The email address you provide is used solely for the purpose of sending you email notifications as requested. We will not use this information for marketing purposes without your explicit consent.

3. Data Security
We are committed to ensuring that your information is secure. While no method of electronic storage is 100% secure, we strive to use commercially acceptable means to protect your personal information.

4. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.

Contact Us
If you have any questions about this Privacy Policy, please contact us.
''',
          style: kSecondaryBodyTextStyle.copyWith(height: 1.6),
        ),
      ),
    );
  }
}
