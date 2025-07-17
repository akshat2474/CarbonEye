import 'package:carboneye/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPreview extends StatelessWidget {
  final MapController mapController;
  final String selectedLayer;
  final List<Marker> watchlistMarkers;
  final List<Marker> detectionMarkers;
  final List<Polygon> detectionPolygons;
  final bool isSelectionMode;
  final List<LatLng> selectionPoints;
  final void Function(LatLng) onMapTap;

  const MapPreview({
    super.key,
    required this.mapController,
    required this.selectedLayer,
    this.watchlistMarkers = const [],
    this.detectionMarkers = const [],
    this.detectionPolygons = const [],
    this.isSelectionMode = false,
    this.selectionPoints = const [],
    required this.onMapTap,
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

  List<Polygon> _buildSelectionPolygon() {
    if (selectionPoints.length < 2) return [];
    final point1 = selectionPoints[0];
    final point2 = selectionPoints[1];
    final List<LatLng> polygonPoints = [
      point1,
      LatLng(point1.latitude, point2.longitude),
      point2,
      LatLng(point2.latitude, point1.longitude),
    ];
    return [
      Polygon(
        points: polygonPoints,
        color: kAccentColor.withOpacity(0.2),
        borderColor: kAccentColor,
        borderStrokeWidth: 2.0,
        isFilled: true,
      ),
    ];
  }

  List<Marker> _buildSelectionMarkers() {
    return selectionPoints.map((point) {
      return Marker(
        width: 15.0,
        height: 15.0,
        point: point,
        child: Container(
          decoration: BoxDecoration(
            color: kAccentColor,
            shape: BoxShape.circle,
            border: Border.all(color: kWhiteColor, width: 2),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.0),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(-3.4653, -62.2159),
            initialZoom: 4.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              if (isSelectionMode) {
                onMapTap(point);
              }
            },
          ),
          children: [
            TileLayer(
              key: ValueKey<String>(selectedLayer),
              urlTemplate: _getTileUrl(),
              userAgentPackageName: 'com.example.carboneye',
            ),
            PolygonLayer(polygons: [
              ...detectionPolygons,
              ..._buildSelectionPolygon(),
            ]),
            MarkerLayer(markers: [
              ...watchlistMarkers,
              ...detectionMarkers,
              ..._buildSelectionMarkers(),
            ]),
          ],
        ),
      ),
    );
  }
}
