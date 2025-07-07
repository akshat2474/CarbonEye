import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/map_preview.dart';
import 'package:carboneye/widgets/dashboard_item.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsSummary(),
                  const SizedBox(height: 30),
                  Text("Global Deforestation Hotspots", style: kSectionTitleStyle.copyWith(fontSize: 24)),
                  const SizedBox(height: 16),
                  MapPreview(),
                  const SizedBox(height: 30),
                  Text("Dashboard", style: kSectionTitleStyle.copyWith(fontSize: 24)),
                  const SizedBox(height: 16),
                  _buildDashboardList(), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Image.asset(
          'assets/images/satellite_forest.png',
          height: 350,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          height: 350,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, kBackgroundColor],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Real-time intelligence.",
                style: kSectionTitleStyle,
              ),
              Text(
                "Zero trees lost.",
                style: kSectionTitleStyle.copyWith(color: kAccentColor),
              ),
              const SizedBox(height: 16),
              Text(
                "Automated satellite analysis to protect our vital ecosystems.",
                style: kSecondaryBodyTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Active Alerts", "23"),
          _buildStatItem("Regions", "12"),
          _buildStatItem("Area (ha)", "1.2M"),
        ],
      ),
    );
  }

  // This section remains unchanged
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: kStatValueStyle),
        const SizedBox(height: 4),
        Text(title, style: kSecondaryBodyTextStyle),
      ],
    );
  }

  Widget _buildDashboardList() {
    return Column(
      children: [
        DashboardItem(
          icon: Icons.track_changes,
          title: "Analyze New Region",
          subtitle: "Select an area for real-time monitoring",
          onTap: () {},
        ),
        const SizedBox(height: 12),
        DashboardItem(
          icon: Icons.notifications_active_outlined,
          title: "View All Alerts",
          subtitle: "Review active and past deforestation events",
          onTap: () {},
        ),
        const SizedBox(height: 12),
        DashboardItem(
          icon: Icons.document_scanner_outlined,
          title: "Generate Report",
          subtitle: "Create a detailed ESG or impact report",
          onTap: () {},
        ),
        const SizedBox(height: 12),
        DashboardItem(
          icon: Icons.settings_outlined,
          title: "Settings",
          subtitle: "Configure notifications and account details",
          onTap: () {},
        ),
      ],
    );
  }
}
