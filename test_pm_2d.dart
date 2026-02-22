import 'dart:io';
import 'lib/services/csv_service.dart';
import 'lib/services/process_monitoring_service.dart';
import 'lib/services/calculation_service.dart';
import 'lib/models/analysis_mode.dart';
import 'lib/models/measurement_data.dart';
import 'lib/models/coordinate_point.dart';
import 'lib/models/process_monitoring_result.dart';

/// Test Process Monitoring with 2D coordinate data
void main() async {
  print('═══════════════════════════════════════════════════════════════════');
  print('  PROZESSÜBERWACHUNG - 2D Koordinaten Test');
  print(
      '═══════════════════════════════════════════════════════════════════\n');

  try {
    // Load the xy_coordinate_copy_clean_small.csv file
    print('📂 Lade CSV-Datei: xy_coordinate_copy_clean_small.csv');
    final file = File('xy_coordinate_copy_clean_small.csv');

    if (!await file.exists()) {
      print('❌ Datei nicht gefunden!');
      print('   Versuche: xy_coordinate_copy_clean.csv');
      return;
    }

    final csvContent = await file.readAsString();
    print('✓ Datei geladen\n');

    // Parse CSV
    print('🔍 Parse CSV-Daten...');
    final parseResult = CsvService.parseCoordinates(csvContent);

    print('✓ Daten erkannt:');
    if (parseResult.values_1d.isNotEmpty) {
      print(
        '   ${parseResult.values_1d.length} 1D-Werte - Modus: ${parseResult.mode.description}',
      );
    } else if (parseResult.points_2d_direct.isNotEmpty) {
      print(
        '   ${parseResult.points_2d_direct.length} 2D-Punkte (Direct) - Modus: ${parseResult.mode.description}',
      );
    } else if (parseResult.points_2d_distances.isNotEmpty) {
      print(
        '   ${parseResult.points_2d_distances.length} 2D-Punkte (Distances) - Modus: ${parseResult.mode.description}',
      );
    }
    print('');

    // Run Process Monitoring on appropriate data
    print('⚙️  Führe Prozessüberwachungs-Analyse durch...');
    ProcessMonitoringResult result;

    if (parseResult.values_1d.isNotEmpty) {
      result = ProcessMonitoringService.analyze1D(
        values: parseResult.values_1d,
      );
    } else if (parseResult.points_2d_direct.isNotEmpty) {
      result = ProcessMonitoringService.analyze2DDirect(
        points: parseResult.points_2d_direct,
      );
    } else if (parseResult.points_2d_distances.isNotEmpty) {
      result = ProcessMonitoringService.analyze2DDistances(
        measurements: _createMeasurements(parseResult.points_2d_distances),
      );
    } else {
      throw Exception('Keine Daten zum Analysieren gefunden');
    }

    print('✓ Analyse abgeschlossen\n');

    // Display results
    print(result.toFormattedString());
  } catch (e) {
    print('\n❌ Fehler:');
    print('   $e');
  }
}

List<MeasurementData> _createMeasurements(List<CoordinatePoint> points) {
  final measurements = <MeasurementData>[];
  for (int i = 0; i < points.length; i += 2) {
    if (i + 1 < points.length) {
      measurements.add(CalculationService.createMeasurement(
        id: i ~/ 2 + 1,
        point1: points[i],
        point2: points[i + 1],
      ));
    }
  }
  return measurements;
}
