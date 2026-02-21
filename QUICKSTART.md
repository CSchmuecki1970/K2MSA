# MSA Analysis - Schnelleinstieg (Quick Start)

## 📦 Installation & Setup

### Voraussetzungen
- **Flutter SDK** ≥ 3.4 oder **Dart SDK** ≥ 3.0+
- **Compiler**: `dart` oder `flutter`
- Optional: **VS Code Extension** für Dart/Flutter

### Installation

#### 1. Flutter-App aufsetzen
```bash
cd c:\Programming\flutter_projects\MSA
flutter pub get
```

#### 2. Tests ausführen (validiere Installation)
```bash
flutter test
```

**Erwartete Ausgabe**:
```
✓ All tests passed! (42 tests in 3.2s)
```

## 🚀 Schnellstart CLI (Commandline)

### Beispiel: Datei analysieren
```bash
# Mit Standard-Spannweite als Toleranz
dart bin/msa_cli.dart example_data.csv

# Mit Toleranzbereich (±5 = 10 total)
dart bin/msa_cli.dart example_data.csv --tolerance=10.0

# Mit Referenz-Sollwert
dart bin/msa_cli.dart example_data.csv --tolerance=10.0 --reference=5.831

# Alles zusammen
dart bin/msa_cli.dart example_data.csv \
  --tolerance=10.0 \
  --reference=5.831
```

### Output-Beispiel
```
📂 Lese CSV-Datei: example_data.csv
📖 Parse CSV-Daten...
✓ 50 Datensätze erfolgreich gelesen

📐 Berechne Abstände...
✓ 50 Abstände berechnet

⚙️  Führe MSA Typ 1 Analyse durch...

╔════════════════════════════════════════════════╗
║     MSA TYP 1 - MESSSYSTEMANALYSE (AIAG)      ║
╚════════════════════════════════════════════════╝

📊 STATISTISCHE GRUNDLAGEN:
   Stichprobenumfang (n):     50
   Mittelwert (μ):            5.830625
   Standardabweichung (σ):    0.035891
   ...

✓ AIAG-BEWERTUNG:
   Eignungsstufe:             ✓ GEEIGNET
   ...
```

## 🎨 Flutter App starten

### Start-Befehlszeile
```bash
flutter run
```

### Device auswählen (falls mehrere)
```bash
flutter devices
flutter run -d <device-id>
```

### Features der App
- ✓ Demo-Beispiel (100 Messungen generieren)
- ✓ Analyse durchführen & Ergebnisse anzeigen
- ✓ Neue Analyse starten
- ✓ Strukturierte Ausgabe

## 📋 Eigene CSV-Datei erstellen

**Format** (CSV mit Kommata):
```
x1,y1,x2,y2
10.05,20.01,15.05,23.02
10.12,20.08,15.13,23.09
10.03,19.95,15.04,22.98
...
```

**Via Excel/Calc**:
1. Öffne Excel/LibreOffice
2. Spalten: A=x1, B=y1, C=x2, D=y2
3. Gib Daten ein
4. Speichere als CSV (UTF-8)

**Platzhalter Daten** (zum Testen):
```csv
x1,y1,x2,y2
0.0,0.0,3.0,4.0
0.5,0.2,3.5,4.3
-1.0,1.0,2.0,5.0
```

## 🔍 Programmverwendung im Code

### Minimal Beispiel
```dart
import 'package:msa_analysis/services/csv_service.dart';
import 'package:msa_analysis/services/calculation_service.dart';
import 'package:msa_analysis/services/msa_type1_service.dart';

void main() {
  // CSV einlesen
  const csv = '''x1,y1,x2,y2
10.0,20.0,15.0,23.0
10.1,20.1,15.1,23.1''';
  
  final csvService = CsvService();
  final data = csvService.parseCoordinates(csv);
  final points = csvService.toCoordinatePoints(data);
  
  // Messungen erstellen
  final measurements = points.asMap().entries.map((e) {
    return CalculationService.createMeasurement(
      id: e.key + 1,
      point1: e.value.p1,
      point2: e.value.p2,
    );
  }).toList();
  
  // Analyse
  final result = MsaType1Service.analyze(
    measurements: measurements,
    toleranceRange: 10.0,
  );
  
  print(result.toFormattedString());
}
```

### Mit Fehlerbehandlung
```dart
try {
  final data = csvService.parseCoordinates(csvContent);
  // ...
} on CsvException catch (e) {
  print('❌ CSV-Fehler (Zeile ${e.lineNumber}): ${e.message}');
} catch (error) {
  print('❌ Fehler: $error');
}
```

## ⚙️ Konfiguration anpassen

### 1. AIAG-Grenzen ändern
Datei: `lib/services/msa_type1_service.dart`

```dart
class MsaType1Service {
  // Ändern Sie diese:
  static const double _suitableBoundary = 0.10;    // 10%
  static const double _marginalBoundary = 0.30;    // 30%
}
```

**Beispiel**: Für strengere Anforderungen (8% Grenze):
```dart
static const double _suitableBoundary = 0.08;     // 8% statt 10%
```

### 2. CSV-Format-Validierung
Datei: `lib/services/csv_service.dart`

```dart
class CsvService {
  static const String _expectedHeader = 'x1,y1,x2,y2';  // ← ändern
  static const int _requiredFields = 4;                 // ← ändern
}
```

### 3. Stabilitäts-Prüfschwelle
Datei: `lib/services/msa_type1_service.dart`
```dart
if (analyzeStability && measurements.length > 10) {  // ← ändern
  // ...
  stabilityCheck = {
    'hasTrend': trendData['r_squared']! > 0.3,      // ← R²-Schwelle
  };
}
```

## 📚 Wichtiges Wissen

### AIAG Bewertungskriterium
- **%TV = (6σ Messsystem) / (Toleranzbereich) × 100%**
- < 10% = ✓ Geeignet
- 10-30% = ⚠ Bedingt
- \> 30% = ✗ Nicht geeignet

### Häufige Fehler & Lösungen

| Problem | Ursache | Lösung |
|---------|---------|--------|
| `CsvException: Header nicht erkannt` | CSV-Header falsch | Header exakt `x1,y1,x2,y2` |
| `CsvException: Nicht-numerisch` | Text in Datenzeilen | Nur Zahlen (z.B. 1.5, -3.0) |
| Zu hohe %TV (>30%) | Messsystem zu ungenau | Kalibrieren/reparieren |
| Stabilitätswarte: `hasTrend: true` | Messdrift über Zeit | Kalibration überprüfen |
| `Bias` großer Wert | Systematischer Fehler | Nullpunkt/Offset-Fehler |

## 🧪 Tests ausführen

### Alle Tests
```bash
flutter test
```

### Einzelne Test-Datei
```bash
flutter test test/calculation_service_test.dart
```

### Mit Coverage
```bash
flutter test --coverage
# Report: coverage/lcov.info
```

## 📊 Ausgabeformate

### Konsole (formatiert)
```dart
print(result.toFormattedString());
```

### JSON (für weitere Verarbeitung)
```dart
print(jsonEncode(result.toJson()));
```

Output Beispiel:
```json
{
  "mean": 5.830625,
  "standardDeviation": 0.035891,
  "min": 5.744562,
  "max": 5.916538,
  "sampleCount": 50,
  "repeatability": 0.035891,
  "bias": -0.000475,
  "studyVariation": 0.215347,
  "percentStudyVariation": 0.02154,
  "suitability": "MsaSuitability.suitable",
  "interpretation": "Das Messsystem ist GEEIGNET..."
}
```

### Speichern in Datei
```bash
dart bin/msa_cli.dart data.csv > results.txt
# oder automatisch via CLI (→ results_msa_results.json)
```

## 🔗 Nächste Schritte

### Fortgeschrittene Nutzung
1. **Mehrere CSV-Dateien vergleichen** → Loop über Files
2. **Dashboard erstellen** → Flutter Charts + Table-Widget
3. **Gage R&R erweitern** → Multiple Operator-Support
4. **Backend-Integration** → REST-API oder Firebase

### Erweiterungen
```dart
// In Planung:
class GaugeRRService { ... }           // Gage R&R Analyse
class MsaChartGenerator { ... }        // Graphische Ausgabe
class MsaRepository { ... }            // Persistierung (DB)
```

## 📞 Support

### Häufige Fragen

**F: Kann ich andere Toleranz-Werte nutzen?**  
A: Ja! `--tolerance=5.5` oder im Code:
```dart
final result = MsaType1Service.analyze(
  measurements: measurements,
  toleranceRange: 5.5,  // ← Ihre Toleranz
);
```

**F: Was ist der Unterschied zwischen Toleranzbereich und Spannweite?**  
A:
- **Toleranzbereich**: Vorgegeben (z.B. ±5 = 10 total)
- **Spannweite**: (max - min) der Daten selbst
- Wenn kein Toleranzbereich → nutzt Spannweite

**F: Was tun bei zu hoher %TV?**  
A: Messsystem überprüfen:
1. Kalibrierung überprüfen
2. Mechanische Verschleißteile prüfen
3. Messprozess optimieren
4. Neues Messinstrument erwägen

**F: Brauche ich 50 Messungen mindestens?**  
A: AIAG empfiehlt:
- Minimum: 10-20 für schnelle Tests
- Standard: 30-50 für zuverlässige Ergebnisse
- Robust: 100+ für genaue Stabilitätsprüfung

---

**Viel Erfolg mit Ihrer MSA-Analyse! 🎯**
