import 'coordinate_point.dart';

/// Repräsentiert einen Messdatensatz: zwei Punkte und berechnete Kenngrößen
class MeasurementData {
  final int id;
  final CoordinatePoint point1;
  final CoordinatePoint point2;
  final double distance; // Euklidischer Abstand
  final double deltaX; // x2 - x1
  final double deltaY; // y2 - y1
  final DateTime? timestamp; // Optional für Stabilitätsprüfung

  MeasurementData({
    required this.id,
    required this.point1,
    required this.point2,
    required this.distance,
    required this.deltaX,
    required this.deltaY,
    this.timestamp,
  });

  @override
  String toString() =>
      'MeasurementData(id: $id, distance: ${distance.toStringAsFixed(6)}, '
      'deltaX: ${deltaX.toStringAsFixed(6)}, deltaY: ${deltaY.toStringAsFixed(6)})';
}
