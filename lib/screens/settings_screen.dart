import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/services/notification_service.dart';
import 'package:carboneye/screens/privacy_policy_screen.dart';
import 'package:carboneye/screens/edit_account_screen.dart';
import 'package:carboneye/utils/file_helper.dart';
import 'package:carboneye/screens/log_viewer_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _pushNotificationsEnabled = false;
  bool _emailNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadPreferences();
  }
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotificationsEnabled = prefs.getBool('pushNotificationsEnabled') ?? false;
      _emailNotificationsEnabled = prefs.getBool('emailNotificationsEnabled') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _handlePushToggle(bool value) async {
    if (value) {
      final bool? permissionGranted = await _notificationService.requestPermissions();
      if (mounted) {
        if (permissionGranted ?? false) {
          setState(() => _pushNotificationsEnabled = true);
          await _savePreference('pushNotificationsEnabled', true);
          await _notificationService.showTestNotification();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission denied. Notifications cannot be enabled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      setState(() => _pushNotificationsEnabled = false);
      await _savePreference('pushNotificationsEnabled', false);
    }
  }

  Future<void> _handleEmailToggle(bool value) async {
    if (value) {
      final email = await _showEmailInputDialog();
      if (email != null && email.isNotEmpty) {
        await FileHelper.writeEmailToLog(email);
        setState(() => _emailNotificationsEnabled = true);
        await _savePreference('emailNotificationsEnabled', true);
      }
    } else {
      setState(() => _emailNotificationsEnabled = false);
      await _savePreference('emailNotificationsEnabled', false);
    }
  }

  Future<String?> _showEmailInputDialog() async {
    final TextEditingController emailController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        title: Text('Enable Email Notifications', style: kAppTitleStyle.copyWith(fontSize: 20)),
        content: TextField(
          controller: emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: kBodyTextStyle,
          decoration: InputDecoration(
            hintText: "your.email@example.com",
            hintStyle: kSecondaryBodyTextStyle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: kSecondaryBodyTextStyle),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(emailController.text),
            child: const Text('Confirm', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text("Settings", style: kAppTitleStyle),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kWhiteColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Notifications", style: kSectionTitleStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                SwitchListTile(
                  title: Text("Push Notifications", style: kBodyTextStyle),
                  value: _pushNotificationsEnabled,
                  onChanged: _handlePushToggle,
                  activeColor: kAccentColor,
                ),
                const Divider(color: kBackgroundColor, height: 1),
                SwitchListTile(
                  title: Text("Email Notifications", style: kBodyTextStyle),
                  value: _emailNotificationsEnabled,
                  onChanged: _handleEmailToggle,
                  activeColor: kAccentColor,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text("Account", style: kSectionTitleStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.person_outline,
                  title: "Edit Account Details",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditAccountScreen())),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text("About", style: kSectionTitleStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.shield_outlined,
                  title: "Privacy Policy",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text("Developer", style: kSectionTitleStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            _buildSettingsCard(
              children: [
                _buildSettingsTile(
                  icon: Icons.description_outlined,
                  title: "View Email Log",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LogViewerScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12.0)),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: kSecondaryTextColor),
      title: Text(title, style: kBodyTextStyle),
      trailing: const Icon(Icons.arrow_forward_ios, color: kSecondaryTextColor, size: 16),
      onTap: onTap,
    );
  }
}
