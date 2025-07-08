import 'package:flutter/material.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/map_preview.dart';
import 'package:carboneye/widgets/dashboard_item.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:carboneye/models/watchlist_item.dart';
import 'package:carboneye/models/annotation.dart';
import 'package:carboneye/screens/annotation_screen.dart';
import 'package:carboneye/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final Random _random = Random();

  String _selectedMapFilter = 'Heatmap';
  final List<WatchlistItem> _watchlistRegions = [
    WatchlistItem(name: 'Amazonas, Brazil', coordinates: const LatLng(-3.46, -62.21)),
    WatchlistItem(name: 'Congo Basin, DRC', coordinates: const LatLng(0.5, 23.5)),
    WatchlistItem(
      name: 'Borneo, Indonesia',
      coordinates: const LatLng(1.0, 114.0),
      annotations: [Annotation(text: "Initial area of concern noted.", timestamp: DateTime.now().subtract(const Duration(days: 1)))],
    ),
  ];
  DateTime _lastSynced = DateTime.now();
  bool _isRefreshing = false;

  void _addToWatchlist(String regionName) {
    if (regionName.isNotEmpty && !_watchlistRegions.any((item) => item.name == regionName)) {
      final newCoords = LatLng(
        _random.nextDouble() * 180 - 90,
        _random.nextDouble() * 360 - 180,
      );

      setState(() {
        _watchlistRegions.add(WatchlistItem(name: regionName, coordinates: newCoords));
        _mapController.move(newCoords, 6.0);
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _lastSynced = DateTime.now();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _showAddWatchlistDialog() async {
    String? selectedForest;
    final List<String> availableForests = [
      'Sumatra, Indonesia', 'New Guinea', 'Madagascar', 'Siberian Taiga',
    ];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text('Add to Watchlist', style: kAppTitleStyle.copyWith(fontSize: 20)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<String>(
                isExpanded: true,
                value: selectedForest,
                hint: Text('Select a forest to monitor', style: kSecondaryBodyTextStyle),
                dropdownColor: kCardColor,
                style: kBodyTextStyle,
                icon: const Icon(Icons.arrow_drop_down, color: kAccentColor),
                underline: Container(height: 1, color: kAccentColor),
                items: availableForests
                    .where((forest) => !_watchlistRegions.any((item) => item.name == forest))
                    .map((String forest) {
                  return DropdownMenuItem<String>(value: forest, child: Text(forest));
                }).toList(),
                onChanged: (String? newValue) => setState(() => selectedForest = newValue),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: kSecondaryBodyTextStyle),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (selectedForest != null) {
                  _addToWatchlist(selectedForest!);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Marker> _buildWatchlistMarkers() {
    return _watchlistRegions.map((item) {
      return Marker(
        width: 24.0, height: 24.0, point: item.coordinates,
        child: Container(
          decoration: BoxDecoration(
            color: kAccentColor.withOpacity(0.4),
            shape: BoxShape.circle,
            border: Border.all(color: kAccentColor, width: 2),
          ),
          child: const Center(child: Icon(Icons.push_pin, color: kWhiteColor, size: 12)),
        ),
      );
    }).toList();
  }

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
                  _buildMapFilters(),
                  const SizedBox(height: 12),
                  MapPreview(
                    selectedLayer: _selectedMapFilter,
                    mapController: _mapController,
                    watchlistMarkers: _buildWatchlistMarkers(),
                  ),
                  const SizedBox(height: 8),
                  _buildLastSynced(),
                  const SizedBox(height: 30),
                  _buildWatchlist(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: kAccentColor,
        tooltip: 'Refresh Data',
        child: _isRefreshing
            ? const CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2.0)
            : const Icon(Icons.refresh, color: kBackgroundColor),
      ),
    );
  }

  Widget _buildWatchlist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("My Watchlist", style: kSectionTitleStyle.copyWith(fontSize: 24)),
            TextButton.icon(
              onPressed: _showAddWatchlistDialog,
              icon: const Icon(Icons.add, color: kAccentColor, size: 20),
              label: const Text('Add', style: TextStyle(color: kAccentColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _watchlistRegions.length,
            itemBuilder: (context, index) {
              final item = _watchlistRegions[index];
              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: item.annotations.isNotEmpty ? kAccentColor : kSecondaryTextColor,
                  ),
                  onPressed: () async {
                    final updatedAnnotations = await Navigator.push<List<Annotation>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnotationScreen(watchlistItem: item),
                      ),
                    );

                    if (updatedAnnotations != null) {
                      setState(() {
                        item.annotations.clear();
                        item.annotations.addAll(updatedAnnotations);
                      });
                    }
                  },
                ),
                title: Text(item.name, style: kBodyTextStyle),
                trailing: const Icon(Icons.arrow_forward_ios, color: kSecondaryTextColor, size: 16),
                onTap: () => _mapController.move(item.coordinates, 6.0),
              );
            },
            separatorBuilder: (context, index) => const Divider(
              color: kBackgroundColor, height: 1, indent: 16, endIndent: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardList() {
    return Column(
      children: [
        DashboardItem(
          icon: Icons.track_changes,
          title: "Analyze New Region",
          subtitle: "Select an area for one-time analysis",
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
        // --- THIS ITEM IS NOW FUNCTIONAL ---
        DashboardItem(
          icon: Icons.settings_outlined,
          title: "Settings",
          subtitle: "Configure notifications and account details",
          onTap: () {
            // Navigate to the new SettingsScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }


  Widget _buildMapFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Heatmap', 'Satellite', 'Political'].map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedMapFilter == filter,
              onSelected: (selected) {
                if (selected) setState(() => _selectedMapFilter = filter);
              },
              backgroundColor: kCardColor,
              selectedColor: kAccentColor,
              labelStyle: TextStyle(color: _selectedMapFilter == filter ? kBackgroundColor : kWhiteColor),
              checkmarkColor: kBackgroundColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLastSynced() {
    final now = DateTime.now();
    final difference = now.difference(_lastSynced);
    String timeAgo;
    if (difference.inSeconds < 60) {
      timeAgo = 'just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else {
      timeAgo = '${difference.inHours}h ago';
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Last updated: $timeAgo', style: kSecondaryBodyTextStyle.copyWith(fontSize: 12)),
      ],
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
              Text("Real-time intelligence.", style: kSectionTitleStyle),
              Text("Zero trees lost.", style: kSectionTitleStyle.copyWith(color: kAccentColor)),
              const SizedBox(height: 16),
              Text("Automated satellite analysis to protect our vital ecosystems.", style: kSecondaryBodyTextStyle),
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

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(value, style: kStatValueStyle),
        const SizedBox(height: 4),
        Text(title, style: kSecondaryBodyTextStyle),
      ],
    );
  }
}
