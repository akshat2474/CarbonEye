import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPreview extends StatelessWidget {
  final MapController mapController;
  final String selectedLayer;
  final List<Marker> watchlistMarkers;
  final List<Marker> detectionMarkers;

  const MapPreview({
    super.key,
    required this.mapController,
    required this.selectedLayer,
    this.watchlistMarkers = const [],
    this.detectionMarkers = const [],
  });

  String _getTileUrl() {
    switch (selectedLayer) {
      case 'Satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'Political':
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'Heatmap':
      default:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(-3.4653, -62.2159), // Amazon Rainforest
            initialZoom: 4.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              // FIXED: Adding a unique key forces the widget to rebuild when the layer changes.
              key: ValueKey<String>(selectedLayer),
              urlTemplate: _getTileUrl(),
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.carboneye', // Recommended by flutter_map
            ),
            MarkerLayer(markers: [...watchlistMarkers, ...detectionMarkers]),
          ],
        ),
      ),
    );
  }
}
