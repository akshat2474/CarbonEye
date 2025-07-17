import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/neu_card.dart';
import 'package:flutter/material.dart';

class DashboardItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeuCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kAccentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: kBodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: kSecondaryBodyTextStyle.copyWith(fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: kSecondaryTextColor, size: 16),
          ],
        ),
      ),
    );
  }
}