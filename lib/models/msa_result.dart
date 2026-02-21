import 'analysis_mode.dart';

/// Einstufung der Messsystemeignung nach AIAG
enum MsaSuitability {
  suitable, // <10% GRR
  marginal, // 10-30% GRR
  notSuitable, // >30% GRR
}

/// Ergebnisse der MSA Typ 1 (Variables) Analyse
class MsaType1Result {
  // Analysemodus
  final AnalysisMode mode;

  // Grundlegende Statistik
  final double mean;
  final double standardDeviation;
  final double min;
  final double max;
  final int sampleCount;

  // MSA-spezifische Parameter
  final double repeatability; // Equipment Variation (σ)
  final double? bias; // Systematischer Fehler (optional)
  final double studyVariation; // 6σ (Study Variation)
  final double percentStudyVariation; // %GRR (Repeatability % TV)

  // AIAG-Bewertung
  final MsaSuitability suitability;
  final String interpretation;

  // Stabilitätsprüfung (optional)
  final Map<String, dynamic>? stabilityCheck;

  MsaType1Result({
    required this.mode,
    required this.mean,
    required this.standardDeviation,
    required this.min,
    required this.max,
    required this.sampleCount,
    required this.repeatability,
    this.bias,
    required this.studyVariation,
    required this.percentStudyVariation,
    required this.suitability,
    required this.interpretation,
    this.stabilityCheck,
  });

  /// Formatierte Ausgabe für Konsole/UI
  String toFormattedString() {
    final buffer = StringBuffer();
    buffer.writeln('╔════════════════════════════════════════════════╗');
    buffer.writeln('║     MSA TYP 1 - MESSSYSTEMANALYSE (AIAG)       ║');
    buffer.writeln('╚════════════════════════════════════════════════╝\n');

    buffer.writeln('� ANALYSEMODUS: ${mode.description}\n');

    buffer.writeln('�📊 STATISTISCHE GRUNDLAGEN:');
    buffer.writeln('   Stichprobenumfang (n):     $sampleCount');
    buffer.writeln('   Mittelwert (μ):            ${mean.toStringAsFixed(6)}');
    buffer.writeln(
        '   Standardabweichung (σ):    ${standardDeviation.toStringAsFixed(6)}');
    buffer.writeln('   Minimum:                   ${min.toStringAsFixed(6)}');
    buffer.writeln('   Maximum:                   ${max.toStringAsFixed(6)}');
    buffer.writeln(
        '   Spannweite (R):            ${(max - min).toStringAsFixed(6)}\n');

    buffer.writeln('⚙️  MESSSYSTEMPARAMETER:');
    buffer.writeln(
        '   Wiederholbarkeit (σ):      ${repeatability.toStringAsFixed(6)}');
    buffer.writeln(
        '   Study Variation (6σ):      ${studyVariation.toStringAsFixed(6)}');
    if (bias != null) {
      buffer.writeln(
          '   Bias (Abweichung):          ${bias!.toStringAsFixed(6)}');
    }
    buffer.writeln(
        '   %Study Variation (%TV):    ${percentStudyVariation.toStringAsFixed(2)}%\n');

    buffer.writeln('✓ AIAG-BEWERTUNG:');
    final suitStr = switch (suitability) {
      MsaSuitability.suitable => '✓ GEEIGNET',
      MsaSuitability.marginal => '⚠ BEDINGT GEEIGNET',
      MsaSuitability.notSuitable => '✗ NICHT GEEIGNET',
    };
    buffer.writeln('   Eignungsstufe:              $suitStr');
    buffer.writeln('   Interpretation:            $interpretation\n');

    if (stabilityCheck != null) {
      buffer.writeln('📈 STABILITÄTSPRÜFUNG:');
      buffer.writeln(
          '   Trend erkannt:             ${stabilityCheck!['hasTrend'] ?? false}');
      buffer.writeln(
          '   Trendsteigung:             ${(stabilityCheck!['trendSlope'] ?? 0).toStringAsFixed(6)}');
      buffer.writeln('\n');
    }

    buffer.writeln('╚════════════════════════════════════════════════╝');
    return buffer.toString();
  }

  /// JSON-Exportformat für Datenverarbeitung
  Map<String, dynamic> toJson() => {
        'mode': mode.toString(),
        'mean': mean,
        'standardDeviation': standardDeviation,
        'min': min,
        'max': max,
        'sampleCount': sampleCount,
        'repeatability': repeatability,
        'bias': bias,
        'studyVariation': studyVariation,
        'percentStudyVariation': percentStudyVariation,
        'suitability': suitability.toString(),
        'interpretation': interpretation,
        'stabilityCheck': stabilityCheck,
      };
}
