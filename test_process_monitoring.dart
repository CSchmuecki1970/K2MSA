import 'dart:io';
import 'lib/services/csv_service.dart';
import 'lib/services/process_monitoring_service.dart';
import 'lib/models/analysis_mode.dart';

/// Test der Prozessüberwachungs-Analyse mit Drahtzieh-Daten
void main() async {
  print('═══════════════════════════════════════════════════════════');
  print('  PROZESSÜBERWACHUNGS-ANALYSE - Drahtzieh-Messdaten');
  print('═══════════════════════════════════════════════════════════\n');

  try {
    // 1. CSV laden
    print('📂 Lade CSV-Datei: x_coordinate_copy_clean.csv');
    final file = File('x_coordinate_copy_clean.csv');

    if (!await file.exists()) {
      print('❌ Fehler: Datei nicht gefunden!');
      return;
    }

    final csvContent = await file.readAsString();
    print('✓ Datei geladen\n');

    // 2. CSV parsen
    print('🔍 Parse CSV-Daten...');
    final parseResult = CsvService.parseCoordinates(csvContent);
    print('✓ ${parseResult.values_1d.length} Messwerte erkannt');
    print('   Modus: ${parseResult.mode.description}\n');

    // 3. Prozessüberwachungs-Analyse durchführen
    print('⚙️  Führe Prozessüberwachungs-Analyse durch...');
    final result = ProcessMonitoringService.analyze1D(
      values: parseResult.values_1d,
    );
    print('✓ Analyse abgeschlossen\n');

    // 4. Ergebnisse anzeigen
    print(result.toFormattedString());
  } catch (e) {
    print('\n❌ Fehler bei der Analyse:');
    print('   $e');
    print(e.toString());
  }
}
