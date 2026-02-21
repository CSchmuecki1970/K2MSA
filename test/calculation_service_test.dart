import 'package:test/test.dart';
import 'package:msa_analysis/models/coordinate_point.dart';
import 'package:msa_analysis/services/calculation_service.dart';
import 'package:msa_analysis/services/csv_service.dart';
import 'package:msa_analysis/services/msa_type1_service.dart';

void main() {
  group('CalculationService Tests', () {
    test('Berechne Euklidischen Abstand korrekt', () {
      final p1 = CoordinatePoint(x: 0, y: 0);
      final p2 = CoordinatePoint(x: 3, y: 4);

      // Pythagoras: 3² + 4² = 25, √25 = 5
      final distance = CalculationService.calculateEuclideanDistance(p1, p2);
      expect(distance, closeTo(5.0, 0.0001));
    });

    test('Berechne Euklidischen Abstand für identische Punkte', () {
      final p1 = CoordinatePoint(x: 2, y: 3);
      final p2 = CoordinatePoint(x: 2, y: 3);

      final distance = CalculationService.calculateEuclideanDistance(p1, p2);
      expect(distance, closeTo(0.0, 0.0001));
    });

    test('Berechne Mittelwert korrekt', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0];
      final mean = CalculationService.calculateMean(values);
      expect(mean, closeTo(3.0, 0.0001));
    });

    test('Berechne Standardabweichung korrekt', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0];
      // Stichproben-StdDev: σ = √(10/4) ≈ 1.581
      final stdDev = CalculationService.calculateStandardDeviation(values);
      expect(stdDev, closeTo(1.5811, 0.001));
    });

    test('Berechne Min korrekt', () {
      final values = [3.0, 1.0, 4.0, 1.0, 5.0];
      final min = CalculationService.calculateMin(values);
      expect(min, 1.0);
    });

    test('Berechne Max korrekt', () {
      final values = [3.0, 1.0, 4.0, 1.0, 5.0];
      final max = CalculationService.calculateMax(values);
      expect(max, 5.0);
    });

    test('Berechne Bias korrekt', () {
      final values = [4.0, 5.0, 6.0];
      final bias = CalculationService.calculateBias(values, 5.0);
      expect(bias, closeTo(0.0, 0.0001));
    });

    test('Berechne Bias mit Referenzwert', () {
      final values = [5.0, 5.0, 5.0];
      final bias = CalculationService.calculateBias(values, 6.0);
      expect(bias, closeTo(-1.0, 0.0001));
    });

    test('Standardabweichung ist 0 für identische Werte', () {
      final values = [5.0, 5.0, 5.0, 5.0];
      final stdDev = CalculationService.calculateStandardDeviation(values);
      expect(stdDev, closeTo(0.0, 0.0001));
    });
  });

  group('CsvService Tests', () {
    test('Parse gültige CSV korrekt', () {
      const csvContent = '''x1,y1,x2,y2
1.0,2.0,3.0,4.0
5.0,6.0,7.0,8.0''';

      final service = CsvService();
      final result = service.parseCoordinates(csvContent);

      expect(result, hasLength(2));
      expect(result[0]['x1'], 1.0);
      expect(result[0]['y1'], 2.0);
      expect(result[1]['x2'], 7.0);
    });

    test('Leere Zeilen ignorieren', () {
      const csvContent = '''x1,y1,x2,y2
1.0,2.0,3.0,4.0

5.0,6.0,7.0,8.0''';

      final service = CsvService();
      final result = service.parseCoordinates(csvContent);

      expect(result, hasLength(2));
    });

    test('Ungültiger Header wirft Exception', () {
      const csvContent = '''x1,y1,x2
1.0,2.0,3.0''';

      final service = CsvService();
      expect(
        () => service.parseCoordinates(csvContent),
        throwsA(isA<CsvException>()),
      );
    });

    test('Nicht-numerische Werte werfen Exception', () {
      const csvContent = '''x1,y1,x2,y2
1.0,abc,3.0,4.0''';

      final service = CsvService();
      expect(
        () => service.parseCoordinates(csvContent),
        throwsA(isA<CsvException>()),
      );
    });

    test('Zu wenige Felder werfen Exception', () {
      const csvContent = '''x1,y1,x2,y2
1.0,2.0,3.0''';

      final service = CsvService();
      expect(
        () => service.parseCoordinates(csvContent),
        throwsA(isA<CsvException>()),
      );
    });

    test('Leere CSV wirft Exception', () {
      const csvContent = '';

      final service = CsvService();
      expect(
        () => service.parseCoordinates(csvContent),
        throwsA(isA<CsvException>()),
      );
    });
  });

  group('MSA Type 1 Analysis Tests', () {
    test('MSA Analyse mit geeignetem Messsystem (<10%)', () {
      // Generiere Messdaten mit kleiner Varianz (geringe Messunsicherheit)
      final measurements = <MeasurementData>[];
      for (int i = 0; i < 30; i++) {
        final m = CalculationService.createMeasurement(
          id: i + 1,
          point1: CoordinatePoint(x: 0, y: 0),
          point2:
              CoordinatePoint(x: 5.0 + (i % 2) * 0.01, y: 3.0 + (i % 2) * 0.01),
        );
        measurements.add(m);
      }

      final result = MsaType1Service.analyze(
        measurements: measurements,
        toleranceRange: 100.0,
      );

      // %TV sollte < 10% sein für so kleine Varianz
      expect(result.percentStudyVariation, lessThan(0.10));
      expect(result.suitability.toString(), contains('suitable'));
    });

    test('MSA Analyse mit Bias-Berechnung', () {
      final measurements = <MeasurementData>[];
      for (int i = 0; i < 20; i++) {
        final m = CalculationService.createMeasurement(
          id: i + 1,
          point1: CoordinatePoint(x: 0, y: 0),
          point2: CoordinatePoint(x: 5.0, y: 3.0),
        );
        measurements.add(m);
      }

      final result = MsaType1Service.analyze(
        measurements: measurements,
        toleranceRange: 100.0,
        referenceValue: 5.831, // Erwarteter Wert für 5,3,4
      );

      expect(result.bias, isNotNull);
    });

    test('MSA Analyse mit Stabilitätsprüfung', () {
      final measurements = <MeasurementData>[];
      for (int i = 0; i < 20; i++) {
        final m = CalculationService.createMeasurement(
          id: i + 1,
          point1: CoordinatePoint(x: 0, y: 0),
          point2: CoordinatePoint(x: 5.0 + i * 0.01, y: 3.0),
        );
        measurements.add(m);
      }

      final result = MsaType1Service.analyze(
        measurements: measurements,
        toleranceRange: 100.0,
        analyzeStability: true,
      );

      expect(result.stabilityCheck, isNotNull);
    });

    test('MSA wirft Exception bei leinen Messungen', () {
      expect(
        () => MsaType1Service.analyze(measurements: []),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
