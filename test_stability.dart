import 'dart:io';
import 'lib/services/csv_service.dart';
import 'lib/services/msa_type1_service.dart';
import 'lib/models/analysis_mode.dart';

/// Schnelltest für Stabilitätsanalyse mit 971 Datenpunkten
void main() async {
  print('═══════════════════════════════════════════════');
  print('  MSA STABILITÄTSANALYSE - 971 Messpunkte');
  print('═══════════════════════════════════════════════\n');

  try {
    // 1. CSV-Datei laden
    print('📂 Lade CSV-Datei: x_coordinate_copy_clean.csv');
    final file = File('x_coordinate_copy_clean.csv');

    if (!await file.exists()) {
      print('❌ Fehler: Datei nicht gefunden!');
      print(
          '   Bitte stelle sicher, dass x_coordinate_copy_clean.csv im Projektverzeichnis ist.');
      return;
    }

    final csvContent = await file.readAsString();
    print('✓ Datei geladen\n');

    // 2. CSV parsen
    print('🔍 Parse CSV-Daten...');
    final parseResult = CsvService.parseCoordinates(csvContent);
    print('✓ ${parseResult.values_1d.length} Messpunkte erkannt');
    print('   Modus: ${parseResult.mode.description}\n');

    // 3. MSA Typ 1 mit Stabilitätsprüfung durchführen
    print('⚙️  Führe MSA Typ 1 Analyse mit Stabilitätsprüfung durch...');
    final result = MsaType1Service.analyzeWithMode(
      mode: parseResult.mode,
      values_1d: parseResult.values_1d,
      points_2d_direct: parseResult.points_2d_direct,
      points_2d_distances: parseResult.points_2d_distances,
      toleranceRange: 10.0, // Beispiel-Toleranz (anpassen nach Bedarf)
      analyzeStability: true, // <<< Stabilitätsprüfung aktiviert
    );
    print('✓ Analyse abgeschlossen\n');

    // 4. Ergebnisse anzeigen
    print(result.toFormattedString());

    // 5. Stabilitäts-Zusammenfassung
    if (result.stabilityCheck != null) {
      final stability = result.stabilityCheck!;
      print('\n╔════════════════════════════════════════════════╗');
      print('║        STABILITÄTS-ZUSAMMENFASSUNG             ║');
      print('╚════════════════════════════════════════════════╝\n');

      final hasTrend = stability['hasTrend'] as bool;
      final slope = stability['trendSlope'] as double;
      final rSquared = stability['r_squared'] as double;
      final sampleCount = stability['sampleCount'] as int;

      print('Status: ${hasTrend ? "⚠️  INSTABIL" : "✓ STABIL"}');
      print('');
      print('Details:');
      print('  • $sampleCount Messungen analysiert');
      print('  • R² = ${rSquared.toStringAsFixed(4)} (Schwellenwert: 0.3)');
      print('  • Trendsteigung = ${slope.toStringAsFixed(8)} pro Messung');
      print('');

      if (hasTrend) {
        print('⚠️  WARNUNG: Systematischer Trend erkannt!');
        print('');
        print('Interpretation:');
        if (slope > 0) {
          print('  • Messwerte driften aufwärts (positiver Trend)');
          print(
              '  • Mögliche Ursachen: Werkzeugverschleiß, Kalibrierungsdrift,');
          print('    Temperaturanstieg, systematische Abnutzung');
        } else {
          print('  • Messwerte driften abwärts (negativer Trend)');
          print('  • Mögliche Ursachen: Material-Schrumpfung, Temperatur-');
          print('    abfall, Kalibrierungsdrift, Ermüdungserscheinungen');
        }
        print('');
        print('Empfohlene Maßnahmen:');
        print('  1. Messsystem kalibrieren');
        print(
            '  2. Umgebungsbedingungen überprüfen (Temperatur, Feuchtigkeit)');
        print('  3. Mechanische Komponenten auf Verschleiß prüfen');
        print('  4. Weitere Messreihe zur Bestätigung durchführen');
      } else {
        print('✓ Messsystem zeigt keine signifikante Drift.');
        print('  Das System kann als zeitlich stabil betrachtet werden.');
      }
      print('');
      print('═══════════════════════════════════════════════');
    }
  } catch (e) {
    print('\n❌ Fehler bei der Analyse:');
    print('   $e');
  }
}
