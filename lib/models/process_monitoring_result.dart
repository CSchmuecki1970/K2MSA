/// Einstufung des Instrument-Status während Prozessüberwachung
enum InstrumentMonitoringStatus {
  stable, // Kein signifikanter Instrumentendrift
  drifting, // Instrument selbst driftet
}

/// Ergebnisse der Prozessüberwachungs-Analyse
///
/// Diese Analyse ist speziell für dynamische Prozesse konzipiert:
/// - Drahtziehen mit Drift
/// - Laufende Produktionsprozesse
/// - Messungen mit bekannter erwarteter Veränderung über Zeit
///
/// Unterschied zu MSA Typ 1:
/// - Typ 1: Messinstrument auf STATISCHEM Referenzteil
/// - Process Monitoring: Messinstrument auf DYNAMISCHEM/DRIFTENDEM Prozess
class ProcessMonitoringResult {
  // ═══════════════════════════════════════════════════════════════
  // STATISTISCHE BASISDATEN
  // ═══════════════════════════════════════════════════════════════
  final int sampleCount;
  final double mean;
  final double standardDeviation;
  final double min;
  final double max;

  // ═══════════════════════════════════════════════════════════════
  // INSTRUMENTEN-VARIABILITÄT (aus stabilen Bereichen extrahiert)
  // ═══════════════════════════════════════════════════════════════

  /// Standardabweichung des Messinstruments (nur zufällige Variabilität)
  /// Berechnet aus Bereichen, wo Prozess stabil ist (sich nicht verändert)
  final double instrumentStdDev;

  /// Wiederholbarkeit des Instruments (6 * σ_instrument)
  final double instrumentRepeatability;

  /// Anzahl der stabilen Bereiche, die für Instrumenten-Schätzung verwendet wurden
  final int stableRegionsDetected;

  // ═══════════════════════════════════════════════════════════════
  // PROZESSDRIFT (die tatsächliche Veränderung)
  // ═══════════════════════════════════════════════════════════════

  /// Steigung der linearen Regression über alle Messungen
  /// Einheit: (Messwert-Einheiten) pro Messung
  /// > 0: Prozess driftet aufwärts
  /// < 0: Prozess driftet abwärts
  final double driftSlope;

  /// R² der Trendanalyse (Güte der linearen Regression)
  /// 0-1: Wie gut wird der Drift durch eine Gerade beschrieben
  /// > 0.8: Sehr konsistenter Drift
  /// 0.3-0.8: Moderater Drift
  /// < 0.3: Erratischer/ungleichmäßiger Drift
  final double driftTrendStrength;

  /// Gesamte Prozess-Änderung über alle Messungen
  /// min bis max der Trendlinie (nicht der rohen Daten)
  final double totalDriftChange;

  /// Durchschnittliche Drift-Rate pro Messung
  /// = driftSlope (selbes wie Trendlinie-Steigung)
  final double driftRatePerMeasurement;

  // ═══════════════════════════════════════════════════════════════
  // QUALITÄT & GENAUIGKEIT (Signal-zu-Rausch-Verhältnis)
  // ═══════════════════════════════════════════════════════════════

  /// Signal-zu-Rausch-Verhältnis
  /// = Prozess-Variabilität ÷ Instrumenten-Variabilität
  /// > 10: Sehr saubenes Signal (gute Nachverfolgung)
  /// 3-10: Gutes Signal (noch akzeptabel)
  /// < 3: Signalverlust (Instrument-Rauschen dominiert)
  final double signalToNoiseRatio;

  /// Anteil der Gesamtvariabilität, der durch Drift erklärt wird
  /// 0-1: Je höher, desto mehr ist die Variation systematischer Drift
  /// mit instrumenteller Variabilität kombiniert
  final double driftExplanationPercentage;

  /// Verfolgungsgenauigkeit des Systems
  /// 0-1: Wie sauber folgt das System dem erwarteten Trend?
  /// 1.0: Perfekt linearer Trend (saubere Verfolgung)
  /// < 0.7: Viel Rauschen um Trendlinie herum
  final double trackingAccuracy;

  // ═══════════════════════════════════════════════════════════════
  // STABILITÄTS-BEWERTUNG
  // ═══════════════════════════════════════════════════════════════

  /// Bewertung des Instruments
  /// stable: Instrument ist stabil, beobachtete Drift = echter Prozess-Drift
  /// drifting: Instrument selbst hat zusätzliche Drift
  final InstrumentMonitoringStatus instrumentStatus;

  // ═══════════════════════════════════════════════════════════════
  // INTERPRETATION & EMPFEHLUNGEN
  // ═══════════════════════════════════════════════════════════════

  /// Menschenlesbare Interpretation der Analyse
  final String interpretation;

  /// Empfohlene Maßnahmen basierend auf Ergebnissen
  final List<String> recommendations;

  /// Rohe Messwerte für Charting (optional)
  final List<double>? measurementValues;

  /// Trendinien-Werte für Charting (optional)
  final List<double>? trendlineValues;

  /// X-Koordinaten für 2D Scatter Plot (optional)
  final List<double>? coordinateX;

  /// Y-Koordinaten für 2D Scatter Plot (optional)
  final List<double>? coordinateY;

  ProcessMonitoringResult({
    required this.sampleCount,
    required this.mean,
    required this.standardDeviation,
    required this.min,
    required this.max,
    required this.instrumentStdDev,
    required this.instrumentRepeatability,
    required this.stableRegionsDetected,
    required this.driftSlope,
    required this.driftTrendStrength,
    required this.totalDriftChange,
    required this.driftRatePerMeasurement,
    required this.signalToNoiseRatio,
    required this.driftExplanationPercentage,
    required this.trackingAccuracy,
    required this.instrumentStatus,
    required this.interpretation,
    required this.recommendations,
    this.measurementValues,
    this.trendlineValues,
    this.coordinateX,
    this.coordinateY,
  });

  /// Formatierte Ausgabe für Konsole/UI
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('╔════════════════════════════════════════════════╗');
    buffer.writeln('║   PROZESSÜBERWACHUNGS-ANALYSE (Dynamisch)      ║');
    buffer.writeln('╚════════════════════════════════════════════════╝\n');

    buffer.writeln('📊 STATISTISCHE BASISDATEN:');
    buffer.writeln('   Messungen (n):             $sampleCount');
    buffer.writeln('   Mittelwert (μ):           ${mean.toStringAsFixed(6)}');
    buffer.writeln(
        '   Standardabweichung (σ):  ${standardDeviation.toStringAsFixed(6)}');
    buffer.writeln('   Minimum:                  ${min.toStringAsFixed(6)}');
    buffer.writeln('   Maximum:                  ${max.toStringAsFixed(6)}');
    buffer.writeln(
        '   Spannweite:               ${(max - min).toStringAsFixed(6)}\n');

    buffer.writeln('🔧 INSTRUMENTEN-VARIABILITÄT:');
    buffer.writeln(
        '   σ_Instrument:             ${instrumentStdDev.toStringAsFixed(6)}');
    buffer.writeln(
        '   Wiederholbarkeit (6σ):    ${instrumentRepeatability.toStringAsFixed(6)}');
    buffer.writeln('   Stabile Regionen erkannt: $stableRegionsDetected\n');

    buffer.writeln('📈 PROZESS-DRIFT:');
    buffer.writeln(
        '   Trendsteigung:            ${driftSlope.toStringAsFixed(8)}/Messung');
    buffer.writeln(
        '   Trend-Stärke (R²):        ${driftTrendStrength.toStringAsFixed(4)}');
    buffer.writeln(
        '   Gesamte Änderung:         ${totalDriftChange.toStringAsFixed(6)}');
    buffer.writeln(
        '   Drift-Rate:               ${driftRatePerMeasurement.toStringAsFixed(8)}\n');

    buffer.writeln('📊 SIGNAL-ZU-RAUSCH-VERHÄLTNIS:');
    buffer.writeln(
        '   SNR:                      ${signalToNoiseRatio.toStringAsFixed(2)}');
    final snrStatus = switch (signalToNoiseRatio) {
      > 10 => '✓ Sehr saubenes Signal',
      > 3 => '✓ Gutes Signal',
      > 1 => '⚠ Akzeptabel mit Rauschen',
      _ => '✗ Signalverlust (Rauschen dominiert)',
    };
    buffer.writeln('   Status:                   $snrStatus');
    buffer.writeln(
        '   Drift-Erklärung:          ${driftExplanationPercentage.toStringAsFixed(1)}%');
    buffer.writeln(
        '   Verfolgungsgenauigkeit:   ${trackingAccuracy.toStringAsFixed(3)}\n');

    buffer.writeln('✓ INSTRUMENT-STATUS:');
    final statusStr = instrumentStatus == InstrumentMonitoringStatus.stable
        ? '✓ STABIL (Instrument konstant)'
        : '⚠ DRIFTEND (Instrument-Drift erkannt)';
    buffer.writeln('   $statusStr\n');

    buffer.writeln('💡 INTERPRETATION:');
    for (final line in interpretation.split('\n')) {
      if (line.isNotEmpty) {
        buffer.writeln('   $line');
      }
    }
    buffer.writeln('');

    if (recommendations.isNotEmpty) {
      buffer.writeln('📋 EMPFEHLUNGEN:');
      for (int i = 0; i < recommendations.length; i++) {
        buffer.writeln('   ${i + 1}. ${recommendations[i]}');
      }
      buffer.writeln('');
    }

    buffer.writeln('╚════════════════════════════════════════════════╝');
    return buffer.toString();
  }

  /// JSON-Exportformat
  Map<String, dynamic> toJson() => {
        'sampleCount': sampleCount,
        'mean': mean,
        'standardDeviation': standardDeviation,
        'min': min,
        'max': max,
        'instrumentStdDev': instrumentStdDev,
        'instrumentRepeatability': instrumentRepeatability,
        'stableRegionsDetected': stableRegionsDetected,
        'driftSlope': driftSlope,
        'driftTrendStrength': driftTrendStrength,
        'totalDriftChange': totalDriftChange,
        'driftRatePerMeasurement': driftRatePerMeasurement,
        'signalToNoiseRatio': signalToNoiseRatio,
        'driftExplanationPercentage': driftExplanationPercentage,
        'trackingAccuracy': trackingAccuracy,
        'instrumentStatus': instrumentStatus.toString(),
        'interpretation': interpretation,
        'recommendations': recommendations,
        'measurementValues': measurementValues,
        'trendlineValues': trendlineValues,
        'coordinateX': coordinateX,
        'coordinateY': coordinateY,
      };
}
