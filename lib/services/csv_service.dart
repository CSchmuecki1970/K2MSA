import '../models/coordinate_point.dart';
import '../models/analysis_mode.dart';

/// Exception für CSV-bezogene Fehler
class CsvException implements Exception {
  final String message;
  final int? lineNumber;

  CsvException(this.message, {this.lineNumber});

  @override
  String toString() => lineNumber != null
      ? 'CsvException (Zeile $lineNumber): $message'
      : 'CsvException: $message';
}

/// Ergebnis des CSV-Parsing
class CsvParseResult {
  final AnalysisMode mode;
  final List<Map<String, double>> data;
  final List<double> values_1d; // Für 1D-Modus
  final List<CoordinatePoint> points_2d_direct; // Für 2D direkt
  final List<CoordinatePoint> points_2d_distances; // Für 2D Distanzen

  CsvParseResult({
    required this.mode,
    required this.data,
    this.values_1d = const [],
    this.points_2d_direct = const [],
    this.points_2d_distances = const [],
  });
}

/// Service zum Einlesen und Validieren von CSV-Daten
/// Unterstützt 3 Modi: 1D (x), 2D direkt (x,y), 2D Distanzen (x1,y1,x2,y2)
class CsvService {
  /// Parst CSV-String und erkennt automatisch den Typ
  ///
  /// Unterstützt:
  /// - 1 Spalte: x
  /// - 2 Spalten: x,y
  /// - 4 Spalten: x1,y1,x2,y2
  ///
  /// Wirft [CsvException] bei Validierungsfehlern
  static CsvParseResult parseCoordinates(String csvContent) {
    if (csvContent.trim().isEmpty) {
      throw CsvException('CSV-Datei ist leer');
    }

    final lines = csvContent.trim().split('\n');
    if (lines.isEmpty) {
      throw CsvException('Keine Zeilen in der CSV-Datei');
    }

    // Header validieren und Spaltenanzahl bestimmen
    final header = lines[0].trim();
    final headerFields = header.split(',').map((h) => h.trim()).toList();

    AnalysisMode mode;
    switch (headerFields.length) {
      case 1:
        if (headerFields[0] != 'x') {
          throw CsvException(
            'Ungültiger Header für 1D. Erwartet: "x", erhalten: "$header"',
          );
        }
        mode = AnalysisMode.oneD;
        break;
      case 2:
        if (headerFields[0] != 'x' || headerFields[1] != 'y') {
          throw CsvException(
            'Ungültiger Header für 2D. Erwartet: "x,y", erhalten: "$header"',
          );
        }
        mode = AnalysisMode.twoD_direct;
        break;
      case 4:
        if (headerFields[0] != 'x1' ||
            headerFields[1] != 'y1' ||
            headerFields[2] != 'x2' ||
            headerFields[3] != 'y2') {
          throw CsvException(
            'Ungültiger Header für 2D Distanzen. '
            'Erwartet: "x1,y1,x2,y2", erhalten: "$header"',
          );
        }
        mode = AnalysisMode.twoD_distances;
        break;
      default:
        throw CsvException(
          'Ungültige Spaltenanzahl: ${headerFields.length}. '
          'Erwartet: 1, 2 oder 4 Spalten',
        );
    }

    final results = <Map<String, double>>[];
    final values_1d = <double>[];
    final points_2d_direct = <CoordinatePoint>[];
    final points_2d_distances = <CoordinatePoint>[];

    // Datenzeilen parsen
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final values = line.split(',').map((v) => v.trim()).toList();

        if (values.length != headerFields.length) {
          throw CsvException(
            'Ungültige Feldanzahl. Erwartet: ${headerFields.length}, '
            'erhalten: ${values.length}',
            lineNumber: i + 1,
          );
        }

        // Numerische Werte parsen
        final doubles = <double>[];
        try {
          for (final val in values) {
            doubles.add(double.parse(val));
          }
        } catch (e) {
          throw CsvException(
            'Nicht-numerischer Wert gefunden: ${values.map((v) => '"$v"').join(', ')}',
            lineNumber: i + 1,
          );
        }

        // Werte auf Gültigkeit prüfen
        for (int j = 0; j < doubles.length; j++) {
          if (doubles[j].isNaN || doubles[j].isInfinite) {
            throw CsvException(
              'Ungültiger numerischer Wert (NaN/Infinity): ${values[j]}',
              lineNumber: i + 1,
            );
          }
        }

        // Daten entsprechend dem Modus speichern
        final record = <String, double>{};
        switch (mode) {
          case AnalysisMode.oneD:
            record['x'] = doubles[0];
            values_1d.add(doubles[0]);
            break;
          case AnalysisMode.twoD_direct:
            record['x'] = doubles[0];
            record['y'] = doubles[1];
            points_2d_direct.add(CoordinatePoint(x: doubles[0], y: doubles[1]));
            break;
          case AnalysisMode.twoD_distances:
            record['x1'] = doubles[0];
            record['y1'] = doubles[1];
            record['x2'] = doubles[2];
            record['y2'] = doubles[3];
            points_2d_distances
                .add(CoordinatePoint(x: doubles[0], y: doubles[1]));
            points_2d_distances
                .add(CoordinatePoint(x: doubles[2], y: doubles[3]));
            break;
        }

        results.add(record);
      } catch (e) {
        if (e is CsvException) rethrow;
        throw CsvException(
          'Fehler beim Parsen der Zeile: $e',
          lineNumber: i + 1,
        );
      }
    }

    if (results.isEmpty) {
      throw CsvException('Keine gültigen Datenzeilen gefunden');
    }

    return CsvParseResult(
      mode: mode,
      data: results,
      values_1d: values_1d,
      points_2d_direct: points_2d_direct,
      points_2d_distances: points_2d_distances,
    );
  }
}
