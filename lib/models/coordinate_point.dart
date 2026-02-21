/// Repräsentiert einen Messpunkt mit x und y Koordinate
class CoordinatePoint {
  final double x;
  final double y;

  CoordinatePoint({
    required this.x,
    required this.y,
  });

  @override
  String toString() => 'CoordinatePoint(x: $x, y: $y)';
}
