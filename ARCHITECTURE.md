# MSA Type 1 - Technische Dokumentation & Architektur

## 1. Gesamtarchitektur

```
┌─────────────────────────────────────────────────────┐
│                   UI Layer (Flutter)
│              main.dart - MsaAnalysisApp
├─────────────────────────────────────────────────────┤
│              Business Logic Layer
│  ┌──────────────┐     ┌──────────────────────────┐
│  │  CsvService  │────▶│ CalculationService       │
│  │              │     │  - euclideanDistance()   │
│  │ - parseCoord()     │  - calculateMean()       │
│  │ - validate()       │  - calculateStdDev()     │
│  │ - toPoints()       │  - calculateTrend()      │
│  └──────────────┘     └──────────────────────────┘
├──────────────────────┬──────────────────────────────┤
│  MsaType1Service     │  Result Models
│  ┌────────────────┐  │  ┌──────────────────┐
│  │ - analyze()    │  │  │ MsaType1Result   │
│  │ - _evaluate... │  │  │ MsaSuitability   │
│  │ - _interpret...│  │  │ MeasurementData  │
│  └────────────────┘  │  │ CoordinatePoint  │
│                      │  └──────────────────┘
└──────────────────────┴──────────────────────────────┘
```

## 2. Data Flow

```
CSV-String
   ↓
[CsvService.parseCoordinates()]
   ↓
List<Map<string, double>>  (x1, y1, x2, y2)
   ↓
[CsvService.toCoordinatePoints()]
   ↓
List<(CoordinatePoint p1, CoordinatePoint p2)>
   ↓
[For-Loop] + [CalculationService.createMeasurement()]
   ↓
List<MeasurementData>  (mit berechneten Abständen)
   ↓
[MsaType1Service.analyze()]
   ↓
MsaType1Result  (Statistiken, %TV, Bewertung)
   ↓
UI / JSON Export
```

## 3. Service-Verantwortlichkeiten (Single Responsibility)

### CsvService
**Verantwortung**: CSV-Ein-/Ausgabe und Validierung
- ✓ Zeilenparsing
- ✓ Feldvalidierung
- ✓ Fehlerreprtierung mit Zeilennummern
- ✗ Mathematik
- ✗ MSA-Logik

```dart
class CsvService {
  List<Map<String, double>> parseCoordinates(String csvContent);
  List<(CoordinatePoint p1, CoordinatePoint p2)> toCoordinatePoints(...);
}
```

### CalculationService
**Verantwortung**: Mathematische Grundfunktionen
- ✓ Euklidischer Abstand
- ✓ Statistische Metriken (μ, σ, min, max)
- ✓ Bias-Berechnung
- ✓ Trend-Analyse (Regression)
- ✓ MeasurementData-Fabrik
- ✗ AIAG-Bewertungslogik
- ✗ Interpretationen

```dart
class CalculationService {
  static double calculateEuclideanDistance(...);
  static double calculateMean(List<double> values);
  static double calculateStandardDeviation(List<double> values);
  static double calculateBias(List<double> values, double? ref);
  static Map<String, double> calculateTrend(List<MeasurementData> measurements);
  static MeasurementData createMeasurement(...);
}
```

### MsaType1Service
**Verantwortung**: MSA-Typ-1-Geschäftslogik
- ✓ Daten-Orchestrierung
- ✓ AIAG-Grenzbewertung
- ✓ Stabilität-Prüfung
- ✓ Textuelle Interpretationen
- ✗ CSV-Parsing
- ✗ Elementare Mathematik

```dart
class MsaType1Service {
  static MsaType1Result analyze({
    required List<MeasurementData> measurements,
    double? toleranceRange,
    double? referenceValue,
    bool analyzeStability = true,
  });
  
  static MsaSuitability _evaluateSuitability(double percentStudyVariation);
  static String _interpretSuitability(...);
}
```

## 4. Datenmodelle (Models)

### CoordinatePoint
Minimal, unveränderlich (immutable):
```dart
class CoordinatePoint {
  final double x;
  final double y;
  // + toString() für Debug
}
```

**Warum**: Geometrie-primitive, keine Mutations-Logik nötig

### MeasurementData
Kombiniert Eingabe + berechnete Werte:
```dart
class MeasurementData {
  final int id;                    // Messungs-Index
  final CoordinatePoint point1;   // Eingang
  final CoordinatePoint point2;   // Eingang
  final double distance;           // Berechnet: √((x2-x1)²+(y2-y1)²)
  final double deltaX;             // Berechnet: x2 - x1
  final double deltaY;             // Berechnet: y2 - y1
  final DateTime? timestamp;       // Optional: für Stabilitätsprüfung
}
```

**Design**: 
- Unveränderlich nach Erstellung
- Alle relevanten Infos in einem Objekt
- Zeitstempel optional (Erweiterbarkeit)

### MsaType1Result
Umfassendes Ergebnisobjekt:
```dart
class MsaType1Result {
  // Statistik
  double mean, standardDeviation, min, max;
  int sampleCount;
  
  // MSA-Parameter
  double repeatability;              // σ
  double? bias;                      // μ - Referenz
  double studyVariation;             // 6σ
  double percentStudyVariation;      // 6σ / Toleranz
  
  // Bewertung
  MsaSuitability suitability;
  String interpretation;
  
  // Optional
  Map<String, dynamic>? stabilityCheck;
  
  // Ausgabe
  String toFormattedString();
  Map<String, dynamic> toJson();
}

enum MsaSuitability { suitable, marginal, notSuitable }
```

**Features**:
- Zentrale Datenstruktur für Ergebnis + Ausgabe
- `toFormattedString()` für lesbare Konsolenausgabe
- `toJson()` für Weiterverarbeitung / Persistierung

## 5. Fehlerbehandlung

### CsvException
Spezifische, informative Exceptions:
```dart
class CsvException {
  final String message;
  final int? lineNumber;
  
  // Nutzbarer toString()
}
```

**Beispiel**:
```
CsvException (Zeile 15): Nicht-numerischer Wert gefunden: "abc", 'def', '1.5', '2.0'
```

### Validierungskette
```
CSV-String
└─ Header-Check
   ├─ Format-Check
   ├─ Feldanzahl-Check
   ├─ Numerische Validierung
   ├─ NaN/Infinity-Check
   └─ → CsvException if fail
```

## 6. Statistische Formeln (mit Implementierungen)

### 6.1 Euklidischer Abstand
**Formel**:
$$d = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2}$$

**Code**:
```dart
static double calculateEuclideanDistance(CoordinatePoint p1, CoordinatePoint p2) {
  final deltaX = p2.x - p1.x;
  final deltaY = p2.y - p1.y;
  return sqrt(deltaX * deltaX + deltaY * deltaY);
}
```

**Warum Pythagoras**: Geometrische Distanz zwischen zwei Punkten

### 6.2 Mittelwert (Arithmetic Mean)
**Formel**:
$$\mu = \frac{1}{n} \sum_{i=1}^{n} x_i$$

**Code**:
```dart
static double calculateMean(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((a, b) => a + b) / values.length;
}
```

### 6.3 Standardabweichung (Sample StdDev)
**Formel** (Stichprobe mit Bessel-Korrektur):
$$\sigma = \sqrt{\frac{\sum_{i=1}^{n} (x_i - \mu)^2}{n - 1}}$$

**Code**:
```dart
static double calculateStandardDeviation(List<double> values) {
  if (values.length < 2) return 0.0;
  final mean = calculateMean(values);
  final sumSquaredDiff = values.fold<double>(
    0.0,
    (sum, value) => sum + pow(value - mean, 2),
  );
  return sqrt(sumSquaredDiff / (values.length - 1));  // ← (n-1) nicht n
}
```

**WICHTIG**: (n-1) Freiheitsgrade für **unverzerrte Schätzung** (Standard AIAG)

### 6.4 Study Variation (6-Sigma-Bereich)
**Formel**:
$$\text{Study Variation} = 6 \times \sigma$$

**Interpretation**:
- Deckt ±3σ ab (99.73% der Normalverteilung)
- AIAG-Standard für Messunsicherheit
- Repräsentiert wahrscheinlichen Bereich der Messgeräte-Fehler

**Code**:
```dart
final studyVariation = 6 * repeatability;
```

### 6.5 %Study Variation (%GRR / %TV)
**Formel** (mit Toleranzbereich):
$$\text{%TV} = \frac{\text{Study Variation}}{\text{Toleranz}} \times 100\%$$

**Alternativ** (mit Spannweite bei keinen bekannten Toleranzen):
$$\text{%TV} = \frac{6\sigma}{\text{Max} - \text{Min}} \times 100\%$$

**Code**:
```dart
final effective_tolerance = toleranceRange ?? (max - min);
final percentStudyVariation = studyVariation / effective_tolerance;
```

**Interpretation**:
- < 10%: Gut (± geringe Messunsicherheit)
- 10-30%: Akzeptabel mit Vorsicht
- > 30%: Unbrauchbar (Messsystem kalibrieren/reparieren)

### 6.6 Bias (Systematischer Fehler)
**Formel**:
$$\text{Bias} = \mu_{\text{gemessen}} - \text{Referenzwert}$$

**Code**:
```dart
static double? calculateBias(List<double> values, double? referenceValue) {
  if (referenceValue == null || values.isEmpty) return null;
  return calculateMean(values) - referenceValue;
}
```

**Interpretation**:
- Bias ≈ 0: System hat keinen systematischen Fehler
- Bias > 0: System misst konsistent zu hoch
- Bias < 0: System misst konsistent zu niedrig

### 6.7 Läneare Regression (Trend-Analyse)
**Ziel**: Prüfe auf Messsystem-Drift über Zeit

**Formeln**: (Least Squares)
$$\text{Slope} = \frac{n \sum x_i y_i - \sum x_i \sum y_i}{n \sum x_i^2 - (\sum x_i)^2}$$

$$R^2 = \left(\frac{n \sum x_i y_i - \sum x_i \sum y_i}{\sqrt{(n \sum x_i^2 - (\sum x_i)^2)(n \sum y_i^2 - (\sum y_i)^2)}}\right)^2$$

**Code**:
```dart
static Map<String, double> calculateTrend(List<MeasurementData> measurements) {
  // X = Index (0, 1, 2, ...)
  // Y = Messwert (distance)
  final n = measurements.length.toDouble();
  late double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;
  
  for (int i = 0; i < measurements.length; i++) {
    final x = i.toDouble();
    final y = measurements[i].distance;
    sumX += x;
    sumY += y;
    sumXY += x * y;
    sumX2 += x * x;
    sumY2 += y * y;
  }
  
  final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  final rValue = numerator / denominator;
  final rSquared = rValue * rValue;
  
  return {'slope': slope, 'r_squared': rSquared};
}
```

**Interpretation**:
- **Slope > 0**: Messwerte steigen → Verschleiß/Kalibrierungsdrift
- **Slope < 0**: Messwerte sinken → Temperatur-/Verschleiß-Einfluss
- **R² > 0.3**: Trend signifikant (Warnung ausgebungs)
- **R² < 0.1**: Kaum Trend, System stabil

## 7. AIAG-Bewertungslogik

```dart
static MsaSuitability _evaluateSuitability(double percentStudyVariation) {
  if (percentStudyVariation < 0.10) {
    return MsaSuitability.suitable;          // < 10%
  } else if (percentStudyVariation <= 0.30) {
    return MsaSuitability.marginal;          // 10-30%
  } else {
    return MsaSuitability.notSuitable;       // > 30%
  }
}
```

**Tabelle**:

| %TV | Eignungsgrad | Aktion |
|-----|---|---|
| 0-10% | ✓ **Geeignet** | Akzeptieren & nutzen |
| 10-30% | ⚠ **Bedingt** | Mit Vorsicht; überwachen |
| >30% | ✗ **Ungeeignet** | Ablehnen; kalibrieren/reparieren |

## 8. Stabilitätsprüfung

**Triggerbedingung**: n > 10 Messungen

**Durchführung**: Lineare Regression über Zeit

**Bewertungskriterium**:
```dart
stabilityCheck = {
  'hasTrend': trend['r_squared']! > 0.3,    // R² > 30% = Trend signifikant
  'trendSlope': trend['slope'],              // Steigung (Drift pro Messung)
  'r_squared': trend['r_squared'],
  'sampleCount': measurements.length,
};
```

**Interpretation Ausgabe**:
```
Trend erkannt: true/false
Trendsteigung: 0.00123  (→ Drift um 0.00123 pro Messung)
```

## 9. Erweiterungspunkte für Gage R&R

Aktuelle Architektur ermöglicht Gage R&R:

### Level 1: Datenmodell-Erweiterung
```dart
// Neue Felder in MeasurementData
class MeasurementData {
  int operatorId;        // Prüfer-Information
  int repeatNumber;      // Wiederholung 1, 2, 3, ...
  int partId;            // Prüfstück
  // ... rest unverändert
}
```

### Level 2: CSV-Format erweitern
```
operatorId,partId,repeatNumber,x1,y1,x2,y2
1,1,1,10.05,20.01,15.05,23.02
1,1,2,10.06,20.02,15.06,23.01
1,1,3,10.04,20.00,15.04,23.00
2,1,1,10.07,20.08,15.07,23.08
2,1,2,10.05,20.06,15.05,23.07
...
```

### Level 3: GageRRService erstellen
```dart
class GageRRService {
  /// Führe Gage R&R nach AIAG durch
  /// - Repeatability: Varianz innerhalb Prüfer
  /// - Reproducibility: Varianz zwischen Prüfern
  /// - Apparat × Teile Wechselwirkung
  /// - ANOVA oder traditionelle Methode
  static GageRRResult analyzeGaugeRR({
    required List<MeasurementData> measurements,
    // ... weitere Optionen
  });
}
```

### Level 4: Result-Klasse
```dart
class GageRRResult {
  double repeatability;      // σ_apparat (innerhalb)
  double reproducibility;    // σ_prüfer (zwischen)
  double totalSystemVariation;
  double partToPartVariation;
  
  double percentRepeatability;
  double percentReproducibility;
  double percentGRR;
  
  // Bonus: ANOVA Ergebnisse falls gewünscht
  // ...
}
```

**Vorteil bestehendem Design**:
- `CalculationService` enthält bereits Grund-Statistiken
- `MeasurementData` kann erweitert werden ohne API-Breaking
- CSV-Validierung gut gekapselt
- Keine Duplizierung = wartbar

## 10. Code-Style & Best Practices

### Dart Idioms
- ✓ Final-Keyword für unveränderliche Variablen
- ✓ Late-Keyword für deferred initialization
- ✓ Null-safety abgesichert
- ✓ Pattern matching für Enums (switch)

### Dokumentation
- ✓ Triple-Slash `///` für public API
- ✓ Formel-Erklärungen in Kommentaren
- ✓ Parameter-Beschreibungen
- ✓ Fallbeispiele wo komplex

### Testing
- ✓ Unit-Tests für alle Services
- ✓ Edge-Cases (leere Listen, NaN, etc.)
- ✓ Exception-Path-Testing
- ✓ Näherungsmessungen mit `closeTo()` für Floats

### Performance
- ✓ Keine Unnecessary-Objekt-Allokationen
- ✓ Reduce/fold statt mehrfache Iterationen
- ✓ Sqrt/Pow nur wenn nötig

## 11. Deployment-Optionen

### Option A: Reine Dart CLI
```bash
dart pub global activate msa_analysis
msa_cli data.csv --tolerance=10.0
```

### Option B: Flutter App (Mobil/Desktop)
```bash
flutter run -d <device>
# Oder Build für Distribution
flutter build apk / ios / windows / etc.
```

### Option C: Web-App
```bash
flutter web
# oder
flutter build web
# Dann auf Webserver deployen
```

### Option D: Library-Integration
```dart
// pubspec.yaml
dependencies:
  msa_analysis: ^1.0.0

// Code
import 'package:msa_analysis/services/msa_type1_service.dart';
```

---

**Fazit**: Saubere Architektur mit klaren Verantwortlichkeiten ermöglicht Wartung, Testing und Erweiterung. AIAG-konform und produktionsreif.
