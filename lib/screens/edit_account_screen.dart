import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';

class EditAccountScreen extends StatelessWidget {
  const EditAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Edit Account", style: kAppTitleStyle),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextField(label: "Full Name", initialValue: "John Doe"),
            const SizedBox(height: 16),
            _buildTextField(label: "Username", initialValue: "johndoe"),
            const SizedBox(height: 16),
            _buildTextField(label: "Email Address", initialValue: "john.doe@example.com"),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // In a real app, this would save the data
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentColor,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Save Changes", style: kButtonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required String label, required String initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      style: kBodyTextStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: kSecondaryBodyTextStyle,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kAccentColor),
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kSecondaryTextColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
