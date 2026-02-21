# MSA Type 1 Measurement System Analysis (AIAG Standard)

Vollständiges Dart-/Flutter-Programm zur **Messsystemanalyse Typ 1 (Variables)** nach dem AIAG-Standard (Automotive Industry Action Group).

## 📋 Überblick

Dieses Programm analysiert die Qualität eines Messsystems (z.B. Messschieber, Laser-Abstandsensor) anhand von Messdaten. Es bewertet, ob die **Messunsicherheit** klein genug im Vergleich zu Prozess-Variabilität ist.

### Wichtige Konzepte

**MSA Typ 1** konzentriert sich auf ein einzelnes Messinstrument ohne mehrere Prüfer:
- ✓ Ein Messinstrument / Sensor
- ✓ Ein Prüfer (oder automatisiert)
- ✓ Fokus: Wiederholbar (Repeatability)
- ✗ Kein Vergleich zwischen Prüfern

Die Analyse bewertet das System nach dem Kriterium **%Study Variation (%TV / GRR%)**:

| %TV | AIAG-Bewertung | Eignung |
|-----|---|---|
| < 10% | **Geeignet** | ✓ Akzeptiert |
| 10-30% | **Bedingt geeignet** | ⚠ Mit Vorsicht |
| > 30% | **Nicht geeignet** | ✗ Reject/Instandsetzen |

## 🏗️ Architektur

```
lib/
├── main.dart                      # Flutter UI & Demo
├── models/
│   ├── coordinate_point.dart      # Einzelner Messpunkt (x, y)
│   ├── measurement_data.dart      # Ein Messdatensatz (2 Punkte + berechnete Werte)
│   └── msa_result.dart            # MSA-Analyseergebnis mit Interpretation
└── services/
    ├── csv_service.dart           # CSV einlesen & validieren
    ├── calculation_service.dart    # Mathematische Berechnungen
    └── msa_type1_service.dart      # MSA-Typ-1-Analyse (Kernlogik)
```

### Service-Beschreibungen

#### 1. **CsvService**
- Liest CSV-Datei ein mit Format: `x1,y1,x2,y2`
- Validiert numerische Werte
- Nutzbarer Parser für Fehlerbehandlung
- **Exceptions**: `CsvException` mit Zeilennummern

```dart
final service = CsvService();
final data = service.parseCoordinates(csvContent);
final points = service.toCoordinatePoints(data);
```

#### 2. **CalculationService**
- **Euklidischer Abstand**: $d = \sqrt{(x_2-x_1)^2 + (y_2-y_1)^2}$
- **Mittelwert**: $\mu = \frac{\sum x}{n}$
- **Standardabweichung (Stichprobe)**: $\sigma = \sqrt{\frac{\sum(x-\mu)^2}{n-1}}$
- **Trend (Regression)**: Berechnet Steigung + $R^2$ für Stabilitätsprüfung
- **Bias**: $\text{Bias} = \mu - \text{Referenzwert}$

```dart
// Abstand zwischen zwei Punkten
final d = CalculationService.calculateEuclideanDistance(p1, p2);

// MeasurementData erstellen
final measurement = CalculationService.createMeasurement(
  id: 1,
  point1: p1,
  point2: p2,
);
```

#### 3. **MsaType1Service** (Kernlogik)
Führt vollständige MSA-Analyse durch:

1. **Grundstatistiken** aus Abstandsmessungen:
   - Mittelwert (μ), Standardabweichung (σ), Min, Max

2. **Wiederholbarkeit (Equipment Variation)**:
   - Nach AIAG: $\text{Repeatability} = \sigma$
   - Repräsentiert ±3σ der Normalverteilung

3. **Study Variation**:
   - $\text{6σ Study} = 6 \times \sigma$
   - Deckt 99.73% der Messwerte

4. **%Study Variation (%TV/GRR%)**:
   $$\text{%TV} = \frac{\text{6σ}}{\text{Toleranzbereich}} \times 100\%$$
   
   - Falls kein Toleranzbereich: nutze Spannweite (max - min)

5. **Bias-Berechnung** (optional):
   $$\text{Bias} = \mu - \text{Referenzwert}$$

6. **Stabilitätsprüfung** (für n > 10):
   - Lineare Regression über Zeit
   - Prüft auf Trend im System (Verschleiß?)

## 📊 Verwendungsbeispiel

### 1. CSV einlesen

```dart
final csv = '''x1,y1,x2,y2
10.05,20.01,15.05,23.02
10.12,20.08,15.13,23.09
...''';

final csvService = CsvService();
final parsed = csvService.parseCoordinates(csv);
final coordinates = csvService.toCoordinatePoints(parsed);
```

### 2. MeasurementData erstellen

```dart
final measurements = <MeasurementData>[];
for (int i = 0; i < coordinates.length; i++) {
  final pair = coordinates[i];
  final m = CalculationService.createMeasurement(
    id: i + 1,
    point1: pair.p1,
    point2: pair.p2,
    timestamp: DateTime.now(), // Optional
  );
  measurements.add(m);
}
```

### 3. MSA Analyse durchführen

```dart
final result = MsaType1Service.analyze(
  measurements: measurements,
  toleranceRange: 10.0,        // ±5 Einheiten = 10 total
  referenceValue: 5.831,       // Erwarteter Sollwert
  analyzeStability: true,      // Stabilitätsprüfung
);

print(result.toFormattedString());
```

### Beispielausgabe

```
╔════════════════════════════════════════════════╗
║     MSA TYP 1 - MESSSYSTEMANALYSE (AIAG)      ║
╚════════════════════════════════════════════════╝

📊 STATISTISCHE GRUNDLAGEN:
   Stichprobenumfang (n):     50
   Mittelwert (μ):            5.830625
   Standardabweichung (σ):    0.035891
   Minimum:                   5.744562
   Maximum:                   5.916538
   Spannweite (R):            0.171976

⚙️  MESSSYSTEMPARAMETER:
   Wiederholbarkeit (σ):      0.035891
   Study Variation (6σ):      0.215347
   Bias (Abweichung):         -0.000475
   %Study Variation (%TV):    2.15%

✓ AIAG-BEWERTUNG:
   Eignungsstufe:             ✓ GEEIGNET
   Interpretation:            Das Messsystem ist GEEIGNET...

📈 STABILITÄTSPRÜFUNG:
   Trend erkannt:             false
   Trendsteigung:             0.000001

╚════════════════════════════════════════════════╝
```

## 🧪 Unit-Tests

Führe alle Tests aus:

```bash
flutter test
```

Tests decken ab:
- ✓ Euklidische Abstandsberechnung (Pythagoras)
- ✓ CSV-Parsing und Validierung
- ✓ Statistische Berechnungen (μ, σ, min, max)
- ✓ Bias-Berechnung
- ✓ MSA-Analyse mit verschiedenen Szenarien
- ✓ Fehlerfallbehandlung

## ⚙️ Konfigurierbare Parameter

### In `MsaType1Service._evaluateSuitability()`

```dart
static const double _suitableBoundary = 0.10;    // 10% - Grenze
static const double _marginalBoundary = 0.30;    // 30% - Grenze
```

Diese können angepasst werden für:
- Strengere Anforderungen (z.B. 8% vs. 10%)
- Andere Branchen-Standards

### In `analyze()`

```dart
final result = MsaType1Service.analyze(
  measurements: measurements,
  toleranceRange: 10.0,        // ← Anpassen je nach Prozess
  referenceValue: 5.831,       // ← Sollwert setzen/null
  analyzeStability: true,      // ← Toggle für Trend-Analyse
);
```

## 🔄 Erweiterungsoptionen für Gage R&R

Um später **Gage R&R** (mehrere Prüfer, Wiederholungen) zu implementieren:

**Notwendige Änderungen:**

1. **MeasurementData erweitern**:
   ```dart
   class MeasurementData {
     int operatorId;     // ← Prüfer-ID
     int repeatNumber;   // ← Wiederholung 1, 2, 3
     ...
   }
   ```

2. **Neuer Service**: `GageRRService`
   - Berechne Varianz zwischen Prüfern
   - Prüfer × Teile Interaktionseffekt
   - ANOVA-Analysen

3. **Result-Klasse**: `GageRRResult`
   - Reproducibility (Unterschied zwischen Prüfern)
   - Ruhestellung Variation separat
   - Apparat × Teile Wechselwirkung

**Architekturvorteil:**
- `MeasurementData` bleibt modular
- `CsvService` kann mehrere Spalten handhaben
- `CalculationService` bietet Grundbasisfunktionen
- `GageRRService` nutzt diese ohne Duplikation

## 📝 CSV-Format

**Erforderliche Spalten**:
```
x1,y1,x2,y2
```

**Beispiel**:
```csv
x1,y1,x2,y2
10.05,20.01,15.05,23.02
10.12,20.08,15.13,23.09
10.03,19.95,15.04,22.98
```

- Keine Header außer der ersten Zeile
- Numerische Werte (Double)
- Komma-getrennt (kein Semikolon)
- Leere Zeilen werden ignoriert
- Dezimalzeichen: Punkt (1.5, nicht 1,5)

## 📚 Statistische Formeln im Code

| Formel | Funktion | AIAG-Standard |
|--------|----------|---|
| $d = \sqrt{(x_2-x_1)^2 + (y_2-y_1)^2}$ | `calculateEuclideanDistance()` | Geometrische Messung |
| $\mu = \frac{\sum x}{n}$ | `calculateMean()` | Zentralwert |
| $\sigma = \sqrt{\frac{\sum(x-\mu)^2}{n-1}}$ | `calculateStandardDeviation()` | Stichproben-StdDev (Bessel) |
| $\text{6σ}$ | `studyVariation` | AIAG: ±3σ Bereich |
| $\%\text{TV} = \frac{6\sigma}{\text{Tolerance}}$ | `percentStudyVariation` | **Hauptbewertungskriterium** |
| $\text{Bias} = \mu - \text{Ref}$ | `calculateBias()` | Systematischer Fehler |

## 🚀 Flutter UI

Die Flutter-App (`main.dart`) bietet:
- 📱 Demo-Daten generieren (100 Messungen)
- 📊 Analyse durchführen und Ergebnisse anzeigen
- 📥 Platzhalter für eigenständiges CSV-Upload (mit `file_picker` erweiterbar)
- 🔄 Analyse neu starten
- 📋 Gut lesbare, strukturierte Ausgabe

### Erweiterung für echte Datei-Uploads

```dart
// Installiere Package
// pubspec.yaml:
//   file_picker: ^5.0.0

import 'package:file_picker/file_picker.dart';

Future<void> _uploadCsvFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  
  if (result != null) {
    final path = result.files.single.path;
    final content = await File(path!).readAsString();
    // → csvService.parseCoordinates(content)
  }
}
```

## 🎯 Validierungslogik

**CSV-Validierung**:
- ✓ Header muss exakt sein: `x1,y1,x2,y2`
- ✓ Numerische Werte (Integer/Double)
- ✓ Keine NaN/Infinity
- ✓ Richtige Feldanzahl (4)

**Messdaten-Validierung**:
- ✓ Mindestens 1 Messung
- ✓ Alle Abstandswerte ≥ 0
- ✓ Toleranzbereich > 0 (falls angegeben)

**Fehlerbehandlung**:
```dart
try {
  final data = csvService.parseCoordinates(csvContent);
} on CsvException catch (e) {
  print('Fehler in Zeile ${e.lineNumber}: ${e.message}');
} catch (e) {
  print('Gesamt-Problem: $e');
}
```

## 📖 Literatur/Standards

- **AIAG** (Automotive Industry Action Group)
  - Measurement System Analysis (MSA)
  - GRR - Gage R&R Analyse

- **ISO 9001** - Qualitätsmanagementsysteme
- **VDA 5** - German automotive quality standard

## 🔧 Abhängigkeiten

**Runtime**:
- `flutter` (SDK)
- `dart` (≥3.0)

**Development**:
- `test` (Unit-Testing)
- `flutter_test` (Flutter Testing)

## 📄 Lizenz

Frei nutzbar für Qualitätsingenieur- und Entwicklungs-Projekte.

---

**Erstellt**: Februar 2026 | **Standard**: AIAG MSA Typ 1
