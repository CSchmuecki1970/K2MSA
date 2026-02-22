import 'analysis_mode.dart';
import 'analysis_metadata.dart';

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

  // Discrimination & Resolution (AIAG Critical)
  final double? discriminationRatio; // DR = Tolerance / Study Variation
  final int? numberOfDistinctCategories; // NDC = DR * 1.41
  final double? resolutionPercent; // Resolution as % of tolerance

  // Confidence & Control Intervals
  final double confidenceIntervalLower; // 95% CI lower bound
  final double confidenceIntervalUpper; // 95% CI upper bound
  final double controlLimitLower; // LCL = mean - 3σ
  final double controlLimitUpper; // UCL = mean + 3σ

  // Process Capability (if tolerance available)
  final double? cp; // Potential capability
  final double? cpk; // Actual capability (considers centering)
  final double? toleranceUsedPercent; // % of tolerance band used

  // AIAG-Bewertung
  final MsaSuitability suitability;
  final String interpretation;

  // Stabilitätsprüfung (optional)
  final Map<String, dynamic>? stabilityCheck;

  // Analyse-Metadaten (Traceability & Professional Info)
  final AnalysisMetadata? metadata;

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
    // Discrimination & Resolution
    this.discriminationRatio,
    this.numberOfDistinctCategories,
    this.resolutionPercent,
    // Confidence & Control Intervals
    required this.confidenceIntervalLower,
    required this.confidenceIntervalUpper,
    required this.controlLimitLower,
    required this.controlLimitUpper,
    // Process Capability
    this.cp,
    this.cpk,
    this.toleranceUsedPercent,
    // AIAG Assessment
    required this.suitability,
    required this.interpretation,
    this.stabilityCheck,
    this.metadata,
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

    // Discrimination & Resolution
    if (discriminationRatio != null) {
      buffer.writeln('🔍 DISCRIMINATION & AUFLÖSUNG:');
      buffer.writeln(
          '   Discrimination Ratio (DR): ${discriminationRatio!.toStringAsFixed(2)}');
      if (numberOfDistinctCategories != null) {
        buffer.writeln(
            '   Distinct Categories (NDC):  $numberOfDistinctCategories');
      }
      if (resolutionPercent != null) {
        buffer.writeln(
            '   Auflösung (% Toleranz):     ${resolutionPercent!.toStringAsFixed(2)}%');
      }
      buffer.writeln('');
    }

    // Confidence & Control Intervals
    buffer.writeln('📏 KONFIDENZ & KONTROLLGRENZEN:');
    buffer.writeln(
        '   95% CI Untergrenze:        ${confidenceIntervalLower.toStringAsFixed(6)}');
    buffer.writeln(
        '   95% CI Obergrenze:         ${confidenceIntervalUpper.toStringAsFixed(6)}');
    buffer.writeln(
        '   Kontrollgrenze (LCL):      ${controlLimitLower.toStringAsFixed(6)}');
    buffer.writeln(
        '   Kontrollgrenze (UCL):      ${controlLimitUpper.toStringAsFixed(6)}\n');

    // Process Capability
    if (cp != null || cpk != null) {
      buffer.writeln('📈 PROZESSFÄHIGKEIT:');
      if (cp != null) {
        buffer
            .writeln('   Cp (Potenzial):            ${cp!.toStringAsFixed(3)}');
      }
      if (cpk != null) {
        buffer.writeln(
            '   Cpk (Tatsächlich):         ${cpk!.toStringAsFixed(3)}');
      }
      if (toleranceUsedPercent != null) {
        buffer.writeln(
            '   Toleranznutzung:           ${toleranceUsedPercent!.toStringAsFixed(2)}%');
      }
      buffer.writeln('');
    }

    buffer.writeln('✓ AIAG-BEWERTUNG:');
    final suitStr = switch (suitability) {
      MsaSuitability.suitable => '✓ GEEIGNET',
      MsaSuitability.marginal => '⚠ BEDINGT GEEIGNET',
      MsaSuitability.notSuitable => '✗ NICHT GEEIGNET',
    };
    buffer.writeln('   Eignungsstufe:              $suitStr');
    buffer.writeln('   Interpretation:            $interpretation\n');

    // Stability Check (Enhanced Display)
    if (stabilityCheck != null) {
      final hasTrend = stabilityCheck!['hasTrend'] ?? false;
      final trendSlope = stabilityCheck!['trendSlope'] ?? 0.0;
      final rSquared = stabilityCheck!['r_squared'] ?? 0.0;
      final sampleCount = stabilityCheck!['sampleCount'] ?? 0;

      buffer.writeln('📊 STABILITÄTSANALYSE:');
      buffer.writeln('   Stichprobengröße:          $sampleCount Messungen');
      buffer.writeln(
          '   R² (Bestimmtheitsmaß):     ${rSquared.toStringAsFixed(4)} ${rSquared > 0.3 ? "⚠️" : "✓"}');
      buffer.writeln(
          '   Trendsteigung:             ${trendSlope.toStringAsFixed(8)} pro Messung');

      final stabilityStatus =
          hasTrend ? '⚠ INSTABIL (Trend erkannt)' : '✓ STABIL';
      buffer.writeln('   Status:                    $stabilityStatus');

      if (hasTrend) {
        final direction = trendSlope > 0 ? 'aufwärts' : 'abwärts';
        buffer.writeln(
            '   ⚠️  Warnung: Systematischer Trend $direction erkannt!');
        buffer.writeln('      → Kalibrierung oder Systemcheck empfohlen');
      }
      buffer.writeln('');
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
        // Discrimination & Resolution
        'discriminationRatio': discriminationRatio,
        'numberOfDistinctCategories': numberOfDistinctCategories,
        'resolutionPercent': resolutionPercent,
        // Confidence & Control Intervals
        'confidenceIntervalLower': confidenceIntervalLower,
        'confidenceIntervalUpper': confidenceIntervalUpper,
        'controlLimitLower': controlLimitLower,
        'controlLimitUpper': controlLimitUpper,
        // Process Capability
        'cp': cp,
        'cpk': cpk,
        'toleranceUsedPercent': toleranceUsedPercent,
        // Assessment
        'suitability': suitability.toString(),
        'interpretation': interpretation,
        'stabilityCheck': stabilityCheck,
      };
}
