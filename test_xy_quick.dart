import 'dart:io';
import 'lib/services/csv_service.dart';
import 'lib/services/msa_type1_service.dart';

void main() async {
  final csv = await File('demo_xy_direct.csv').readAsString();
  final parsed = CsvService.parseCoordinates(csv);
  final result = MsaType1Service.analyzeWithMode(
    mode: parsed.mode,
    values_1d: parsed.values_1d,
    points_2d_direct: parsed.points_2d_direct,
    points_2d_distances: parsed.points_2d_distances,
    analyzeStability: true,
  );
  print('Mode: ');
  print('Points: ');
  if (result.stabilityCheck != null) {
    print('Stability: ');
    print('R²: ');
  }
}
