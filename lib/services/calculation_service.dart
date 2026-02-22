import 'dart:math' as math;
import '../models/coordinate_point.dart';
import '../models/measurement_data.dart';

/// Service für mathematische Berechnungen der Messdaten
class CalculationService {
  /// Berechnet den euklidischen Abstand zwischen zwei Punkten
  ///
  /// Formel: d = √((x₂-x₁)² + (y₂-y₁)²)
  ///
  /// Parameter:
  /// - [p1]: Erster Punkt
  /// - [p2]: Zweiter Punkt
  ///
  /// Rückgabe: Euklidischer Abstand (immer ≥ 0)
  static double calculateEuclideanDistance(
    CoordinatePoint p1,
    CoordinatePoint p2,
  ) {
    final deltaX = p2.x - p1.x;
    final deltaY = p2.y - p1.y;
    return math.sqrt((deltaX * deltaX) + (deltaY * deltaY));
  }

  /// Erstellt MeasurementData aus Koordinatenpunkten
  ///
  /// Kombiniert:
  /// - Eingabedaten (zwei Punkte)
  /// - Berechnete Werte (Abstand, Δx, Δy)
  /// - Optionale Metadaten (Timestamp)
  static MeasurementData createMeasurement({
    required int id,
    required CoordinatePoint point1,
    required CoordinatePoint point2,
    DateTime? timestamp,
  }) {
    final distance = calculateEuclideanDistance(point1, point2);
    final deltaX = point2.x - point1.x;
    final deltaY = point2.y - point1.y;

    return MeasurementData(
      id: id,
      point1: point1,
      point2: point2,
      distance: distance,
      deltaX: deltaX,
      deltaY: deltaY,
      timestamp: timestamp,
    );
  }

  /// Berechnet Mittelwert einer Liste von Werten
  ///
  /// Formel: μ = (Σx) / n
  static double calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Berechnet Standardabweichung (Stichprobe)
  ///
  /// Formel: σ = √(Σ(x-μ)² / (n-1))
  ///
  /// Verwendet (n-1) Freiheitsgrade für unverzerrte Schätzung
  static double calculateStandardDeviation(List<double> values) {
    if (values.length < 2) return 0.0;

    final mean = calculateMean(values);
    final sumSquaredDiff = values.fold<double>(
      0.0,
      (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
    );

    return math.sqrt(sumSquaredDiff / (values.length - 1));
  }

  /// Berechnet Minimum einer Liste
  static double calculateMin(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a < b ? a : b);
  }

  /// Berechnet Maximum einer Liste
  static double calculateMax(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Berechnet Bias (Unterschied zwischen Mittelwert und Referenzwert)
  ///
  /// Formel: Bias = μ - Referenz
  ///
  /// Null wenn kein Referenzwert vorhanden
  static double? calculateBias(
    List<double> values,
    double? referenceValue,
  ) {
    if (referenceValue == null || values.isEmpty) return null;
    return calculateMean(values) - referenceValue;
  }

  /// Berechnet Trend über Zeit mittels linearer Regression
  ///
  /// Rückgabe: Map mit 'slope' und 'r_squared'
  ///
  /// Diese Methode ist optimiert für Stabilitätstests
  /// da sie zeigt, ob Drift über Zeit auftritt
  static Map<String, double> calculateTrend(
    List<MeasurementData> measurements,
  ) {
    if (measurements.length < 2) {
      return {'slope': 0.0, 'r_squared': 0.0};
    }

    // X = Messung-Index (0, 1, 2, ...)
    // Y = Messwert
    final n = measurements.length.toDouble();
    late double sumX = 0;
    late double sumY = 0;
    late double sumXY = 0;
    late double sumX2 = 0;
    late double sumY2 = 0;

    for (int i = 0; i < measurements.length; i++) {
      final x = i.toDouble();
      final y = measurements[i].distance;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }

    // Steigung (Slope) berechnen
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // R² (Bestimmtheitsmaß) berechnen
    final numerator = (n * sumXY - sumX * sumY);
    final denominator =
        math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    final rValue = denominator == 0 ? 0.0 : numerator / denominator;
    final rSquared = rValue * rValue;

    return {
      'slope': slope,
      'r_squared': rSquared,
    };
  }

  /// Berechnet Trendanalyse (Lineare Regression) für 1D-Werte
  ///
  /// Führt lineare Regression durch um Drift über die Messreihe zu erkennen
  ///
  /// Parameter:
  /// - [values]: Liste von Messwerten (1D)
  ///
  /// Rückgabe: Map mit:
  /// - 'slope': Steigung (Drift pro Messung)
  /// - 'r_squared': Bestimmtheitsmaß (0-1, höher = stärkerer Trend)
  ///
  /// Diese Methode ist optimiert für Stabilitätstests
  /// da sie zeigt, ob Drift über Zeit auftritt
  static Map<String, double> calculateTrendFromValues(
    List<double> values,
  ) {
    if (values.length < 2) {
      return {'slope': 0.0, 'r_squared': 0.0};
    }

    // X = Messung-Index (0, 1, 2, ...)
    // Y = Messwert
    final n = values.length.toDouble();
    late double sumX = 0;
    late double sumY = 0;
    late double sumXY = 0;
    late double sumX2 = 0;
    late double sumY2 = 0;

    for (int i = 0; i < values.length; i++) {
      final x = i.toDouble();
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }

    // Steigung (Slope) berechnen
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    // R² (Bestimmtheitsmaß) berechnen
    final numerator = (n * sumXY - sumX * sumY);
    final denominator =
        math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
    final rValue = denominator == 0 ? 0.0 : numerator / denominator;
    final rSquared = rValue * rValue;

    return {
      'slope': slope,
      'r_squared': rSquared,
    };
  }
}
