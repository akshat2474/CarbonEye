import 'package:latlong2/latlong.dart';
import 'package:carboneye/models/annotation.dart';

class WatchlistItem {
  final String name;
  final LatLng coordinates;
  final List<double> bbox;  
  List<Annotation> annotations;

  WatchlistItem({
    required this.name,
    required this.coordinates,
    required this.bbox,
    List<Annotation>? annotations,
  }) : annotations = annotations ?? [];
}
