import 'package:carboneye/models/annotation.dart'; 
import 'package:latlong2/latlong.dart';
class WatchlistItem {
  final String name;
  final LatLng focusPoint;
  final List<double> bbox;
  List<Annotation> annotations;

  WatchlistItem({
    required this.name,
    required this.focusPoint,
    required this.bbox,
    // The list can be initialized optionally. It defaults to an empty list.
    List<Annotation>? annotations,
  }) : annotations = annotations ?? [];
}
