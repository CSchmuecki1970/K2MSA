import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'models/measurement_data.dart';
import 'models/analysis_mode.dart';
import 'services/csv_service.dart';
import 'services/calculation_service.dart';
import 'services/msa_type1_service.dart';
import 'services/pdf_export_service.dart';

void main() {
  runApp(const MsaAnalysisApp());
}

class MsaAnalysisApp extends StatefulWidget {
  const MsaAnalysisApp({Key? key}) : super(key: key);

  @override
  State<MsaAnalysisApp> createState() => _MsaAnalysisAppState();
}

class _MsaAnalysisAppState extends State<MsaAnalysisApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSA Type 1 Analysis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MsaAnalysisScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: (bool newValue) {
          setState(() {
            _isDarkMode = newValue;
          });
        },
      ),
    );
  }
}

class MsaAnalysisScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const MsaAnalysisScreen({
    Key? key,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  State<MsaAnalysisScreen> createState() => _MsaAnalysisScreenState();
}

class _MsaAnalysisScreenState extends State<MsaAnalysisScreen> {
  String? _analysisResult;
  List<MeasurementData>? _measurements;
  bool _isLoading = false;
  dynamic _msaResult; // Speichert das MsaType1Result für PDF-Export
  AnalysisMode _currentMode = AnalysisMode.twoD_distances; // Standard-Modus

  @override
  void initState() {
    super.initState();
    // Demo beim Start ausführen - nach dem ersten Build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDemoAnalysis();
    });
  }

  /// Demo-CSV-Daten für 1D-Modus (nur X-Werte)
  String _generateDemo1DCsv() {
    final buffer = StringBuffer();
    buffer.writeln('x');
    final random = DateTime.now().microsecond % 100;
    for (int i = 0; i < 100; i++) {
      final value = 10.0 + (i % 10) + (random % 5) * 0.01;
      buffer.writeln('$value');
    }
    return buffer.toString();
  }

  /// Demo-CSV-Daten für 2D-direkt Modus (X,Y Wertepaare)
  String _generateDemo2DDirectCsv() {
    final buffer = StringBuffer();
    buffer.writeln('x,y');
    final random = DateTime.now().microsecond % 100;
    for (int i = 0; i < 100; i++) {
      final x = 10.0 + (i % 10) + (random % 5) * 0.01;
      final y = 20.0 + (i ~/ 10) + (random % 5) * 0.01;
      buffer.writeln('$x,$y');
    }
    return buffer.toString();
  }

  /// Demo-CSV-Daten für 2D-Distanzen Modus (Koordinatenpunkte)
  String _generateDemo2DDistancesCsv() {
    final buffer = StringBuffer();
    buffer.writeln('x1,y1,x2,y2');
    final random = DateTime.now().microsecond % 100;
    for (int i = 0; i < 100; i++) {
      final x1 = 10.0 + (i % 10) + (random % 5) * 0.01;
      final y1 = 20.0 + (i ~/ 10) + (random % 5) * 0.01;
      final x2 = x1 + 5.0 + (random % 2) * 0.1;
      final y2 = y1 + 3.0 + (random % 2) * 0.1;
      buffer.writeln('$x1,$y1,$x2,$y2');
    }
    return buffer.toString();
  }

  void _runDemoAnalysis() async {
    setState(() => _isLoading = true);

    try {
      String csvData;
      switch (_currentMode) {
        case AnalysisMode.oneD:
          csvData = _generateDemo1DCsv();
          break;
        case AnalysisMode.twoD_direct:
          csvData = _generateDemo2DDirectCsv();
          break;
        case AnalysisMode.twoD_distances:
          csvData = _generateDemo2DDistancesCsv();
          break;
      }

      await _analyzeData(csvData, _currentMode);
    } catch (e) {
      setState(() {
        _analysisResult = 'Fehler: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Analysiert CSV-Daten mit dem angegebenen Modus
  Future<void> _analyzeData(String csvContent, AnalysisMode mode) async {
    try {
      // 1. CSV parsen
      print('📝 Parsing CSV for mode: $mode');
      final parseResult = CsvService.parseCoordinates(csvContent);
      print('✓ CSV parsed successfully. Detected mode: ${parseResult.mode}');
      print('  - 1D values: ${parseResult.values_1d.length}');
      print('  - 2D direct points: ${parseResult.points_2d_direct.length}');
      print(
          '  - 2D distances points: ${parseResult.points_2d_distances.length}');

      // 2. MSA Typ 1 Analyse durchführen
      print('🔧 Starting MSA analysis...');
      final msaResult = MsaType1Service.analyzeWithMode(
        mode: parseResult.mode,
        values_1d: parseResult.values_1d,
        points_2d_direct: parseResult.points_2d_direct,
        points_2d_distances: parseResult.points_2d_distances,
        measurements_distances: parseResult.mode == AnalysisMode.twoD_distances
            ? _createMeasurementsFromPoints(parseResult.points_2d_distances)
            : null,
        toleranceRange: 10.0,
        analyzeStability: true,
      );
      print('✓ MSA analysis completed');

      // 3. UI aktualisieren
      if (mounted) {
        setState(() {
          _analysisResult = msaResult.toFormattedString();
          _msaResult = msaResult;
          _currentMode = parseResult.mode;
          _measurements = _createMeasurementsFromResult(parseResult, msaResult);
        });

        // Erfolgs-Meldung
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${msaResult.sampleCount} Messungen analysiert (${msaResult.mode.shortDescription})',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Debug: JSON Export
      print('\n📋 JSON Export:');
      print(msaResult.toJson());
    } catch (e, stackTrace) {
      print('❌ Error in _analyzeData: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _analysisResult = 'Fehler beim Laden der Datei:\n\n$e\n\n$stackTrace';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Erstellt MeasurementData-Objekte für 2D-Distanzen Modus
  List<MeasurementData> _createMeasurementsFromPoints(List<dynamic> points) {
    final measurements = <MeasurementData>[];
    for (int i = 0; i < points.length; i += 2) {
      if (i + 1 < points.length) {
        final measurement = CalculationService.createMeasurement(
          id: (i ~/ 2) + 1,
          point1: points[i],
          point2: points[i + 1],
          timestamp:
              DateTime.now().subtract(Duration(minutes: points.length - i)),
        );
        measurements.add(measurement);
      }
    }
    return measurements;
  }

  /// Erstellt MeasurementData-Objekte aus Parse-Result
  List<MeasurementData> _createMeasurementsFromResult(
      CsvParseResult result, dynamic msaResult) {
    switch (result.mode) {
      case AnalysisMode.oneD:
      case AnalysisMode.twoD_direct:
        // Für 1D und 2D direkt: einfach Mock-Messungen erstellen
        // Diese werden vom Service erstellt, wir brauchen sie aber evtl. nicht
        return [];
      case AnalysisMode.twoD_distances:
        return _createMeasurementsFromPoints(result.points_2d_distances);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MSA Type 1 - Measurement System Analysis'),
        elevation: 0,
        actions: [
          Tooltip(
            message: widget.isDarkMode ? 'Helles Design' : 'Dunkles Design',
            child: IconButton(
              icon:
                  Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                widget.onThemeChanged(!widget.isDarkMode);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 1. Header-Sektion
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messsystemanalyse (AIAG Standard)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Typ 1 - Variables (Messwerte)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 2. Datensatz-Übersicht
          if (_measurements != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datensatz-Übersicht',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_measurements != null && _measurements!.isNotEmpty)
                        Text(
                          'Anzahl Messungen: ${_measurements!.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (_measurements != null && _measurements!.isNotEmpty)
                        Text(
                          'Erste Messung: ${_measurements!.first.distance.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (_measurements == null || _measurements!.isEmpty)
                        const Text(
                          'Keine Messdaten für diesen Modus\n(nur für 2D Distanzen)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      if (_measurements != null && _measurements!.isNotEmpty)
                        Text(
                          'Letzte Messung: ${_measurements!.last.distance.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Analyse-Ergebnisse
          if (_analysisResult != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12.0),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 500,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _analysisResult!,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 4. Analysis Mode Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Demo-Modus wählen:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<AnalysisMode>(
                      segments: const <ButtonSegment<AnalysisMode>>[
                        ButtonSegment<AnalysisMode>(
                          value: AnalysisMode.oneD,
                          label: Text('1D'),
                          tooltip: 'Nur X-Werte',
                        ),
                        ButtonSegment<AnalysisMode>(
                          value: AnalysisMode.twoD_direct,
                          label: Text('2D direkt'),
                          tooltip: 'X,Y Wertepaare',
                        ),
                        ButtonSegment<AnalysisMode>(
                          value: AnalysisMode.twoD_distances,
                          label: Text('2D Distanzen'),
                          tooltip: 'Distanzen zwischen Punkten',
                        ),
                      ],
                      selected: <AnalysisMode>{_currentMode},
                      onSelectionChanged: (Set<AnalysisMode> newSelection) {
                        setState(() {
                          _currentMode = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runDemoAnalysis,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Demo-Analyse ausführen'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _showCsvUploadDialog(),
                  child: const Text('Eigene CSV-Datei laden'),
                ),
                const SizedBox(height: 8),
                if (_msaResult != null)
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _exportToPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Als PDF exportieren'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    exit(0);
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('Beenden'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showCsvUploadDialog() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        dialogTitle: 'CSV-Datei auswählen',
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        if (filePath != null) {
          await _loadAndAnalyzeCsv(filePath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Öffnen der Datei: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAndAnalyzeCsv(String filePath) async {
    setState(() => _isLoading = true);

    try {
      // 1. CSV-Datei lesen
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Datei nicht gefunden: $filePath');
      }

      final csvContent = await file.readAsString();

      // 2. CSV-Daten parsen und Mode erkennen
      final parseResult = CsvService.parseCoordinates(csvContent);

      // 3. Falls 2 Spalten: Mode wählen lassen
      AnalysisMode modeToUse = parseResult.mode;
      if (parseResult.mode == AnalysisMode.twoD_direct) {
        if (mounted) {
          setState(() => _isLoading = false);

          modeToUse =
              await _showModeSelectionDialog() ?? AnalysisMode.twoD_direct;

          setState(() => _isLoading = true);
        }
      }

      // 4. Analyse durchführen
      setState(() => _isLoading = true);
      await _analyzeData(csvContent, modeToUse);
    } catch (e) {
      setState(() {
        _analysisResult = 'Fehler beim Laden der Datei:\n\n$e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Dialog zur Mode-Auswahl, wenn CSV 2 Spalten hat
  Future<AnalysisMode?> _showModeSelectionDialog() async {
    return showDialog<AnalysisMode>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Analysemodus wählen'),
          content: const Text(
            'Diese CSV hat 2 Spalten (x,y).\n\n'
            'Wie möchten Sie diese analysieren?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, AnalysisMode.twoD_direct);
              },
              child: const Text('2D direkt\n(X,Y Wertepaare)'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, AnalysisMode.twoD_distances);
              },
              child: const Text('2D Distanzen\n(zwischen Punktparen)'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToPdf() async {
    if (_msaResult == null || _measurements == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Analysedaten zum Exportieren'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pdfPath = await PdfExportService.generatePdfReport(
        result: _msaResult,
        measurements: _measurements!,
      );

      // Datei öffnen (wenn möglich)
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '""', pdfPath], runInShell: true);
      } else if (Platform.isMacOS) {
        Process.run('open', [pdfPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [pdfPath]);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ PDF gespeichert: $pdfPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Exportieren: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
