import 'dart:async';
import 'package:carboneye/models/annotation.dart';
import 'package:carboneye/models/watchlist_item.dart';
import 'package:carboneye/screens/all_alerts_screen.dart';
import 'package:carboneye/screens/annotation_screen.dart';
import 'package:carboneye/screens/report_screen.dart';
import 'package:carboneye/screens/settings_screen.dart';
import 'package:carboneye/services/api_service.dart';
import 'package:carboneye/services/report_generator.dart';
import 'package:carboneye/utils/constants.dart';
import 'package:carboneye/widgets/dashboard_item.dart';
import 'package:carboneye/widgets/map_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  String _selectedMapFilter = 'Heatmap';
  List<Map<String, dynamic>> _detections = [];
  bool _isLoading = false;
  DateTime _lastSynced = DateTime.now();
  WatchlistItem? _activeWatchlistItem;

  final List<WatchlistItem> _watchlistRegions = [
    WatchlistItem(
      name: 'Amazonas, Brazil',
      coordinates: const LatLng(-3.46, -62.21),
      bbox: [-62.2159, -3.4653, -62.1159, -3.3653],
      annotations: [Annotation(id: '1', text: "Initial area of concern noted.", timestamp: DateTime.now())],
    ),
    WatchlistItem(
      name: 'Congo Basin, DRC',
      coordinates: const LatLng(0.5, 23.5),
      bbox: [17.9416, 0.4598, 18.1416, 0.6598],
    ),
    WatchlistItem(
      name: 'Borneo, Indonesia',
      coordinates: const LatLng(1.0, 114.0),
      bbox: [113.9, 0.9, 114.1, 1.1],
    ),
  ];

  final Map<String, dynamic> _availableForestsData = {
    'Sumatra, Indonesia': {'coordinates': const LatLng(0.5897, 101.3431), 'bbox': [101.2431, 0.4897, 101.4431, 0.6897]},
    'New Guinea': {'coordinates': const LatLng(-5.5, 141.5), 'bbox': [141.0, -6.0, 142.0, -5.0]},
    'Madagascar': {'coordinates': const LatLng(-18.9, 47.5), 'bbox': [47.0, -19.4, 48.0, -18.4]},
  };
  
  Future<void> _runAnalysis(WatchlistItem item) async {
    setState(() {
      _isLoading = true;
      _detections = [];
      _activeWatchlistItem = item;
    });

    try {
      final result = await _apiService.analyzeRegion(item.bbox);
      if (!mounted) return;
      final newDetections = List<Map<String, dynamic>>.from(result['detections']);
      setState(() {
        _detections = newDetections;
        _lastSynced = DateTime.now();
      });
      if (newDetections.isNotEmpty) {
        _fitMapToDetections(newDetections);
      } else {
        _mapController.move(item.coordinates, 8.0);
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Analysis complete: ${newDetections.length} detections found for ${item.name}."),
        backgroundColor: Colors.green.shade700,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('API Error: ${e.toString()}'),
        backgroundColor: Colors.red.shade700,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fitMapToDetections(List<Map<String, dynamic>> detections) {
    if (detections.isEmpty) return;
    final points = detections.map((d) {
      final coords = d['center_coordinates'];
      return LatLng(coords['latitude'], coords['longitude']);
    }).toList();
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)));
  }

  void _addToWatchlist(String regionName) {
    if (_availableForestsData.containsKey(regionName) && !_watchlistRegions.any((item) => item.name == regionName)) {
      final data = _availableForestsData[regionName]!;
      setState(() {
        final newItem = WatchlistItem(name: regionName, coordinates: data['coordinates'], bbox: data['bbox']);
        _watchlistRegions.add(newItem);
        _runAnalysis(newItem);
      });
    }
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
                    detectionMarkers: _buildDetectionMarkers(),
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
        onPressed: () {
          final WatchlistItem? itemToRefresh = _activeWatchlistItem ?? (_watchlistRegions.isNotEmpty ? _watchlistRegions.first : null);
          if (itemToRefresh != null) {
            _runAnalysis(itemToRefresh);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Add a region to your watchlist to run an analysis."),
            ));
          }
        },
        backgroundColor: kAccentColor,
        tooltip: 'Refresh Analysis',
        child: _isLoading ? const CircularProgressIndicator(color: kBackgroundColor, strokeWidth: 2.0) : const Icon(Icons.refresh, color: kBackgroundColor),
      ),
    );
  }

  Widget _buildDashboardList() {
    return Column(
      children: [
        DashboardItem(icon: Icons.track_changes, title: "Analyze New Region", subtitle: "Select an area for one-time analysis", onTap: _showAddWatchlistDialog),
        const SizedBox(height: 12),
        DashboardItem(
          icon: Icons.notifications_active_outlined,
          title: "View All Alerts",
          subtitle: "Review deforestation events from last analysis",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllAlertsScreen(detections: _detections))),
        ),
        const SizedBox(height: 12),
        DashboardItem(
          icon: Icons.document_scanner_outlined,
          title: "Generate Report",
          subtitle: "Create a detailed ESG or impact report",
          onTap: () {
            final WatchlistItem? regionToReportOn = _activeWatchlistItem ?? (_watchlistRegions.isNotEmpty ? _watchlistRegions.first : null);

            if (regionToReportOn == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Please add a region to your watchlist first."),
                backgroundColor: Colors.orange,
              ));
              return;
            }

            final reportData = ReportGenerator.generateReport(
              region: regionToReportOn,
              detections: _detections,
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportScreen(reportData: reportData)),
            );
          },
        ),
        const SizedBox(height: 12),
        DashboardItem(
          icon: Icons.settings_outlined,
          title: "Settings",
          subtitle: "Configure notifications and account details",
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
      ],
    );
  }

  List<Marker> _buildDetectionMarkers() {
    return _detections.map((detection) {
      final center = detection['center_coordinates'];
      final severity = detection['severity']?.toString().toLowerCase() ?? 'medium';
      Color markerColor;
      switch (severity) {
        case 'critical': markerColor = Colors.red.withAlpha(200); break;
        case 'high': markerColor = Colors.orange.withAlpha(200); break;
        default: markerColor = Colors.yellow.withAlpha(200);
      }
      return Marker(
        width: 18.0, height: 18.0,
        point: LatLng(center['latitude'], center['longitude']),
        child: Tooltip(
          message: 'Severity: $severity\nArea: ${detection['area_ha']} ha',
          child: Container(decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5))),
        ),
      );
    }).toList();
  }
  

  List<Marker> _buildWatchlistMarkers() {
    return _watchlistRegions.map((item) {
      return Marker(
        width: 24.0, height: 24.0,
        point: item.coordinates,
        child: Container(decoration: BoxDecoration(color: kAccentColor.withOpacity(0.4), shape: BoxShape.circle, border: Border.all(color: kAccentColor, width: 2)),
          child: const Center(child: Icon(Icons.push_pin, color: kWhiteColor, size: 12)),
        ),
      );
    }).toList();
  }

  Widget _buildWatchlist() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("My Watchlist", style: kSectionTitleStyle.copyWith(fontSize: 24)),
        TextButton.icon(onPressed: _showAddWatchlistDialog, icon: const Icon(Icons.add, color: kAccentColor, size: 20), label: const Text('Add', style: TextStyle(color: kAccentColor))),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12.0)),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _watchlistRegions.length,
          itemBuilder: (context, index) {
            final item = _watchlistRegions[index];
            return ListTile(
              leading: IconButton(icon: Icon(Icons.chat_bubble_outline, color: item.annotations.isNotEmpty ? kAccentColor : kSecondaryTextColor),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnnotationScreen(watchlistItem: item))),
              ),
              title: Text(item.name, style: kBodyTextStyle),
              trailing: const Icon(Icons.arrow_forward_ios, color: kSecondaryTextColor, size: 16),
              onTap: () => _runAnalysis(item),
            );
          },
          separatorBuilder: (context, index) => const Divider(color: kBackgroundColor, height: 1, indent: 16, endIndent: 16),
        ),
      ),
    ]);
  }

  Widget _buildMapFilters() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Heatmap', 'Satellite', 'Political'].map((filter) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: FilterChip(
          label: Text(filter),
          selected: _selectedMapFilter == filter,
          onSelected: (selected) { if (selected) setState(() => _selectedMapFilter = filter); },
          backgroundColor: kCardColor,
          selectedColor: kAccentColor,
          labelStyle: TextStyle(color: _selectedMapFilter == filter ? kBackgroundColor : kWhiteColor),
          checkmarkColor: kBackgroundColor,
        ),
      );
    }).toList()));
  }

  Widget _buildLastSynced() {
    final difference = DateTime.now().difference(_lastSynced);
    String timeAgo = (difference.inSeconds < 5) ? 'just now' : '${difference.inSeconds}s ago';
    if (difference.inMinutes >= 1) timeAgo = '${difference.inMinutes}m ago';
    if (difference.inHours >= 1) timeAgo = '${difference.inHours}h ago';
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Last updated: $timeAgo', style: kSecondaryBodyTextStyle.copyWith(fontSize: 12))]);
  }

  Widget _buildHeroSection() {
    return Stack(alignment: Alignment.bottomLeft, children: [
      Image.asset('assets/images/satellite_forest.png', height: 350, width: double.infinity, fit: BoxFit.cover),
      Container(height: 350, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, kBackgroundColor], stops: [0.4, 1.0]))),
      Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text("Real-time intelligence.", style: kSectionTitleStyle),
        Text("Zero trees lost.", style: kSectionTitleStyle.copyWith(color: kAccentColor)),
        const SizedBox(height: 16),
        Text("Automated satellite analysis to protect our vital ecosystems.", style: kSecondaryBodyTextStyle),
      ])),
    ]);
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12.0)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatItem("Active Alerts", _detections.length.toString()),
        _buildStatItem("Regions", _watchlistRegions.length.toString()),
      ]),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(children: [Text(value, style: kStatValueStyle), const SizedBox(height: 4), Text(title, style: kSecondaryBodyTextStyle)]);
  }

  Future<void> _showAddWatchlistDialog() async {
    String? selectedForest;
    return showDialog<void>(context: context, builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: kCardColor,
        title: Text('Add to Watchlist', style: kAppTitleStyle.copyWith(fontSize: 20)),
        content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return DropdownButton<String>(
            isExpanded: true,
            value: selectedForest,
            hint: Text('Select a forest to monitor', style: kSecondaryBodyTextStyle),
            dropdownColor: kCardColor,
            style: kBodyTextStyle,
            icon: const Icon(Icons.arrow_drop_down, color: kAccentColor),
            underline: Container(height: 1, color: kAccentColor),
            items: _availableForestsData.keys.where((forest) => !_watchlistRegions.any((item) => item.name == forest)).map((String forest) => DropdownMenuItem<String>(value: forest, child: Text(forest))).toList(),
            onChanged: (String? newValue) => setState(() => selectedForest = newValue),
          );
        }),
        actions: <Widget>[
          TextButton(child: Text('Cancel', style: kSecondaryBodyTextStyle), onPressed: () => Navigator.of(context).pop()),
          TextButton(child: const Text('Add', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)), onPressed: () {
            if (selectedForest != null) {
              _addToWatchlist(selectedForest!);
              Navigator.of(context).pop();
            }
          }),
        ],
      );
    });
  }
}