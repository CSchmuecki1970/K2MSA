import 'dart:math' as math;
import '../models/process_monitoring_result.dart';
import '../models/measurement_data.dart';
import 'calculation_service.dart';

/// Service für Prozessüberwachungs-Analyse
///
/// Spezialisiert auf dynamische Prozesse (wie Draht mit Drift):
/// - Trennt echten Prozess-Drift von Instrument-Rauschen
/// - Erkennt stabile Messregionen
/// - Berechnet Signal-zu-Rausch-Verhältnis
/// - Bewertet Verfolgungsgenauigkeit des Systems
class ProcessMonitoringService {
  /// Schwellenwert für "stabile Region": Wenn lokale Variabilität
  /// unter 10% der Gesamtspannweite liegt, ist es "stabil"
  static const double _stableRegionThreshold = 0.10;

  /// Minimale Größe einer stabilen Region (Messungen)
  static const int _minStableRegionSize = 5;

  /// Analysiert 1D-Messwerte als dynamischen Prozess
  ///
  /// Parameter:
  /// - [values]: Sequenzielle Messwerte (in Messreihenfolge!)
  ///
  /// Rückgabe: Prozessüberwachungs-Ergebnisse mit Drift- und Rausch-Analyse
  static ProcessMonitoringResult analyze1D({
    required List<double> values,
  }) {
    if (values.isEmpty) {
      throw ArgumentError('Mindestens ein Messwert erforderlich');
    }

    if (values.length < 2) {
      throw ArgumentError(
          'Mindestens 2 Messwerte erforderlich für Trendanalyse');
    }

    // 1. Basis-Statistiken
    final mean = CalculationService.calculateMean(values);
    final stdDev = CalculationService.calculateStandardDeviation(values);
    final min = CalculationService.calculateMin(values);
    final max = CalculationService.calculateMax(values);
    final range = max - min;

    // 2. Erkennung stabiler Regionen
    final stableRegions = _detectStableRegions(values, range);

    // 3. Instrumenten-Variabilität aus stabilen Regionen extrahieren
    final instrumentStdDev = _estimateInstrumentNoiseFromStableRegions(
      values,
      stableRegions,
      stdDev,
    );
    final instrumentRepeatability = 6 * instrumentStdDev;

    // 4. Trend-Analyse (Drift des Prozesses)
    final trendData = CalculationService.calculateTrendFromValues(values);
    final driftSlope = trendData['slope']!;
    final driftTrendStrength = trendData['r_squared']!;

    // 5. Berechne Trendlinie zur Bestimmung totaler Drift
    final trendlineValues =
        _calculateTrendlineValues(values.length, driftSlope, mean);
    final trendlineMin = CalculationService.calculateMin(trendlineValues);
    final trendlineMax = CalculationService.calculateMax(trendlineValues);
    final totalDriftChange = trendlineMax - trendlineMin;

    // 6. Signal-zu-Rausch-Verhältnis
    final signalToNoiseRatio =
        instrumentStdDev > 0 ? stdDev / instrumentStdDev : 0.0;

    // 7. Drift-Erklärung und Verfolgungsgenauigkeit
    final residuals = _calculateResiduals(values, trendlineValues);
    final residualStdDev =
        CalculationService.calculateStandardDeviation(residuals);
    final totalVariance = stdDev * stdDev;
    final driftVariance = (totalVariance - (residualStdDev * residualStdDev))
        .clamp(0.0, totalVariance);
    final driftExplanationPercentage = totalVariance > 0
        ? ((driftVariance / totalVariance) * 100).clamp(0.0, 100.0)
        : 0.0;

    // Verfolgungsgenauigkeit: 1 - (Residuen / Gesamtvariation)
    final trackingAccuracy = 1.0 - (residualStdDev / stdDev).clamp(0, 1);

    // 8. Instrument-Status
    final instrumentStatus = _assessInstrumentStatus(
      driftTrendStrength,
      signalToNoiseRatio,
      instrumentStdDev,
      stdDev,
    );

    // 9. Interpretation und Empfehlungen
    final interpretation = _generateInterpretation(
      driftSlope,
      driftTrendStrength,
      signalToNoiseRatio,
      trackingAccuracy,
      instrumentStatus,
    );

    final recommendations = _generateRecommendations(
      driftSlope,
      driftTrendStrength,
      signalToNoiseRatio,
      trackingAccuracy,
      instrumentStatus,
      stableRegions.length,
    );

    return ProcessMonitoringResult(
      sampleCount: values.length,
      mean: mean,
      standardDeviation: stdDev,
      min: min,
      max: max,
      instrumentStdDev: instrumentStdDev,
      instrumentRepeatability: instrumentRepeatability,
      stableRegionsDetected: stableRegions.length,
      driftSlope: driftSlope,
      driftTrendStrength: driftTrendStrength,
      totalDriftChange: totalDriftChange,
      driftRatePerMeasurement: driftSlope,
      signalToNoiseRatio: signalToNoiseRatio,
      driftExplanationPercentage: driftExplanationPercentage,
      trackingAccuracy: trackingAccuracy,
      instrumentStatus: instrumentStatus,
      interpretation: interpretation,
      recommendations: recommendations,
      measurementValues: values,
      trendlineValues: trendlineValues,
    );
  }

  /// Analysiert 2D-Messwerte (x,y Wertepaare) als dynamischen Prozess
  ///
  /// Kombiniert X und Y Werte zu einer Sequenz und analysiert den Gesamtdrift
  ///
  /// Parameter:
  /// - [points]: Sequenzielle 2D-Punkte (in Messreihenfolge!)
  ///
  /// Rückgabe: Prozessüberwachungs-Ergebnisse
  /// Analysiert 2D direkte Messpunkte (X,Y Paare) als dynamischen Prozess
  ///
  /// Parameter:
  /// - [points]: Sequenzielle Messpunkte mit X,Y Koordinaten (in Messreihenfolge!)
  ///
  /// Rückgabe: Prozessüberwachungs-Ergebnisse mit X,Y Scatter Plot Support
  static ProcessMonitoringResult analyze2DDirect({
    required List<dynamic> points,
  }) {
    if (points.isEmpty) {
      throw ArgumentError('Mindestens ein Datenpunkt erforderlich');
    }

    // Extrahiere X und Y Koordinaten für Scatter Plot
    final coordinateX = <double>[];
    final coordinateY = <double>[];

    // Kombiniere X und Y Werte aus den Punkten (wie MSA Type 1 tut)
    final allValues = <double>[];
    for (final point in points) {
      final x = point.x as double;
      final y = point.y as double;
      coordinateX.add(x);
      coordinateY.add(y);
      allValues.add(x);
      allValues.add(y);
    }

    // Nutze die 1D Analysen-Logik auf der kombinierten Sequenz
    final baseResult = analyze1D(values: allValues);

    // Erstelle Ergebnis mit X,Y Koordinaten für Scatter Plot
    return ProcessMonitoringResult(
      sampleCount: baseResult.sampleCount,
      mean: baseResult.mean,
      standardDeviation: baseResult.standardDeviation,
      min: baseResult.min,
      max: baseResult.max,
      instrumentStdDev: baseResult.instrumentStdDev,
      instrumentRepeatability: baseResult.instrumentRepeatability,
      stableRegionsDetected: baseResult.stableRegionsDetected,
      driftSlope: baseResult.driftSlope,
      driftTrendStrength: baseResult.driftTrendStrength,
      totalDriftChange: baseResult.totalDriftChange,
      driftRatePerMeasurement: baseResult.driftRatePerMeasurement,
      signalToNoiseRatio: baseResult.signalToNoiseRatio,
      driftExplanationPercentage: baseResult.driftExplanationPercentage,
      trackingAccuracy: baseResult.trackingAccuracy,
      instrumentStatus: baseResult.instrumentStatus,
      interpretation: baseResult.interpretation,
      recommendations: baseResult.recommendations,
      measurementValues: baseResult.measurementValues,
      trendlineValues: baseResult.trendlineValues,
      coordinateX: coordinateX,
      coordinateY: coordinateY,
    );
  }

  /// Analysiert 2D Distanz-Messwerte als dynamischen Prozess
  ///
  /// Analysiert die Distanzen zwischen Punktpaaren über Zeit
  ///
  /// Parameter:
  /// - [measurements]: Sequenzielle Messdaten mit Distanzen (in Messreihenfolge!)
  ///
  /// Rückgabe: Prozessüberwachungs-Ergebnisse mit Scatter Plot Support
  static ProcessMonitoringResult analyze2DDistances({
    required List<MeasurementData> measurements,
  }) {
    if (measurements.isEmpty) {
      throw ArgumentError('Mindestens ein Messdatensatz erforderlich');
    }

    // Extrahiere Distanzwerte
    final distances = measurements.map((m) => m.distance).toList();

    // Extrahiere point1 Koordinaten für Scatter Plot
    final coordinateX = measurements.map((m) => m.point1.x).toList();
    final coordinateY = measurements.map((m) => m.point1.y).toList();

    // Nutze die 1D Analysen-Logik auf den Distanzen
    final baseResult = analyze1D(values: distances);

    // Erstelle Ergebnis mit X,Y Koordinaten für Scatter Plot
    return ProcessMonitoringResult(
      sampleCount: baseResult.sampleCount,
      mean: baseResult.mean,
      standardDeviation: baseResult.standardDeviation,
      min: baseResult.min,
      max: baseResult.max,
      instrumentStdDev: baseResult.instrumentStdDev,
      instrumentRepeatability: baseResult.instrumentRepeatability,
      stableRegionsDetected: baseResult.stableRegionsDetected,
      driftSlope: baseResult.driftSlope,
      driftTrendStrength: baseResult.driftTrendStrength,
      totalDriftChange: baseResult.totalDriftChange,
      driftRatePerMeasurement: baseResult.driftRatePerMeasurement,
      signalToNoiseRatio: baseResult.signalToNoiseRatio,
      driftExplanationPercentage: baseResult.driftExplanationPercentage,
      trackingAccuracy: baseResult.trackingAccuracy,
      instrumentStatus: baseResult.instrumentStatus,
      interpretation: baseResult.interpretation,
      recommendations: baseResult.recommendations,
      measurementValues: baseResult.measurementValues,
      trendlineValues: baseResult.trendlineValues,
      coordinateX: coordinateX,
      coordinateY: coordinateY,
    );
  }

  /// Erkennt Bereiche mit stabilen Werten (minimale Variabilität)
  static List<(int start, int end)> _detectStableRegions(
    List<double> values,
    double totalRange,
  ) {
    final regions = <(int, int)>[];
    final threshold = totalRange * _stableRegionThreshold;

    int? regionStart;
    for (int i = 0; i < values.length - _minStableRegionSize; i++) {
      // Prüfe Fenster von _minStableRegionSize Elementen
      final window = values.sublist(i, i + _minStableRegionSize);
      final windowMin = window.reduce((a, b) => a < b ? a : b);
      final windowMax = window.reduce((a, b) => a > b ? a : b);
      final windowVariation = windowMax - windowMin;

      if (windowVariation <= threshold) {
        if (regionStart == null) {
          regionStart = i;
        }
      } else {
        if (regionStart != null) {
          regions.add((regionStart, i + _minStableRegionSize - 1));
          regionStart = null;
        }
      }
    }

    if (regionStart != null) {
      regions.add((regionStart, values.length - 1));
    }

    return regions;
  }

  /// Schätzt Instrumenten-Rauschen aus stabilen Regionen
  static double _estimateInstrumentNoiseFromStableRegions(
    List<double> values,
    List<(int start, int end)> stableRegions,
    double overallStdDev,
  ) {
    if (stableRegions.isEmpty) {
      // Fallback: Verwende Gesamt-StdDev als Schätzung
      return overallStdDev * 0.3; // Konservative Annahme
    }

    final stableValues = <double>[];
    for (final region in stableRegions) {
      stableValues.addAll(values.sublist(region.$1, region.$2 + 1));
    }

    if (stableValues.length < 2) {
      return overallStdDev * 0.3;
    }

    final stableStdDev =
        CalculationService.calculateStandardDeviation(stableValues);
    return stableStdDev;
  }

  /// Berechnet Trendlinie-Werte basierend auf linearer Regression
  static List<double> _calculateTrendlineValues(
    int length,
    double slope,
    double mean,
  ) {
    final values = <double>[];
    for (int i = 0; i < length; i++) {
      final x = i.toDouble();
      // Trendlinie: y = slope * x + intercept
      // intercept so berechnen, dass die Linie durch den Durchschnitt geht
      final intercept = mean - slope * ((length - 1) / 2);
      values.add(slope * x + intercept);
    }
    return values;
  }

  /// Berechnet Residuen (Abweichungen von der Trendlinie)
  static List<double> _calculateResiduals(
    List<double> actual,
    List<double> trendline,
  ) {
    final residuals = <double>[];
    for (int i = 0; i < actual.length; i++) {
      residuals.add(actual[i] - trendline[i]);
    }
    return residuals;
  }

  /// Bewertet Instrument-Status basierend auf mehreren Faktoren
  static InstrumentMonitoringStatus _assessInstrumentStatus(
    double driftTrendStrength,
    double signalToNoiseRatio,
    double instrumentStdDev,
    double overallStdDev,
  ) {
    // Wenn SNR > 3 und Trend konsistent: Instrument ist stabil
    // Wenn SNR < 2 ODER hoher Trend-Rauschen (R² < 0.3): Instrument driftet
    if (signalToNoiseRatio > 3.0 && driftTrendStrength > 0.3) {
      return InstrumentMonitoringStatus.stable;
    } else if (signalToNoiseRatio < 2.0) {
      return InstrumentMonitoringStatus.drifting;
    } else {
      // Grenzbereich: Prüfe Verhältnis Instrument zu Gesamt
      if (instrumentStdDev < overallStdDev * 0.5) {
        return InstrumentMonitoringStatus.stable;
      } else {
        return InstrumentMonitoringStatus.drifting;
      }
    }
  }

  /// Generiert menschenlesbare Interpretation
  static String _generateInterpretation(
    double driftSlope,
    double driftTrendStrength,
    double signalToNoiseRatio,
    double trackingAccuracy,
    InstrumentMonitoringStatus instrumentStatus,
  ) {
    final buffer = StringBuffer();

    // Drift-Situation
    if (driftTrendStrength > 0.8) {
      buffer.writeln(
        'Der Prozess zeigt einen sehr konsistenten linearen Drift. '
        'Das Messsystem verfolgt den Prozess sehr sauber.',
      );
    } else if (driftTrendStrength > 0.5) {
      buffer.writeln(
        'Der Prozess driftet mit moderater Konsistenz. '
        'Der Trend ist deutlich erkennbar, aber mit etwas Variabilität.',
      );
    } else if (driftTrendStrength > 0.3) {
      buffer.writeln(
        'Der Prozess zeigt einen schwachen Trend, überlagert durch Variabilität. '
        'Drift ist erkennbar, aber Rauschen ist bedeutsam.',
      );
    } else {
      buffer.writeln(
        'Der Prozess zeigt keinen klaren linearen Trend. '
        'Die Messungen sind hauptsächlich Rauschen/Variabilität.',
      );
    }

    // Signal-zu-Rausch
    buffer.writeln('');
    if (signalToNoiseRatio > 10) {
      buffer.writeln(
        'Das Signal-zu-Rausch-Verhältnis ist ausgezeichnet. '
        'Der echte Prozess-Drift ist deutlich vom Instrument-Rauschen separierbar.',
      );
    } else if (signalToNoiseRatio > 3) {
      buffer.writeln(
        'Das Signal-zu-Rausch-Verhältnis ist gut. '
        'Der Prozess-Drift ist klar messbar mit akzeptablem Rauschen.',
      );
    } else if (signalToNoiseRatio > 1) {
      buffer.writeln(
        'Das Signal-zu-Rausch-Verhältnis ist schwach. '
        'Der Prozess-Drift ist von Instrument-Rauschen überlagert.',
      );
    } else {
      buffer.writeln(
        'Das Signal-zu-Rausch-Verhältnis ist sehr schlecht. '
        'Das Instrument-Rauschen dominiert über echte Prozess-Änderungen.',
      );
    }

    // Instrument-Status
    buffer.writeln('');
    if (instrumentStatus == InstrumentMonitoringStatus.stable) {
      buffer.writeln(
        'Das Messinstrument selbst ist STABIL. '
        'Beobachtete Änderungen sind echte Prozess-Drift, nicht Instrument-Drift.',
      );
    } else {
      buffer.writeln(
        'Das Messinstrument zeigt EIGENE DRIFT. '
        'Zusätzlich zum Prozess-Drift hat auch das Instrument eine Drift. '
        'Dies überlagert die Prozess-Messungen.',
      );
    }

    return buffer.toString();
  }

  /// Generiert spezifische Empfehlungen
  static List<String> _generateRecommendations(
    double driftSlope,
    double driftTrendStrength,
    double signalToNoiseRatio,
    double trackingAccuracy,
    InstrumentMonitoringStatus instrumentStatus,
    int stableRegionsDetected,
  ) {
    final recommendations = <String>[];

    // Instrument-Empfehlungen
    if (instrumentStatus == InstrumentMonitoringStatus.drifting) {
      recommendations.add(
        'Instrument kalibrieren: Messsystem zeigt eigene Drift zusätzlich zum Prozess-Drift.',
      );
    } else if (signalToNoiseRatio < 3) {
      recommendations.add(
        'Instrument überprüfen: SNR ist niedrig, möglicherweise defekt oder nicht kalibriert.',
      );
    }

    // Prozess-Empfehlungen
    if (driftTrendStrength > 0.7) {
      if (driftSlope > 0) {
        recommendations.add(
          'Prozess-Drift aufwärts: Überprüfen Sie Verschleiß, Temperaturänderungen oder Kalibrierung.',
        );
      } else {
        recommendations.add(
          'Prozess-Drift abwärts: Überprüfen Sie Material-Eigenschaften oder Umgebungsbedingungen.',
        );
      }
    }

    // SNR/Qualität-Empfehlungen
    if (signalToNoiseRatio < 5) {
      recommendations.add(
        'Mehr Messungen sammeln: Niedrige SNR erfordert mehr Daten für robuste Schlussfolgerungen.',
      );
    }

    if (stableRegionsDetected == 0) {
      recommendations.add(
        'Referenzmessungen hinzufügen: Keine stabilen Regionen erkannt. '
        'Messungen eines stabilen/stationären Referenzobjekts könnten Instrument-Rauschen klären.',
      );
    }

    if (trackingAccuracy < 0.7 && signalToNoiseRatio > 3) {
      recommendations.add(
        'Prozess-Stabilität prüfen: Hohe Residuen um Trendlinie deuten auf ungleichmäßigen Drift hin.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'System läuft optimal: Messinstrument ist stabil und verfolgt den Prozess erkannte Drift sauber..',
      );
    }

    return recommendations;
  }
}
