import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';
import 'package:carboneye/utils/constants.dart';

class MapPreview extends StatelessWidget {
  final String selectedLayer;
  final MapController mapController;
  final List<Marker> watchlistMarkers;

  MapPreview({
    super.key,
    required this.selectedLayer,
    required this.mapController,
    required this.watchlistMarkers,
  });

  final List<Marker> criticalAlertMarkers = [
    _buildCriticalMarker(const LatLng(-3.4653, -62.2159)),
    _buildCriticalMarker(const LatLng(1.0, 114.0)),
  ];

  final List<WeightedLatLng> heatmapData = [
    WeightedLatLng(const LatLng(-3.4653, -62.2159), 1.0),
    WeightedLatLng(const LatLng(-4.0, -63.0), 1.0),
    WeightedLatLng(const LatLng(1.0, 114.0), 1.0),
    WeightedLatLng(const LatLng(0.5, 113.5), 1.0),
    WeightedLatLng(const LatLng(0.5, 23.5), 1.0),
    WeightedLatLng(const LatLng(0.2, 23.8), 1.0),
  ];

  TileLayer _buildMapLayer(BuildContext context) {
    switch (selectedLayer) {
      case 'Satellite':
        return TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          retinaMode: RetinaMode.isHighDensity(context),
        );
      case 'Political':
        return TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          retinaMode: RetinaMode.isHighDensity(context),
        );
      default:
        return TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: SizedBox(
        height: 250,
        child: FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(0, 0),
            initialZoom: 2.0,
            maxZoom: 18.0,
          ),
          children: [
            _buildMapLayer(context),
            if (selectedLayer == 'Heatmap')
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(data: heatmapData),
                heatMapOptions: HeatMapOptions(
                  gradient: {
                    0.25: Colors.lightGreen,
                    0.55: Colors.yellow,
                    0.85: Colors.orange,
                    1.0: Colors.red,
                  },
                  minOpacity: 0.1,
                  radius: 30,
                ),
              ),
            MarkerLayer(
              markers: [...criticalAlertMarkers, ...watchlistMarkers],
            ),
          ],
        ),
      ),
    );
  }

  static Marker _buildCriticalMarker(LatLng point) {
    return Marker(
      width: 24.0,
      height: 24.0,
      point: point,
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(102, 244, 67, 54),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.shade300, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.warning_amber_rounded, color: kWhiteColor, size: 14),
        ),
      ),
    );
  }
}
