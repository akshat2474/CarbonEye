import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
import 'package:carboneye/widgets/neu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _selectedMapFilter = 'Satellite';
  List<Map<String, dynamic>> _detections = [];
  bool _isLoading = false;
  DateTime _lastSynced = DateTime.now();
  WatchlistItem? _activeWatchlistItem;

  bool _isSelectionMode = false;
  List<LatLng> _selectionPoints = [];

  String? _t0ImageBase64;
  String? _t1ImageBase64;

  final List<WatchlistItem> _watchlistRegions = [
    WatchlistItem(name: 'Amazonas, Brazil', coordinates: const LatLng(-3.46, -62.21), bbox: [-62.2159, -3.4653, -62.1159, -3.3653], annotations: [Annotation(id: '1', text: "Initial area of concern noted.", timestamp: DateTime.now())]),
    WatchlistItem(name: 'Congo Basin, DRC', coordinates: const LatLng(0.5, 23.5), bbox: [17.9416, 0.4598, 18.1416, 0.6598]),
    WatchlistItem(name: 'Borneo, Indonesia', coordinates: const LatLng(1.0, 114.0), bbox: [113.9, 0.9, 114.1, 1.1]),
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
      _t0ImageBase64 = null;
      _t1ImageBase64 = null;
      _activeWatchlistItem = item;
    });

    try {
      final result = await _apiService.analyzeRegionWithImages(item.bbox);
      if (!mounted) return;

      final analysisData = result['analysis'];
      final imageData = result['images'];

      final newDetections = List<Map<String, dynamic>>.from(analysisData['detections']);

      setState(() {
        _detections = newDetections;
        _t0ImageBase64 = imageData['t0_image'];
        _t1ImageBase64 = imageData['t1_image'];
        _lastSynced = DateTime.now();
      });

      final List<LatLng> validPoints = newDetections.map((d) {
        final coords = d['center_coordinates'];
        if (coords is Map && coords['latitude'] is num && coords['longitude'] is num) {
          return LatLng((coords['latitude'] as num).toDouble(), (coords['longitude'] as num).toDouble());
        }
        return null;
      }).whereType<LatLng>().toList();

      if (validPoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(validPoints);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
        );
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

  List<Marker> _buildDetectionMarkers() {
    return _detections.map((detection) {
      final center = detection['center_coordinates'];
      if (center is! Map || center['latitude'] is! num || center['longitude'] is! num) {
        return null;
      }

      final lat = (center['latitude'] as num).toDouble();
      final lon = (center['longitude'] as num).toDouble();

      final severity = detection['severity']?.toString().toLowerCase() ?? 'medium';
      final Color markerColor = _getSeverityColor(severity);

      final areaHa = (detection['area_ha'] as num? ?? 0);

      return Marker(
        width: 24.0, height: 24.0,
        point: LatLng(lat, lon),
        child: GestureDetector(
          onTap: () => _showDetectionDetailsDialog(detection),
          child: Tooltip(
            message: 'Severity: $severity\nArea: ${areaHa.toStringAsFixed(2)} ha\n(Tap for details)',
            child: Container(
              decoration: BoxDecoration(
                color: markerColor.withAlpha(220),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 2.0)
              ),
               child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.white.withOpacity(0.9),
                size: 14,
              ),
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSummary(),
                      const SizedBox(height: 30),
                      Text("Global Deforestation Hotspots", style: kSectionTitleStyle),
                      const SizedBox(height: 16),
                      _buildMapFilters(),
                      const SizedBox(height: 12),
                      MapPreview(
                        selectedLayer: _selectedMapFilter,
                        mapController: _mapController,
                        watchlistMarkers: _buildWatchlistMarkers(),
                        detectionMarkers: _buildDetectionMarkers(),
                        detectionPolygons: const [], 
                        isSelectionMode: _isSelectionMode,
                        selectionPoints: _selectionPoints,
                        onMapTap: _onMapTapped,
                      ),
                      const SizedBox(height: 8),
                      if (_isSelectionMode) _buildSelectionControls(),
                      if (_t0ImageBase64 != null && _t1ImageBase64 != null)
                        _buildImageComparison(),
                      _buildLastSynced(),
                      const SizedBox(height: 30),
                      _buildWatchlist(),
                      const SizedBox(height: 30),
                      Text("Dashboard", style: kSectionTitleStyle),
                      const SizedBox(height: 16),
                      _buildDashboardList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
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

  Widget _buildImageComparison() {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: NeuCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Satellite Image Comparison", style: kSectionTitleStyle.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text("Comparing imagery from before and after the analysis period.", style: kSecondaryBodyTextStyle),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildImageColumn("Before", _t0ImageBase64!),
                const SizedBox(width: 16),
                _buildImageColumn("After", _t1ImageBase64!),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildImageColumn(String title, String base64String) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: kBodyTextStyle.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.memory(
              base64Decode(base64String.split(',').last),
              fit: BoxFit.cover,
              gaplessPlayback: true, 
              errorBuilder: (context, error, stackTrace) {
                return const AspectRatio(
                  aspectRatio: 1,
                  child: Center(
                    child: Icon(Icons.error_outline, color: Colors.red, size: 40),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      backgroundColor: kBackgroundColor,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/satellite_forest.png',
              fit: BoxFit.cover,
            ).animate().fadeIn(duration: 500.ms),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, kBackgroundColor],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Real-time intelligence.", style: kSectionTitleStyle.copyWith(fontSize: 30)),
                  Text("Zero trees lost.", style: kSectionTitleStyle.copyWith(color: kAccentColor, fontSize: 30)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(children: [Text(value, style: kStatValueStyle), const SizedBox(height: 4), Text(title, style: kSecondaryBodyTextStyle)]);
  }

  Widget _buildStatsSummary() {
    return NeuCard(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildStatItem("Active Alerts", _detections.length.toString()),
        _buildStatItem("Regions", _watchlistRegions.length.toString()),
        _buildStatItem("Area (ha)", _calculateTotalArea()),
      ]),
    ).animate().slideY(delay: 200.ms, duration: 400.ms, curve: Curves.easeOut);
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      if (_selectionPoints.length >= 2) {
        _selectionPoints = [point];
      } else {
        _selectionPoints.add(point);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectionPoints = [];
      if (_isSelectionMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selection Mode Enabled: Tap two corners on the map to define a region.'),
            backgroundColor: kAccentColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _runAnalysisOnSelection() {
    if (_selectionPoints.length < 2) return;

    final point1 = _selectionPoints[0];
    final point2 = _selectionPoints[1];

    final tempItem = WatchlistItem(
      name: "Custom Selection",
      coordinates: LatLng((point1.latitude + point2.latitude) / 2, (point1.longitude + point2.longitude) / 2),
      bbox: [
        min(point1.longitude, point2.longitude),
        min(point1.latitude, point2.latitude),
        max(point1.longitude, point2.longitude),
        max(point1.latitude, point2.latitude),
      ],
    );

    _runAnalysis(tempItem);
    setState(() {
      _isSelectionMode = false;
      _selectionPoints = [];
    });
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

  void _showDetectionDetailsDialog(Map<String, dynamic> detection) {
    final severity = detection['severity']?.toString() ?? 'Medium';
    final area = (detection['area_ha'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final center = detection['center_coordinates'];
    final lat = (center['latitude'] as num?)?.toStringAsFixed(4) ?? 'N/A';
    final lon = (center['longitude'] as num?)?.toStringAsFixed(4) ?? 'N/A';
    final Color severityColor = _getSeverityColor(severity);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: kCardColor,
          title: Text('Detection Details', style: kSectionTitleStyle.copyWith(fontSize: 20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Severity:', severity.capitalize(), color: severityColor),
              const SizedBox(height: 12),
              _buildDetailRow('Area Affected:', '$area ha'),
              const SizedBox(height: 12),
              _buildDetailRow('Coordinates:', '$lat, $lon'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close', style: TextStyle(color: kAccentColor, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: kSecondaryBodyTextStyle),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: kBodyTextStyle.copyWith(fontWeight: FontWeight.bold, color: color ?? kWhiteColor))),
    ]);
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return Colors.red.shade400;
      case 'high': return Colors.orange.shade400;
      default: return Colors.yellow.shade400;
    }
  }

  Widget _buildSelectionControls() {
    bool canAnalyze = _selectionPoints.length == 2;
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: kAccentColor.withOpacity(0.5))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text("Tap two corners to define an area.", style: kSecondaryBodyTextStyle)),
        const SizedBox(width: 12),
        TextButton(onPressed: _toggleSelectionMode, child: const Text("Cancel"), style: TextButton.styleFrom(foregroundColor: kWhiteColor)),
        ElevatedButton.icon(
          onPressed: canAnalyze ? _runAnalysisOnSelection : null,
          icon: const Icon(Icons.analytics_outlined, size: 18),
          label: const Text("Analyze"),
          style: ElevatedButton.styleFrom(backgroundColor: kAccentColor, foregroundColor: kBackgroundColor, disabledBackgroundColor: Colors.grey.shade700),
        )
      ]),
    );
  }

  Widget _buildDashboardList() {
    return Column(children: [
      DashboardItem(
        icon: _isSelectionMode ? Icons.cancel_outlined : Icons.track_changes,
        title: "Analyze New Region",
        subtitle: _isSelectionMode ? "Selection mode is active" : "Select an area on the map",
        onTap: _toggleSelectionMode,
      ),
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add a region to your watchlist first."), backgroundColor: Colors.orange));
            return;
          }
          final reportData = ReportGenerator.generateReport(region: regionToReportOn, detections: _detections);
          Navigator.push(context, MaterialPageRoute(builder: (context) => ReportScreen(reportData: reportData)));
        },
      ),
      const SizedBox(height: 12),
      DashboardItem(
        icon: Icons.settings_outlined,
        title: "Settings",
        subtitle: "Configure notifications and account details",
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
      ),
    ]);
  }

  String _calculateTotalArea() {
    if (_detections.isEmpty) return "0";
    final totalHa = _detections.fold<double>(0.0, (sum, item) => sum + (item['area_ha'] ?? 0.0));
    if (totalHa > 1000000) return '${(totalHa / 1000000).toStringAsFixed(1)}M';
    if (totalHa > 1000) return '${(totalHa / 1000).toStringAsFixed(1)}K';
    return totalHa.toStringAsFixed(0);
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
        Text("My Watchlist", style: kSectionTitleStyle),
        TextButton.icon(onPressed: _showAddWatchlistDialog, icon: const Icon(Icons.add, color: kAccentColor, size: 20), label: const Text('Add', style: TextStyle(color: kAccentColor))),
      ]),
      const SizedBox(height: 8),
      NeuCard(
        padding: EdgeInsets.zero,
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
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Last updated: $timeAgo', style: kSecondaryBodyTextStyle.copyWith(fontSize: 12))]),
    );
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}