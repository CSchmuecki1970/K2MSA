# 📖 Dokumentations-Index

Schnelle Übersicht, welches Dokument für welche Verwendung geeignet ist.

## 🎯 Nach Bedarf

### **Ich möchte jetzt gleich starten**
→ Lese [QUICKSTART.md](QUICKSTART.md) (5 min)
- CLI-Befehle zum sofort Ausprobieren
- Flutter-App starten
- Eigene CSV-Datei laden

### **Ich möchte verstehen, wie es funktioniert**
→ Lese [README.md](README.md) (15 min)
- MSA-Typ-1-Konzepte erklärt
- Service-Beschreibungen
- Beispiele mit Code
- Statistik-Formeln

### **Ich möchte die Architektur verstehen**
→ Lese [ARCHITECTURE.md](ARCHITECTURE.md) (20 min)
- Detailliertes Design
- Datenfluss
- Mathematische Herleitungen
- Gage-R&R-Roadmap

### **Ich möchte Fehler beheben/konfigurieren**
→ Siehe [QUICKSTART.md - Fehlerbehandlung](QUICKSTART.md#fehlerfallbehandlung)
- Häufige Fehler
- Lösungen
- Debug-Tips

### **Ich möchte Code schreiben / Beispiel sehen**
→ Öffne [example/example.dart](example/example.dart)
- Vollständiges, gestaffeltes Beispiel
- Alle 7 Schritte erklärt
- Mit Fehlerbehandlung

### **Ich möchte Tests schreiben**
→ Öffne [test/calculation_service_test.dart](test/calculation_service_test.dart)
- 42 Unit-Test-Beispiele
- Edge-Cases
- Best-Practices

---

## 📚 Dokument-Übersicht

### [README.md](README.md) - Hauptdokumentation
**Länge:** ~15 Minuten Lesezeit  
**Inhalt:**
- ✓ MSA-Typ-1-Konzepte
- ✓ Service-Architektur
- ✓ Verwendungsbeispiele
- ✓ Statistische Formeln
- ✓ CSV-Format
- ✓ Konfiguration
- ✓ Erweiterungen
- ✓ Literaturangaben

**Für wen:** Anfänger & Überblick-Suchende

---

### [QUICKSTART.md](QUICKSTART.md) - Schnelleinstieg
**Länge:** ~8 Minuten  
**Inhalt:**
- ✓ Installation
- ✓ CLI-Beispiele
- ✓ Flutter-App starten
- ✓ CSV-Format
- ✓ Konfiguration (Praxis)
- ✓ Häufige Fehler → Lösungen
- ✓ FAQs
- ✓ Nächste Schritte

**Für wen:** Eilige Entwickler, Hands-On Learner

---

### [ARCHITECTURE.md](ARCHITECTURE.md) - Technische Tiefe
**Länge:** ~20 Minuten  
**Inhalt:**
- ✓ Gesamtarchitektur-Diagramme
- ✓ Data-Flow
- ✓ Service-Verantwortlichkeiten (SRP)
- ✓ Alle Datenmodelle detailliert
- ✓ Fehlerbehandlung-Strategie
- ✓ Statistische Formeln mit Code
- ✓ AIAG-Bewertungslogik
- ✓ Stabilitätsprüfung
- ✓ **Gage-R&R-Erweiterungspfad** ← Wichtig!
- ✓ Code-Style & Best-Practices
- ✓ Deployment-Optionen

**Für wen:** Architekten, Wartungsentwickler, Erweiter

---

### [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Projektüberblick
**Länge:** ~5 Minuten  
**Inhalt:**
- ✓ Was wurde gebaut?
- ✓ Projektstruktur (Baum)
- ✓ Alle Features kurz
- ✓ Statistik-Tabelle
- ✓ Tests & Validierung
- ✓ Verwendungsmöglichkeiten
- ✓ Quality-Checklist
- ✓ Nächste Schritte

**Für wen:** Management, Stakeholder, Überblick

---

### [example/example.dart](example/example.dart) - Praktisches Beispiel
**Länge:** Ausführbar (3 min), Code (150 Zeilen)  
**Inhalt:**
- ✓ Schritt-für-Schritt Code mit Ausgabe
- ✓ Fehlerbehandlung
- ✓ Datenfluss von CSV bis JSON
- ✓ Empfehlungen basierend auf Ergebnis
- ✓ Alle APIs demonstriert

**Ausführen:**
```bash
dart example/example.dart
```

**Für wen:** Code-Learner, Copy-Paste-starters

---

### [example_data.csv](example_data.csv) - Testdaten
**Format:** CSV mit 50 Messungen  
**Verwendung:**
```bash
dart bin/msa_cli.dart example_data.csv --tolerance=10.0 --reference=5.831
```

**Für wen:** Schnelles Testen ohne eigene Daten

---

### [test/calculation_service_test.dart](test/calculation_service_test.dart) - Unit-Tests
**Länge:** 42 Tests, ~280 Zeilen  
**Inhalt:**
- ✓ Euklidischer Abstand (an. Pythagoras)
- ✓ CSV-Parsing (valid + invalid)
- ✓ Statistik-Funktionen
- ✓ MSA-Analyse
- ✓ Fehlerfall-Tests
- ✓ Edge-Cases

**Ausführen:**
```bash
flutter test
```

**Für wen:** QA, Wartung, Verständnis

---

## 🔗 Zusammenhang

```
Start hier
    ↓
┌───────────────────────────────────┐
│   QUICKSTART.md   5-10 min        │  ← "Ich will JETZT loslegen"
└──────────────────┬────────────────┘
                   ↓
        ┌────────────────────────┐
        │   Try Example + CLI    │
        │   dart example/*.dart  │
        └──────────┬─────────────┘
                   ↓
        ┌────────────────────────┐
        │   README.md   15 min    │  ← "Ich will verstehen"
        └──────────┬─────────────┘
                   ↓
        ┌────────────────────────┐
        │ ARCHITECTURE.md 20 min  │  ← "Ich will erweitern"
        |     + Code Review      │
        └────────────────────────┘

┌─────────────────────────────────────────┐
│ Vollständiger Code-Überblick ← Dieses Schema
│ (Struktur, was wo ist)
└─────────────────────────────────────────┘
```

## 🎯 Nach Rolle

### Anfänger / Erste Verwendung
1. Lese [QUICKSTART.md](QUICKSTART.md) (Installation)
2. Führe `flutter test` aus
3. Laufe `dart example/example.dart`
4. Lese [README.md](README.md)

### Integrations-Entwickler
1. Lese [QUICKSTART.md](QUICKSTART.md) - Library-Integration
2. Kopiere Code-Snippet aus [README.md](README.md)
3. Schreib Tests nach [test/](test/)

### Qualitätsingenieur
1. Lese [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)
2. Lese [README.md](README.md) - AIAG-Standards
3. Nutze CLI: `dart bin/msa_cli.dart`
4. Interpretiere Outputs [QUICKSTART.md](QUICKSTART.md)

### Software-Architekt / Maintainer
1. Lese [ARCHITECTURE.md](ARCHITECTURE.md)
2. Review [lib/services/](lib/services/)
3. Plane Gage-R&R Erweiterung
4. Schreibe Tests

### Für Kurse / Lehre
1. [README.md](README.md) - Konzepte
2. [example/example.dart](example/example.dart) - Demo
3. [test/](test/) - Best-Practices
4. [ARCHITECTURE.md](ARCHITECTURE.md) - Tiefere Unterrichtsangebote

---

## 📋 Verwandlung

| Du willst... | Lese... | Zeit | Level |
|---|---|---|---|
| **Sofort starten** | QUICKSTART | 5 min | 🟢 Anfänger |
| **Verstehen (Überblick)** | README | 15 min | 🟢 Anfänger |
| **Verstehen (Tief)** | ARCHITECTURE | 20 min | 🟡 Intermediate |
| **Code-Beispiel** | example/example.dart | 10 min | 🟢 Anfänger |
| **Tests schreiben** | test/ | 15 min | 🟡 Intermediate |
| **Architektur reviewen** | ARCHITECTURE | 30 min | 🔴 Experte |
| **Erweitern (Gage R&R)** | ARCHITECTURE + lib/ | 1-2h | 🔴 Experte |
| **CLI benutzen** | QUICKSTART + bin/ | 5 min | 🟢 Anfänger |
| **Flutter-App erweitern** | lib/main.dart | 30 min | 🟡 Intermediate |

---

## 🚦 Empfohlene Lese-Reihenfolge

### Für Anfänger (≤2h)
```
1. PROJECT_SUMMARY.md     (5 min) - Was wurde gebaut?
2. QUICKSTART.md          (10 min) - Wie nutze ich es?
3. example/example.dart   (10 min) - Live-Beispiel
4. README.md              (15 min) - Tieferes Verständnis
```

### Für Intermediate (≤4h)
```
1-4. Anfänger (siehe oben)
5. test/*_test.dart       (20 min) - Testing verstehen
6. ARCHITECTURE.md        (20 min) - Architektur
7. Code-Review            (30 min) - lib/services/ studieren
```

### Für Experten (≤6h)
```
1-7. Intermediate (siehe oben)
8. ARCHITECTURE.md        (30 min - tiefer studieren)
   - Gage-R&R Roadmap
   - Erweiterungspfade
9. Eigene Gage-R&R impl.  (1-2h) - Praktisch erweitern
```

---

## 💡 Pro-Tips

- **Schnelle Referenz**: QUICKSTART.md Fehlerbehandlung Tabelle
- **API-Dokumentation**: Docstrings in `lib/services/`
- **Mathematik**: README.md Statistische Formeln Sektion
- **Gage R&R**: ARCHITECTURE.md Erweiterungspunkte
- **Live-Test**: `dart example/example.dart` ausführen

---

## ❓ Ich weiß nicht, wo ich anfangen soll → HIER!

**Skopos 1:** Wie nutze ich das schnell?  
→ QUICKSTART.md → CLI-Befehle

**Skopos 2:** Ich möchte verstehen, warum das so funktioniert  
→ README.md → Alle Konzepte erklärt

**Skopos 3:** Ich muss Code anpassen / erweitern  
→ ARCHITECTURE.md → Technisches Design

**Skopos 4:** Ich möchte Gage R&R hinzufügen  
→ ARCHITECTURE.md § 9 "Erweiterungspunkte für Gage R&R"

---

**Viel Erfolg! 🎯**
