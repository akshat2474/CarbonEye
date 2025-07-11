import 'package:latlong2/latlong.dart';
import 'package:carboneye/models/annotation.dart';

class WatchlistItem {
  final String name;
  final LatLng coordinates; // For map centering and pins
  final List<double> bbox;  // For the API analysis call
  List<Annotation> annotations;

  WatchlistItem({
    required this.name,
    required this.coordinates,
    required this.bbox,
    List<Annotation>? annotations,
  }) : annotations = annotations ?? [];
}
