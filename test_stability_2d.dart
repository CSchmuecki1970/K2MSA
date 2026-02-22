import 'dart:io';
import 'dart:math' as math;
import 'lib/services/csv_service.dart';
import 'lib/services/msa_type1_service.dart';
import 'lib/services/calculation_service.dart';
import 'lib/models/analysis_mode.dart';
import 'lib/models/coordinate_point.dart';
import 'lib/models/measurement_data.dart';

/// Helper function to create measurements from coordinate pairs
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

/// Demonstration: Stabilitätsanalyse für 2D (x,y) Daten
void main() async {
  print('═══════════════════════════════════════════════');
  print('  MSA STABILITÄTSANALYSE - 2D (X,Y) Daten');
  print('═══════════════════════════════════════════════\n');

  try {
    // Teste mit xy_coordinate_copy_clean_small.csv
    print('📂 Lade CSV-Datei: xy_coordinate_copy_clean_small.csv');
    final file = File('xy_coordinate_copy_clean_small.csv');

    if (!await file.exists()) {
      print('❌ Fehler: Datei nicht gefunden!');
      print('   Verfügbare Alternativen:');
      print('   - xy_coordinate_copy_clean.csv');
      print('   - xy_coordinate_copy.csv');
      return;
    }

    final csvContent = await file.readAsString();
    print('✓ Datei geladen\n');

    // CSV parsen
    print('🔍 Parse CSV-Daten...');
    final parseResult = CsvService.parseCoordinates(csvContent);

    final pointCount = parseResult.mode == AnalysisMode.twoD_direct
        ? parseResult.points_2d_direct.length
        : parseResult.points_2d_distances.length ~/ 2;

    print('✓ $pointCount Punkte erkannt');
    print('   Modus: ${parseResult.mode.description}\n');

    // Zeige wie Stabilität für 2D funktioniert
    if (parseResult.mode == AnalysisMode.twoD_direct) {
      print('ℹ️  Wie Stabilitätsprüfung für X,Y-Daten funktioniert:');
      print('   1. X- und Y-Werte werden zu einer Sequenz kombiniert:');
      print('      [x₁, y₁, x₂, y₂, x₃, y₃, ...]');
      print('   2. Trendanalyse auf der gesamten Sequenz');
      print('   3. Erkennt Drift in beiden Dimensionen\n');
    } else {
      print('ℹ️  Wie Stabilitätsprüfung für Distanz-Daten funktioniert:');
      print('   1. Distanzen zwischen Punktpaaren werden berechnet');
      print('   2. Trendanalyse auf den Distanzwerten über Zeit');
      print('   3. Erkennt systematische Änderungen der Abstände\n');
    }

    // MSA Typ 1 mit Stabilitätsprüfung
    print('⚙️  Führe MSA Typ 1 Analyse mit Stabilitätsprüfung durch...');

    // Helper für Distance-Modus
    List<dynamic>? measurements;
    if (parseResult.mode == AnalysisMode.twoD_distances) {
      measurements = [];
      for (int i = 0; i < parseResult.points_2d_distances.length; i += 2) {
        final p1 = parseResult.points_2d_distances[i];
        final p2 = parseResult.points_2d_distances[i + 1];
        final distance =
            ((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y))
                .toDouble();
        measurements.add({
          'point1': p1,
          'point2': p2,
          'distance': distance,
        });
      }
    }

    final result = MsaType1Service.analyzeWithMode(
      mode: parseResult.mode,
      values_1d: parseResult.values_1d,
      points_2d_direct: parseResult.points_2d_direct,
      points_2d_distances: parseResult.points_2d_distances,
      measurements_distances: parseResult.mode == AnalysisMode.twoD_distances
          ? _createMeasurements(parseResult.points_2d_distances)
          : null,
      toleranceRange: 10.0,
      analyzeStability: true, // <<< Stabilitätsprüfung aktiviert
    );
    print('✓ Analyse abgeschlossen\n');

    // Ergebnisse
    print(result.toFormattedString());

    // Stabilitäts-Zusammenfassung
    if (result.stabilityCheck != null) {
      final stability = result.stabilityCheck!;
      print('\n╔════════════════════════════════════════════════╗');
      print('║    STABILITÄTS-ZUSAMMENFASSUNG (2D-Daten)     ║');
      print('╚════════════════════════════════════════════════╝\n');

      final hasTrend = stability['hasTrend'] as bool;
      final slope = stability['trendSlope'] as double;
      final rSquared = stability['r_squared'] as double;
      final sampleCount = stability['sampleCount'] as int;

      print('Status: ${hasTrend ? "⚠️  INSTABIL" : "✓ STABIL"}');
      print('');
      print('Details:');
      print(
          '  • $sampleCount Werte analysiert (${sampleCount ~/ 2} Punkte × 2 Koordinaten)');
      print('  • R² = ${rSquared.toStringAsFixed(4)} (Schwellenwert: 0.3)');
      print('  • Trendsteigung = ${slope.toStringAsFixed(8)} pro Wert');
      print('');

      if (hasTrend) {
        print('⚠️  WARNUNG: Systematischer Trend in den Koordinaten erkannt!');
        print('');
        print('Bei 2D-Daten kann ein Trend bedeuten:');
        print('  • Systematische Verschiebung in X- oder Y-Richtung');
        print('  • Rotationsdrift des Messsystems');
        print('  • Temperatur-bedingte Ausdehnung/Schrumpfung');
        print('  • Mechanische Dejustierung über Zeit');
      } else {
        print('✓ Koordinaten zeigen keine signifikante Drift.');
        print('  Beide Dimensionen (X und Y) sind zeitlich stabil.');
      }
      print('');
      print('═══════════════════════════════════════════════');
    }
  } catch (e) {
    print('\n❌ Fehler bei der Analyse:');
    print('   $e');
  }
}
