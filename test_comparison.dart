import 'dart:io';
import 'lib/services/csv_service.dart';
import 'lib/services/msa_type1_service.dart';
import 'lib/services/process_monitoring_service.dart';
import 'lib/models/analysis_mode.dart';

/// Vergleichende Analyse: MSA Type 1 vs. Process Monitoring
/// Zeigt den Unterschied zwischen Instrument-Fokus und Process-Fokus
void main() async {
  print('═══════════════════════════════════════════════════════════════════');
  print('  VERGLEICHENDE ANALYSE: MSA Type 1 vs. Process Monitoring');
  print(
      '═══════════════════════════════════════════════════════════════════\n');

  try {
    // 1. CSV laden
    print('📂 Lade CSV-Datei: x_coordinate_copy_clean.csv');
    final file = File('x_coordinate_copy_clean.csv');

    if (!await file.exists()) {
      print('❌ Fehler: Datei nicht gefunden!');
      return;
    }

    final csvContent = await file.readAsString();
    final parseResult = CsvService.parseCoordinates(csvContent);
    print('✓ ${parseResult.values_1d.length} Messwerte geladen\n');

    // 2. MSA Type 1 Analyse
    print(
        '═══════════════════════════════════════════════════════════════════');
    print('  ANALYSE 1: MSA TYP 1 - Instruments-Fokus');
    print('  (Bewertet: Wiederholbarkeit & Präzision des Instruments)');
    print(
        '═══════════════════════════════════════════════════════════════════\n');

    final msaResult = MsaType1Service.analyzeWithMode(
      mode: parseResult.mode,
      values_1d: parseResult.values_1d,
      points_2d_direct: parseResult.points_2d_direct,
      points_2d_distances: parseResult.points_2d_distances,
      toleranceRange: 10.0,
      analyzeStability: true,
    );

    print(msaResult.toFormattedString());

    // 3. Process Monitoring Analyse
    print('\n');
    print(
        '═══════════════════════════════════════════════════════════════════');
    print('  ANALYSE 2: PROCESS MONITORING - Prozess-Fokus');
    print('  (Bewertet: Instrument-Rauschen vs. Echter Prozess-Drift)');
    print(
        '═══════════════════════════════════════════════════════════════════\n');

    final procResult = ProcessMonitoringService.analyze1D(
      values: parseResult.values_1d,
    );

    print(procResult.toFormattedString());

    // 4. Zusammenfassender Vergleich
    print('\n');
    print(
        '═══════════════════════════════════════════════════════════════════');
    print('  ZUSAMMENFASSUNG: WAS BEDEUTEN DIE UNTERSCHIEDE?');
    print(
        '═══════════════════════════════════════════════════════════════════\n');

    print('🎯 MSA TYPE 1 ERGEBNIS:');
    print('   Suitability: ${msaResult.suitability}');
    print('   %TV: ${msaResult.percentStudyVariation.toStringAsFixed(2)}%');
    print('   Interpretation: ${msaResult.interpretation}\n');

    print('📊 PROCESS MONITORING ERGEBNIS:');
    print(
        '   Signal-zu-Rausch: ${procResult.signalToNoiseRatio.toStringAsFixed(2)}');
    print('   Instrument-Status: ${procResult.instrumentStatus}');
    print(
        '   Prozess-Drift: ${procResult.driftSlope.toStringAsFixed(8)}/Messung\n');

    print('💡 INTERPRETATION FÜR IHR DRAHTZIEH-SYSTEM:');
    print('');
    print('   MSA Type 1 sagt:');
    print(
        '   "Das Instrument hat viel Streuung (${msaResult.percentStudyVariation.toStringAsFixed(1)}% TV)"');
    print('');
    print('   Process Monitoring sagt:');
    print(
        '   "Ein großer Teil dieser Streuung ist ECHTE DRAHT-BEWEGUNG (${procResult.driftExplanationPercentage.toStringAsFixed(1)}% Drift)"');
    print(
        '   "Das Instrument selbst hat Signal-zu-Rausch von ${procResult.signalToNoiseRatio.toStringAsFixed(2)}"');
    print('');
    print('   → Der Unterschied zeigt:');
    print('   - Die Camera ist STABIL genug, um den Draht zu verfolgen');
    print('   - Aber hat auch innere Variabilität/Rauschen');
    print('   - Das ist NORMAL für reale Messsysteme!');
    print('');
    print(
        '═══════════════════════════════════════════════════════════════════');
  } catch (e) {
    print('\n❌ Fehler:');
    print('   $e');
  }
}
