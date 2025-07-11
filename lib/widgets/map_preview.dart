import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
class MapPreview extends StatefulWidget {
  final MapController mapController;
  final List<Map<String, dynamic>> detections;

  const MapPreview({
    super.key,
    required this.mapController,
    this.detections = const [],
  });

  @override
  MapPreviewState createState() => MapPreviewState();
}

class MapPreviewState extends State<MapPreview> {
  String _selectedLayer = 'Heatmap';

  String _getTileUrl() {
    switch (_selectedLayer) {
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
    return Column(
      children: [
        _buildLayerSelector(),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: FlutterMap(
              mapController: widget.mapController,
              options: const MapOptions(
                initialCenter: LatLng(-3.4653, -62.2159),
                initialZoom: 7.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: _getTileUrl(),
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _buildDetectionMarkers(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildDetectionMarkers() {
    return widget.detections.map((detection) {
      final center = detection['center_coordinates'];
      final severity = detection['severity']?.toString().toLowerCase() ?? 'medium';
      Color markerColor;

      switch (severity) {
        case 'critical':
          markerColor = Colors.red.withAlpha((255 * 0.8).round());
          break;
        case 'high':
          markerColor = Colors.orange.withAlpha((255 * 0.8).round());
          break;
        default:
          markerColor = Colors.yellow.withAlpha((255 * 0.8).round());
      }

      return Marker(
        width: 24.0,
        height: 24.0,
        point: LatLng(center['latitude'], center['longitude']),
        child: Tooltip(
          message: 'Severity: $severity\nArea: ${detection['area_ha']} ha',
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLayerSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['Heatmap', 'Satellite', 'Political'].map((layer) {
        final isSelected = _selectedLayer == layer;
        return GestureDetector(
          onTap: () => setState(() => _selectedLayer = layer),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade700 : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              layer,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade300,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
