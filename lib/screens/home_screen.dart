import 'package:carboneye/models/annotation.dart';
import 'package:carboneye/screens/annotation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:carboneye/models/watchlist_item.dart';
import 'package:carboneye/screens/all_alerts_screen.dart';
import 'package:carboneye/screens/settings_screen.dart';
import 'package:carboneye/widgets/dashboard_item.dart';
import 'package:carboneye/widgets/map_preview.dart';
import 'package:carboneye/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _detections = [];
  List<WatchlistItem> _watchlistItems = [];

  @override
  void initState() {
    super.initState();
    _initializeWatchlist();
  }

  /// Initializes the default list of watchlist items for the user.
  /// This now correctly uses the updated WatchlistItem model with a list of annotations.
  void _initializeWatchlist() {
    _watchlistItems = [
      WatchlistItem(
        name: 'Amazonas, Brazil',
        focusPoint: const LatLng(-3.4653, -62.2159),
        bbox: [-62.2159, -3.4653, -62.1159, -3.3653],
        annotations: [
          Annotation(id: '1', text: 'Initial monitoring area.', timestamp: DateTime.now())
        ],
      ),
      WatchlistItem(
        name: 'Sumatra, Indonesia',
        focusPoint: const LatLng(0.5897, 101.3431),
        bbox: [101.2431, 0.4897, 101.4431, 0.6897],
        annotations: [], // Starts with an empty list of annotations.
      ),
      WatchlistItem(
        name: 'Congo Basin, DRC',
        focusPoint: const LatLng(0.5598, 18.0416),
        bbox: [17.9416, 0.4598, 18.1416, 0.6598],
        // The annotations parameter is optional and defaults to an empty list.
      ),
    ];
  }

  /// Triggers an API call to analyze a region and updates the UI state.
  Future<void> _runAnalysis(List<double> bbox) async {
    setState(() {
      _isLoading = true;
      _detections = [];
    });

    try {
      final result = await _apiService.analyzeRegion(bbox);
      if (!mounted) return; // Safety check for async operations.

      setState(() {
        _detections = List<Map<String, dynamic>>.from(result['detections']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_detections.length} detections found.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeroSection(),
            const SizedBox(height: 24),
            _buildStatsSummary(),
            const SizedBox(height: 24),
            MapPreview(
              mapController: _mapController,
              detections: _detections,
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            _buildWatchlistSection(),
            const SizedBox(height: 24),
            _buildDashboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        image: const DecorationImage(
          image: AssetImage('assets/satellite-hero.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: const Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Real-time intelligence.\nZero trees lost.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatsSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Active Alerts', _detections.length.toString()),
        _buildStatItem('Regions', _watchlistItems.length.toString()),
        _buildStatItem('Area (ha)', '3.4M'), // Example static value
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  /// Builds the watchlist section with an icon to navigate to annotations.
  Widget _buildWatchlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Watchlist', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _watchlistItems.length,
          itemBuilder: (context, index) {
            final item = _watchlistItems[index];
            return Card(
              color: Colors.grey.shade800,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: IconButton(
                  icon: Icon(
                    item.annotations.isEmpty ? Icons.note_add_outlined : Icons.notes,
                    color: Colors.grey.shade400,
                  ),
                  tooltip: 'View Notes',
                  onPressed: () async {
                    // Navigate to the AnnotationScreen for the selected item.
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnnotationScreen(watchlistItem: item),
                      ),
                    );
                    // Refresh the UI to reflect any changes made to annotations
                    // (e.g., updating the icon if a note was added).
                    setState(() {});
                  },
                ),
                title: Text(item.name, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                onTap: () {
                  _mapController.move(item.focusPoint, 10.0);
                  _runAnalysis(item.bbox);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        DashboardItem(
          icon: Icons.travel_explore,
          label: 'Analyze New Region',
          onTap: () {
            // A real implementation would show a dialog to get user input for the bbox.
            final bbox = [-62.2159, -3.4653, -62.1159, -3.3653];
            _mapController.move(const LatLng(-3.4653, -62.2159), 10.0);
            _runAnalysis(bbox);
          },
        ),
        DashboardItem(
          icon: Icons.notifications_active,
          label: 'View All Alerts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AllAlertsScreen(detections: _detections),
              ),
            );
          },
        ),
        DashboardItem(
          icon: Icons.document_scanner,
          label: 'Generate Report',
          onTap: () { /* Placeholder for future functionality */ },
        ),
        DashboardItem(
          icon: Icons.settings,
          label: 'Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }
}
