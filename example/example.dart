/// Vollständiges Beispiel zur Verwendung der MSA Analysis Library
///
/// Dieses Beispiel demonstriert:
/// 1. CSV-Datei laden
/// 2. MeasurementData erstellen
/// 3. MSA-Analyse durchführen
/// 4. Ergebnisse interpretieren

import 'package:msa_analysis/services/csv_service.dart';
import 'package:msa_analysis/services/calculation_service.dart';
import 'package:msa_analysis/services/msa_type1_service.dart';
import 'package:msa_analysis/models/msa_result.dart';

void main() {
  print('═══════════════════════════════════════════════════════════');
  print('     MSA Type 1 Analysis - Vollständiges Beispiel');
  print('═══════════════════════════════════════════════════════════\n');

  // ═══════════════════════════════════════════════════════════════
  // SCHRITT 1: Sample CSV-Daten (In Praxis: aus Datei)
  // ═══════════════════════════════════════════════════════════════
  const sampleCsvData = '''x1,y1,x2,y2
10.05,20.01,15.05,23.02
10.12,20.08,15.13,23.09
10.03,19.95,15.04,22.98
10.08,20.05,15.08,23.04
10.02,20.02,15.03,23.01
10.07,20.09,15.07,23.10
10.04,20.03,15.05,23.02
10.06,20.07,15.06,23.08
10.01,19.98,15.02,22.99
10.09,20.06,15.09,23.05
10.05,20.04,15.06,23.03
10.08,20.02,15.08,23.01
10.03,20.08,15.04,23.09
10.07,19.99,15.07,22.98
10.02,20.05,15.03,23.04
10.06,20.03,15.07,23.02
10.04,20.07,15.04,23.08
10.09,20.01,15.10,23.00
10.01,20.06,15.02,23.07
10.05,20.04,15.05,23.03
10.08,20.08,15.09,23.09
10.03,20.02,15.03,23.01
10.07,20.05,15.08,23.04
10.02,19.99,15.03,22.98
10.06,20.09,15.06,23.10
10.04,20.03,15.05,23.02
10.09,20.06,15.09,23.07
10.01,20.01,15.02,23.00
10.05,20.07,15.05,23.08
10.08,20.04,15.08,23.03''';

  print('📊 SCHRITT 1: CSV-Daten laden');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  try {
    // CSV Parsing mit Fehlerbehandlung
    final csvService = CsvService();
    final parsedData = csvService.parseCoordinates(sampleCsvData);
    final coordinatePairs = csvService.toCoordinatePoints(parsedData);

    print('✓ ${parsedData.length} Datensätze erfolgreich geparst');
    print('✓ ${coordinatePairs.length} Koordinaten-Paare erstellt\n');

    // ═══════════════════════════════════════════════════════════════
    // SCHRITT 2: MeasurementData erstellen
    // ═══════════════════════════════════════════════════════════════
    print('📐 SCHRITT 2: Berechne euklidische Abstände');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final measurements = <MeasurementData>[];
    for (int i = 0; i < coordinatePairs.length; i++) {
      final pair = coordinatePairs[i];
      final measurement = CalculationService.createMeasurement(
        id: i + 1,
        point1: pair.p1,
        point2: pair.p2,
        timestamp: DateTime.now()
            .subtract(Duration(minutes: coordinatePairs.length - i)),
      );
      measurements.add(measurement);
    }

    print('✓ ${measurements.length} Abstandswerte berechnet');
    print('\n  Einige Beispiele:');
    for (int i = 0; i < 3.clamp(0, measurements.length); i++) {
      final m = measurements[i];
      print('    ID ${m.id}: d=${m.distance.toStringAsFixed(6)}, '
          'Δx=${m.deltaX.toStringAsFixed(4)}, Δy=${m.deltaY.toStringAsFixed(4)}');
    }
    print();

    // ═══════════════════════════════════════════════════════════════
    // SCHRITT 3: MSA Typ 1 Analyse durchführen
    // ═══════════════════════════════════════════════════════════════
    print('⚙️  SCHRITT 3: Führe MSA Typ 1 Analyse durch');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final result = MsaType1Service.analyze(
      measurements: measurements,
      toleranceRange: 10.0, // ±5 Einheiten
      referenceValue: 5.831, // Erwarteter Sollwert (sqrt(5^2 + 3^2))
      analyzeStability: true,
    );

    print('✓ Analyse abgeschlossen\n');

    // ═══════════════════════════════════════════════════════════════
    // SCHRITT 4: Ergebnisse anzeigen
    // ═══════════════════════════════════════════════════════════════
    print(result.toFormattedString());

    // ═══════════════════════════════════════════════════════════════
    // SCHRITT 5: Ergebnisse programmgesteuert nutzen
    // ═══════════════════════════════════════════════════════════════
    print('\n📋 SCHRITT 5: Programmgesteuerte Auswertung');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Direkter Zugriff auf Kennwerte
    print('\nStatistische Kennwerte:');
    print('  Stichprobenumfang:      ${result.sampleCount}');
    print('  Mittelwert (μ):         ${result.mean.toStringAsFixed(6)}');
    print(
        '  Standardabweichung (σ): ${result.standardDeviation.toStringAsFixed(6)}');
    print(
        '  Min-Max-Spannweite:     ${(result.max - result.min).toStringAsFixed(6)}');

    print('\nMSA-Kennwerte:');
    print(
        '  Wiederholbarkeit:       ${result.repeatability.toStringAsFixed(6)}');
    print(
        '  Study Variation (6σ):   ${result.studyVariation.toStringAsFixed(6)}');
    print(
        '  %Study Variation:       ${(result.percentStudyVariation * 100).toStringAsFixed(2)}%');
    if (result.bias != null) {
      print('  Bias:                   ${result.bias!.toStringAsFixed(6)}');
    }

    print('\nBewertung:');
    print(
        '  Suitability:            ${result.suitability.toString().replaceAll('MsaSuitability.', '')}');
    print('  Status: ${_getStatusEmoji(result.suitability)} '
        '${_getStatusText(result.suitability)}');

    // ═══════════════════════════════════════════════════════════════
    // SCHRITT 6: Fallspezifische Entscheidungen
    // ═══════════════════════════════════════════════════════════════
    print('\n\n🎯 SCHRITT 6: Empfehlungen & Maßnahmen');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _provideRecommendations(result);

    // ═══════════════════════════════════════════════════════════════
    // SCHRITT 7: JSON Export (für weitere Verarbeitung)
    // ═══════════════════════════════════════════════════════════════
    print('\n\n💾 SCHRITT 7: Datenexport');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final jsonData = result.toJson();
    print('\nJSON-Daten für Datenbank/API:');
    _prettyPrintJson(jsonData);
  } catch (e) {
    print('❌ Fehler: $e');
  }

  print('\n═══════════════════════════════════════════════════════════');
  print('                  Analyse abgeschlossen');
  print('═══════════════════════════════════════════════════════════');
}

String _getStatusEmoji(MsaSuitability suitability) {
  return switch (suitability) {
    MsaSuitability.suitable => '✓',
    MsaSuitability.marginal => '⚠',
    MsaSuitability.notSuitable => '✗',
  };
}

String _getStatusText(MsaSuitability suitability) {
  return switch (suitability) {
    MsaSuitability.suitable => 'Messsystem ist GEEIGNET',
    MsaSuitability.marginal => 'Messsystem ist BEDINGT GEEIGNET',
    MsaSuitability.notSuitable => 'Messsystem ist NICHT GEEIGNET',
  };
}

void _provideRecommendations(MsaType1Result result) {
  switch (result.suitability) {
    case MsaSuitability.suitable:
      print('\n✓ Das Messsystem erfüllt die AIAG-Anforderungen.');
      print('  Empfehlungen:');
      print('    • Reguläre Wartung durchführen');
      print('    • Jährliche Recertifizierung durchführen');
      print('    • Für kritische Anwendungen: 6-monatliche Checks');

    case MsaSuitability.marginal:
      print('\n⚠ Das Messsystem ist bedingt geeignet.');
      print('  Empfehlungen:');
      print('    • Erhöhte Überwachung erforderlich');
      print('    • Regelmäßige Stabilitätsprüfung durchführen');
      print('    • Mit Vorsicht für kritische Entscheidungen nutzen');
      print('    • Reparatur/Optimierung erwägen');
      if (result.stabilityCheck != null &&
          result.stabilityCheck!['hasTrend'] == true) {
        print(
            '    • ⚠ WARNUNG: Trend erkannt! Sofortige Kalibrierung empfohlen.');
      }

    case MsaSuitability.notSuitable:
      print('\n✗ Das Messsystem ist NICHT GEEIGNET.');
      print('  Erforderliche Maßnahmen:');
      print('    1. Sofortiges Kalibrieren und/oder Reparieren');
      print('    2. Verschleißteile überprüfen und ggf. austauschen');
      print('    3. Prozess überprüfen (z.B. zu hohe Umgebungstemperatur)');
      print('    4. Bei Bedarf: Neues Messinstrument erwerben');
      print('    5. Nach Reparatur: Neuen MSA durchführen');
  }

  // Bias-Hinweis
  if (result.bias != null && result.bias!.abs() > 0.05) {
    print(
        '\n⚠ WARNUNG: Signifikanter Bias (${result.bias!.toStringAsFixed(4)})');
    print('  Bedeutung: Das Messsystem hat einen systematischen Fehler.');
    print('  Aktion: Nullpunkt- oder Offset-Kalibrierung überprüfen.');
  }
}

void _prettyPrintJson(Map<String, dynamic> json, {int indent = 0}) {
  final indentStr = '  ' * indent;
  json.forEach((key, value) {
    if (value is Map) {
      print('$indentStr"$key": {');
      _prettyPrintJson(value as Map<String, dynamic>, indent: indent + 1);
      print('$indentStr}');
    } else if (value is num) {
      final formatted = value is double ? value.toStringAsFixed(6) : value;
      print('$indentStr"$key": $formatted');
    } else {
      print('$indentStr"$key": "$value"');
    }
  });
}
