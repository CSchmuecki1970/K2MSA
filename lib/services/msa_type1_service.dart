import '../models/measurement_data.dart';
import '../models/msa_result.dart';
import '../models/analysis_mode.dart';
import '../models/coordinate_point.dart';
import 'calculation_service.dart';

/// Service für MSA Typ 1 (VARIABLES) Messsystemanalyse nach AIAG
///
/// MSA Typ 1 konzentriert sich auf die Variabilität eines Messsystems
/// ohne mehrere Prüfer oder Wiederholungen. Ideal für automatisierte
/// Messgeräte oder vereinfachte GAGE-Analysen.
///
/// Unterstützt 3 Modi:
/// - 1D: Analyse nur von X-Werten
/// - 2D direkt: Analyse von X,Y Wertepaaren (kombiniert)
/// - 2D Distanzen: Analyse von Distanzen zwischen zwei Punkten
///
/// Wichtige Annahmen:
/// - Alle Messungen stammen von einem Apparat/Prüfer
/// - Dieselbe Messmethode für alle Messungen
/// - Teil der Teile stammt aus Normalverteilung (∈ ~ N(μ, σ²))
class MsaType1Service {
  /// AIAG Empfohlene Toleranzbasis für %Study Variation
  /// - <10%: Messsystem ist geeignet
  /// - 10-30%: Bedingt geeignet (acceptable with caution)
  /// - >30%: Nicht geeignet (not acceptable)
  static const double _suitableBoundary = 0.10;
  static const double _marginalBoundary = 0.30;

  /// Analysiert Daten je nach Analysemodus
  ///
  /// Unterstützt:
  /// - [AnalysisMode.oneD]: Analyse von 1D-Werten
  /// - [AnalysisMode.twoD_direct]: Analyse von X,Y Wertepaaren
  /// - [AnalysisMode.twoD_distances]: Analyse von Distanzen
  static MsaType1Result analyzeWithMode({
    required AnalysisMode mode,
    required List<double> values_1d,
    required List<dynamic> points_2d_direct,
    required List<dynamic> points_2d_distances,
    List<MeasurementData>? measurements_distances,
    double? toleranceRange,
    double? referenceValue,
    bool analyzeStability = true,
  }) {
    switch (mode) {
      case AnalysisMode.oneD:
        return _analyze1D(
          values: values_1d,
          toleranceRange: toleranceRange,
          referenceValue: referenceValue,
          analyzeStability: analyzeStability,
        );

      case AnalysisMode.twoD_direct:
        return _analyze2DDirect(
          points: points_2d_direct,
          toleranceRange: toleranceRange,
          referenceValue: referenceValue,
          analyzeStability: analyzeStability,
        );

      case AnalysisMode.twoD_distances:
        return _analyze2DDistances(
          measurements: measurements_distances ?? [],
          toleranceRange: toleranceRange,
          referenceValue: referenceValue,
          analyzeStability: analyzeStability,
        );
    }
  }

  /// Analysiert 1D-Daten (nur X-Werte)
  static MsaType1Result _analyze1D({
    required List<double> values,
    double? toleranceRange,
    double? referenceValue,
    bool analyzeStability = true,
  }) {
    if (values.isEmpty) {
      throw ArgumentError('Mindestens ein Messwert erforderlich');
    }

    final mean = CalculationService.calculateMean(values);
    final stdDev = CalculationService.calculateStandardDeviation(values);
    final min = CalculationService.calculateMin(values);
    final max = CalculationService.calculateMax(values);

    final repeatability = stdDev;
    final studyVariation = 6 * repeatability;

    final effective_tolerance = toleranceRange ?? (max - min);
    final percentStudyVariation =
        effective_tolerance == 0 ? 0.0 : studyVariation / effective_tolerance;

    final bias = referenceValue == null ? null : mean - referenceValue;

    final suitability = _evaluateSuitability(percentStudyVariation);
    final interpretation = _interpretSuitability(
      suitability,
      percentStudyVariation,
      bias,
      AnalysisMode.oneD,
    );

    return MsaType1Result(
      mode: AnalysisMode.oneD,
      mean: mean,
      standardDeviation: stdDev,
      min: min,
      max: max,
      sampleCount: values.length,
      repeatability: repeatability,
      bias: bias,
      studyVariation: studyVariation,
      percentStudyVariation: percentStudyVariation,
      suitability: suitability,
      interpretation: interpretation,
      stabilityCheck: null,
    );
  }

  /// Analysiert 2D-Daten direkt (X,Y Wertepaare kombiniert)
  static MsaType1Result _analyze2DDirect({
    required List<dynamic> points,
    double? toleranceRange,
    double? referenceValue,
    bool analyzeStability = true,
  }) {
    if (points.isEmpty) {
      throw ArgumentError('Mindestens ein Datenpunkt erforderlich');
    }

    // Kombiniere X und Y Werte aus den Punkten
    final allValues = <double>[];
    for (final point in points) {
      // Sichere Typ-Konvertierung
      final x = point is CoordinatePoint ? point.x : (point.x as double?);
      final y = point is CoordinatePoint ? point.y : (point.y as double?);

      if (x == null || y == null) {
        throw ArgumentError(
          'Ungültige Koordinaten in Punkt: x=$x, y=$y',
        );
      }

      allValues.add(x);
      allValues.add(y);
    }

    final mean = CalculationService.calculateMean(allValues);
    final stdDev = CalculationService.calculateStandardDeviation(allValues);
    final min = CalculationService.calculateMin(allValues);
    final max = CalculationService.calculateMax(allValues);

    final repeatability = stdDev;
    final studyVariation = 6 * repeatability;

    final effective_tolerance = toleranceRange ?? (max - min);
    final percentStudyVariation =
        effective_tolerance == 0 ? 0.0 : studyVariation / effective_tolerance;

    final bias = referenceValue == null ? null : mean - referenceValue;

    final suitability = _evaluateSuitability(percentStudyVariation);
    final interpretation = _interpretSuitability(
      suitability,
      percentStudyVariation,
      bias,
      AnalysisMode.twoD_direct,
    );

    return MsaType1Result(
      mode: AnalysisMode.twoD_direct,
      mean: mean,
      standardDeviation: stdDev,
      min: min,
      max: max,
      sampleCount: points.length,
      repeatability: repeatability,
      bias: bias,
      studyVariation: studyVariation,
      percentStudyVariation: percentStudyVariation,
      suitability: suitability,
      interpretation: interpretation,
      stabilityCheck: null,
    );
  }

  /// Analysiert 2D-Daten nach Distanzen (Original-Modus)
  static MsaType1Result _analyze2DDistances({
    required List<MeasurementData> measurements,
    double? toleranceRange,
    double? referenceValue,
    bool analyzeStability = true,
  }) {
    if (measurements.isEmpty) {
      throw ArgumentError('Mindestens ein Messdatensatz erforderlich');
    }

    // Schritt 1: Grundstatistiken aus Abstandsmessungen
    final distances = measurements.map((m) => m.distance).toList();

    final mean = CalculationService.calculateMean(distances);
    final stdDev = CalculationService.calculateStandardDeviation(distances);
    final min = CalculationService.calculateMin(distances);
    final max = CalculationService.calculateMax(distances);

    // Schritt 2: Wiederholbarkeit (Equipment Variation)
    final repeatability = stdDev;

    // Schritt 3: Study Variation (6σ)
    final studyVariation = 6 * repeatability;

    // Schritt 4: %Study Variation (%GRR)
    final effective_tolerance = toleranceRange ?? (max - min);
    final percentStudyVariation =
        effective_tolerance == 0 ? 0.0 : studyVariation / effective_tolerance;

    // Schritt 5: Bias (falls Referenzwert vorhanden)
    final bias = CalculationService.calculateBias(distances, referenceValue);

    // Schritt 6: AIAG Eignungsbewertung
    final suitability = _evaluateSuitability(percentStudyVariation);
    final interpretation = _interpretSuitability(
      suitability,
      percentStudyVariation,
      bias,
      AnalysisMode.twoD_distances,
    );

    // Schritt 7: Stabilitätsprüfung (optional)
    Map<String, dynamic>? stabilityCheck;
    if (analyzeStability && measurements.length > 10) {
      final trendData = CalculationService.calculateTrend(measurements);
      stabilityCheck = {
        'hasTrend': trendData['r_squared']! > 0.3,
        'trendSlope': trendData['slope'],
        'r_squared': trendData['r_squared'],
        'sampleCount': measurements.length,
      };
    }

    return MsaType1Result(
      mode: AnalysisMode.twoD_distances,
      mean: mean,
      standardDeviation: stdDev,
      min: min,
      max: max,
      sampleCount: measurements.length,
      repeatability: repeatability,
      bias: bias,
      studyVariation: studyVariation,
      percentStudyVariation: percentStudyVariation,
      suitability: suitability,
      interpretation: interpretation,
      stabilityCheck: stabilityCheck,
    );
  }

  /// Bewertet Messsystem nach AIAG-Grenzen
  static MsaSuitability _evaluateSuitability(double percentStudyVariation) {
    if (percentStudyVariation < _suitableBoundary) {
      return MsaSuitability.suitable;
    } else if (percentStudyVariation <= _marginalBoundary) {
      return MsaSuitability.marginal;
    } else {
      return MsaSuitability.notSuitable;
    }
  }

  /// Generiert textuelle Interpretation der Messsystemeignung
  static String _interpretSuitability(
    MsaSuitability suitability,
    double percentStudyVariation,
    double? bias,
    AnalysisMode mode,
  ) {
    final buffer = StringBuffer();
    final modeText = mode.description;

    switch (suitability) {
      case MsaSuitability.suitable:
        buffer.write(
          'Das Messsystem ist GEEIGNET (${(percentStudyVariation * 100).toStringAsFixed(2)}% TV). '
          'Die Messunsicherheit ist klein im Vergleich zur Prozess-Variabilität [${modeText}]. ',
        );

      case MsaSuitability.marginal:
        buffer.write(
          'Das Messsystem ist BEDINGT GEEIGNET (${(percentStudyVariation * 100).toStringAsFixed(2)}% TV). '
          'Es kann verwendet werden, erfordert aber kritische Überwachung [${modeText}]. ',
        );

      case MsaSuitability.notSuitable:
        buffer.write(
          'Das Messsystem ist NICHT GEEIGNET (${(percentStudyVariation * 100).toStringAsFixed(2)}% TV). '
          'Zu hohe Messunsicherheit. Reparatur/Kalibrierung erforderlich [${modeText}]. ',
        );
    }

    // Bias-Warnung falls signifikant
    if (bias != null && bias.abs() > 0.0) {
      buffer.write(
        'Warnung: Systematischer Fehler (Bias) von ${bias.toStringAsFixed(6)} erkannt. ',
      );
    }

    return buffer.toString();
  }
}
