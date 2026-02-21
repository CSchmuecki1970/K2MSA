/// Standalone Dart CLI für MSA-Analyse (ohne Flutter)
///
/// Verwendung:
/// dart bin/msa_cli.dart <csv-datei> [--tolerance=10.0] [--reference=5.831]
///
/// Beispiel:
/// dart bin/msa_cli.dart data/measurements.csv --tolerance=10.0 --reference=5.831

import 'dart:io';
import 'dart:convert';
import 'package:msa_analysis/models/measurement_data.dart';
import 'package:msa_analysis/services/csv_service.dart';
import 'package:msa_analysis/services/calculation_service.dart';
import 'package:msa_analysis/services/msa_type1_service.dart';

void main(List<String> args) async {
  try {
    // CLI-Argument-Parsing
    if (args.isEmpty) {
      _printUsage();
      exit(1);
    }

    // Parse command-line arguments
    final csvPath = args[0];
    double? tolerance;
    double? reference;

    for (final arg in args.skip(1)) {
      if (arg.startsWith('--tolerance=')) {
        tolerance = double.tryParse(arg.split('=')[1]);
      } else if (arg.startsWith('--reference=')) {
        reference = double.tryParse(arg.split('=')[1]);
      }
    }

    // Datei einlesen
    print('📂 Lese CSV-Datei: $csvPath');
    final file = File(csvPath);
    if (!file.existsSync()) {
      print('❌ Fehler: Datei nicht gefunden: $csvPath');
      exit(1);
    }

    final csvContent = await file.readAsString();

    // CSV-Daten verarbeiten
    print('📖 Parse CSV-Daten...');
    final csvService = CsvService();
    final parsedData = csvService.parseCoordinates(csvContent);
    final coordinatePairs = csvService.toCoordinatePoints(parsedData);

    print('✓ ${coordinatePairs.length} Datensätze erfolgreich gelesen\n');

    // MeasurementData erstellen
    print('📐 Berechne Abstände...');
    final measurements = <MeasurementData>[];
    for (int i = 0; i < coordinatePairs.length; i++) {
      final pair = coordinatePairs[i];
      final measurement = CalculationService.createMeasurement(
        id: i + 1,
        point1: pair.p1,
        point2: pair.p2,
        timestamp: DateTime.now().subtract(
          Duration(minutes: coordinatePairs.length - i),
        ),
      );
      measurements.add(measurement);
    }

    print('✓ ${measurements.length} Abstände berechnet\n');

    // MSA Analyse durchführen
    print('⚙️  Führe MSA Typ 1 Analyse durch...\n');
    final result = MsaType1Service.analyze(
      measurements: measurements,
      toleranceRange: tolerance,
      referenceValue: reference,
      analyzeStability: measurements.length > 10,
    );

    // Ausgabe
    print(result.toFormattedString());

    // Zusätzliche Debug-Informationen
    print('\n📋 JSON-Daten für weiterere Verarbeitung:\n');
    final jsonData = result.toJson();
    print(jsonEncode(jsonData));

    // Optional: Speichere Ergebnisse in Datei
    await _saveResults(csvPath, result);
  } catch (e) {
    print('❌ Fehler: $e');
    exit(1);
  }
}

void _printUsage() {
  print('''
MSA Type 1 Messsystemanalyse - Standalone Dart CLI

Verwendung:
  dart bin/msa_cli.dart <csv-file> [OPTIONS]

Positional Arguments:
  <csv-file>              Pfad zur CSV-Datei (x1,y1,x2,y2)

Options:
  --tolerance=<value>     Toleranzbereich (default: Spannweite)
  --reference=<value>     Referenz-/Sollwert (optional)
  --help                  Hilfe anzeigen

Beispiele:
  dart bin/msa_cli.dart data/measurements.csv
  dart bin/msa_cli.dart data/measurements.csv --tolerance=10.0
  dart bin/msa_cli.dart data/measurements.csv --tolerance=10.0 --reference=5.831

CSV-Format:
  x1,y1,x2,y2
  10.05,20.01,15.05,23.02
  10.12,20.08,15.13,23.09
  ...

AIAG-Bewertung:
  %TV < 10%   : ✓ Messsystem ist GEEIGNET
  10% ≤ %TV ≤ 30%  : ⚠ BEDINGT GEEIGNET (Mit Vorsicht)
  %TV > 30%   : ✗ NICHT GEEIGNET (Reparatur/Kalibrierung)
  ''');
}

Future<void> _saveResults(String csvPath, dynamic result) async {
  try {
    final directory = Directory(csvPath).parent;
    final filename =
        '${csvPath.split('/').last.replaceAll('.csv', '')}_msa_results.json';
    final outputPath = '${directory.path}/$filename';

    final file = File(outputPath);
    await file.writeAsString(jsonEncode(result.toJson()), flush: true);

    print('💾 Ergebnisse gespeichert: $outputPath');
  } catch (e) {
    print('⚠️  Konnte Ergebnisse nicht speichern: $e');
  }
}
