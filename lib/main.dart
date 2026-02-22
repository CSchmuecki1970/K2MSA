import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'models/measurement_data.dart';
import 'models/analysis_mode.dart';
import 'models/analysis_metadata.dart';
import 'models/msa_result.dart';
import 'models/process_monitoring_result.dart';
import 'models/analysis_save_package.dart';
import 'services/csv_service.dart';
import 'services/calculation_service.dart';
import 'services/msa_type1_service.dart';
import 'services/process_monitoring_service.dart';
import 'services/pdf_export_service.dart';
import 'services/localization_service.dart';

/// Analysis type selector for main UI
enum AnalysisType {
  // ignore: constant_identifier_names
  MSA_TYPE_1,
  // ignore: constant_identifier_names
  PROCESS_MONITORING,
}

extension AnalysisTypeDescription on AnalysisType {
  String get description {
    switch (this) {
      case AnalysisType.MSA_TYPE_1:
        return 'MSA Typ 1 (Instrument-Fokus)';
      case AnalysisType.PROCESS_MONITORING:
        return 'Prozessüberwachung (Prozess-Fokus)';
    }
  }
}

void main() {
  runApp(const MsaAnalysisApp());
}

class MsaAnalysisApp extends StatefulWidget {
  const MsaAnalysisApp({Key? key}) : super(key: key);

  @override
  State<MsaAnalysisApp> createState() => _MsaAnalysisAppState();
}

class _MsaAnalysisAppState extends State<MsaAnalysisApp> {
  String _currentTheme = 'light'; // 'light', 'dark', 'dracula'
  String _currentLocale = 'de'; // 'de', 'en'

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_preference') ?? 'light';
    final savedLocale = prefs.getString('language_preference') ?? 'de';

    // Initialize localization service
    await LocalizationService().setLocale(savedLocale);

    setState(() {
      _currentTheme = savedTheme;
      _currentLocale = savedLocale;
    });
  }

  Future<void> _saveThemePreference(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_preference', theme);
  }

  Future<void> _saveLocalePreference(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_preference', locale);
    await LocalizationService().setLocale(locale);
    setState(() {
      _currentLocale = locale;
    });
  }

  // Dracula theme colors
  static const Color _draculaBg = Color(0xFF282a36);
  static const Color _draculaCurrent = Color(0xFF44475a);
  static const Color _draculaForeground = Color(0xFFF8F8F2);
  static const Color _draculaPurple = Color(0xFFBD93F9);
  static const Color _draculaCyan = Color(0xFF8BE9FD);
  static const Color _draculaGreen = Color(0xFF50FA7B);

  ThemeData _buildDraculaTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _draculaBg,
      primaryColor: _draculaPurple,
      colorScheme: ColorScheme.dark(
        primary: _draculaPurple,
        secondary: _draculaCyan,
        tertiary: _draculaGreen,
        surface: _draculaCurrent,
        surfaceContainerHighest: _draculaCurrent,
        onSurface: _draculaForeground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _draculaCurrent,
        foregroundColor: _draculaForeground,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _draculaCurrent,
        elevation: 4,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        labelStyle: TextStyle(color: _draculaCyan),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white30),
        bodyMedium: TextStyle(color: Colors.white30),
        bodySmall: TextStyle(color: Colors.white30),
        titleLarge: TextStyle(color: Colors.white30),
        titleMedium: TextStyle(color: Colors.white30),
        titleSmall: TextStyle(color: Colors.white30),
        labelLarge: TextStyle(color: Colors.white30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    late ThemeData darkTheme;
    if (_currentTheme == 'dracula') {
      darkTheme = _buildDraculaTheme();
    } else {
      darkTheme = ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black87),
          labelLarge: TextStyle(color: Colors.black87),
        ),
      );
    }

    return MaterialApp(
      title: 'MSA Type 1 Analysis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: darkTheme,
      themeMode: _currentTheme == 'light' ? ThemeMode.light : ThemeMode.dark,
      locale: Locale(_currentLocale),
      home: MsaAnalysisScreen(
        currentTheme: _currentTheme,
        currentLocale: _currentLocale,
        onThemeChanged: (String newTheme) {
          setState(() {
            _currentTheme = newTheme;
          });
          _saveThemePreference(newTheme);
        },
        onLocaleChanged: (String newLocale) {
          setState(() {
            _currentLocale = newLocale;
          });
          _saveLocalePreference(newLocale);
        },
      ),
    );
  }
}

class MsaAnalysisScreen extends StatefulWidget {
  final String currentTheme;
  final String currentLocale;
  final Function(String) onThemeChanged;
  final Function(String) onLocaleChanged;

  const MsaAnalysisScreen({
    Key? key,
    required this.currentTheme,
    required this.currentLocale,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  State<MsaAnalysisScreen> createState() => _MsaAnalysisScreenState();
}

class _MsaAnalysisScreenState extends State<MsaAnalysisScreen> {
  String? _analysisResult;
  List<MeasurementData>? _measurements;
  bool _isLoading = false;
  bool _isDemoMode = false; // Demo mode toggle
  dynamic
      _msaResult; // Speichert das MsaType1Result oder ProcessMonitoringResult
  AnalysisMode _currentMode = AnalysisMode.twoD_distances; // Standard-Modus
  AnalysisType _analysisType = AnalysisType.MSA_TYPE_1; // Standard: MSA Type 1

  // Metadata für Traceability
  late AnalysisMetadata _metadata;

  // Form controllers für Metadata
  late TextEditingController _partNumberController;
  late TextEditingController _partNameController;
  late TextEditingController _drawingReferenceController;
  late TextEditingController _instrumentNameController;
  late TextEditingController _instrumentIdController;
  late TextEditingController _calibrationStatusController;
  late TextEditingController _calibrationDateController;
  late TextEditingController _analyzedByController;
  late TextEditingController _reviewedByController;
  late TextEditingController _customerController;
  late TextEditingController _companyController;
  late TextEditingController _departmentController;
  late TextEditingController _machineController;
  late TextEditingController _processOrOperationController;
  late TextEditingController _measurementProcedureController;
  late TextEditingController _samplingPlanController;
  late TextEditingController _temperatureController;
  late TextEditingController _humidityController;
  late TextEditingController _numberOfOperatorsController;
  late TextEditingController _numberOfReplicatesController;
  late TextEditingController _numberOfPartsController;
  late TextEditingController _uslController;
  late TextEditingController _lslController;

  @override
  void initState() {
    super.initState();
    _initializeMetadataControllers();
    // Demo beim Start ausführen - nach dem ersten Build (wenn Demo Mode aktiv)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDemoMode) {
        _runDemoAnalysis();
      }
    });
  }

  @override
  void dispose() {
    _partNumberController.dispose();
    _partNameController.dispose();
    _drawingReferenceController.dispose();
    _instrumentNameController.dispose();
    _instrumentIdController.dispose();
    _calibrationStatusController.dispose();
    _calibrationDateController.dispose();
    _analyzedByController.dispose();
    _reviewedByController.dispose();
    _customerController.dispose();
    _companyController.dispose();
    _departmentController.dispose();
    _machineController.dispose();
    _processOrOperationController.dispose();
    _measurementProcedureController.dispose();
    _samplingPlanController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _numberOfOperatorsController.dispose();
    _numberOfReplicatesController.dispose();
    _numberOfPartsController.dispose();
    _uslController.dispose();
    _lslController.dispose();
    super.dispose();
  }

  void _initializeMetadataControllers() {
    _partNumberController = TextEditingController();
    _partNameController = TextEditingController();
    _drawingReferenceController = TextEditingController();
    _instrumentNameController = TextEditingController();
    _instrumentIdController = TextEditingController();
    _calibrationStatusController = TextEditingController();
    _calibrationDateController = TextEditingController();
    _analyzedByController = TextEditingController();
    _reviewedByController = TextEditingController();
    _customerController = TextEditingController();
    _companyController = TextEditingController();
    _departmentController = TextEditingController();
    _machineController = TextEditingController();
    _processOrOperationController = TextEditingController();
    _measurementProcedureController = TextEditingController();
    _samplingPlanController = TextEditingController();
    _temperatureController = TextEditingController();
    _humidityController = TextEditingController();
    _numberOfOperatorsController = TextEditingController();
    _numberOfReplicatesController = TextEditingController();
    _numberOfPartsController = TextEditingController();
    _uslController = TextEditingController();
    _lslController = TextEditingController();

    _metadata = AnalysisMetadata();
  }

  void _updateMetadataFromControllers() {
    _metadata = AnalysisMetadata(
      partNumber: _partNumberController.text.isEmpty
          ? null
          : _partNumberController.text,
      partName:
          _partNameController.text.isEmpty ? null : _partNameController.text,
      drawingReference: _drawingReferenceController.text.isEmpty
          ? null
          : _drawingReferenceController.text,
      instrumentName: _instrumentNameController.text.isEmpty
          ? null
          : _instrumentNameController.text,
      instrumentId: _instrumentIdController.text.isEmpty
          ? null
          : _instrumentIdController.text,
      calibrationStatus: _calibrationStatusController.text.isEmpty
          ? null
          : _calibrationStatusController.text,
      calibrationDate: _calibrationDateController.text.isEmpty
          ? null
          : DateTime.tryParse(_calibrationDateController.text),
      analyzedBy: _analyzedByController.text.isEmpty
          ? null
          : _analyzedByController.text,
      reviewedBy: _reviewedByController.text.isEmpty
          ? null
          : _reviewedByController.text,
      customer:
          _customerController.text.isEmpty ? null : _customerController.text,
      company: _companyController.text.isEmpty ? null : _companyController.text,
      department: _departmentController.text.isEmpty
          ? null
          : _departmentController.text,
      machine: _machineController.text.isEmpty ? null : _machineController.text,
      processOrOperation: _processOrOperationController.text.isEmpty
          ? null
          : _processOrOperationController.text,
      measurementProcedure: _measurementProcedureController.text.isEmpty
          ? null
          : _measurementProcedureController.text,
      samplingPlan: _samplingPlanController.text.isEmpty
          ? null
          : _samplingPlanController.text,
      temperature: _temperatureController.text.isEmpty
          ? null
          : double.tryParse(_temperatureController.text),
      humidity: _humidityController.text.isEmpty
          ? null
          : double.tryParse(_humidityController.text),
      numberOfOperators: _numberOfOperatorsController.text.isEmpty
          ? null
          : int.tryParse(_numberOfOperatorsController.text),
      numberOfReplicates: _numberOfReplicatesController.text.isEmpty
          ? null
          : int.tryParse(_numberOfReplicatesController.text),
      numberOfParts: _numberOfPartsController.text.isEmpty
          ? null
          : int.tryParse(_numberOfPartsController.text),
      upperSpecLimit: _uslController.text.isEmpty
          ? null
          : double.tryParse(_uslController.text),
      lowerSpecLimit: _lslController.text.isEmpty
          ? null
          : double.tryParse(_lslController.text),
    );
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
      // 0. Metadaten aktualisieren
      _updateMetadataFromControllers();

      // 1. CSV parsen
      print('📝 Parsing CSV for mode: $mode');
      final parseResult = CsvService.parseCoordinates(csvContent);
      print('✓ CSV parsed successfully. Detected mode: ${parseResult.mode}');
      print('  - 1D values: ${parseResult.values_1d.length}');
      print('  - 2D direct points: ${parseResult.points_2d_direct.length}');
      print(
          '  - 2D distances points: ${parseResult.points_2d_distances.length}');

      // 2. Wähle Analyse basierend auf Modus
      print('🔧 Selected Analysis: ${_analysisType.description}');

      dynamic analysisResult;
      String resultDisplay;

      if (_analysisType == AnalysisType.PROCESS_MONITORING) {
        // Prozessüberwachungs-Analyse (1D, 2D direct, oder 2D distances)
        print('Starting Process Monitoring analysis...');

        ProcessMonitoringResult result;

        if (parseResult.values_1d.isNotEmpty) {
          // 1D Mode
          result = ProcessMonitoringService.analyze1D(
            values: parseResult.values_1d,
          );
        } else if (parseResult.points_2d_direct.isNotEmpty) {
          // 2D Direct Mode
          result = ProcessMonitoringService.analyze2DDirect(
            points: parseResult.points_2d_direct,
          );
        } else if (parseResult.points_2d_distances.isNotEmpty) {
          // 2D Distances Mode
          result = ProcessMonitoringService.analyze2DDistances(
            measurements: _createMeasurementsFromPoints(
              parseResult.points_2d_distances,
            ),
          );
        } else {
          throw Exception(
            'Prozessüberwachung benötigt Daten (1D, 2D X,Y oder 2D x1,y1,x2,y2). '
            'Bitte eine gültige CSV-Datei laden.',
          );
        }

        analysisResult = result;
        resultDisplay = result.toFormattedString();
        print('✓ Process Monitoring analysis completed');
      } else {
        // MSA Typ 1 Analyse (Standard)
        print('🔧 Starting MSA Type 1 analysis...');
        final msaResult = MsaType1Service.analyzeWithMode(
          mode: parseResult.mode,
          values_1d: parseResult.values_1d,
          points_2d_direct: parseResult.points_2d_direct,
          points_2d_distances: parseResult.points_2d_distances,
          measurements_distances: parseResult.mode ==
                  AnalysisMode.twoD_distances
              ? _createMeasurementsFromPoints(parseResult.points_2d_distances)
              : null,
          toleranceRange: 10.0,
          analyzeStability: true,
        );
        print('✓ MSA analysis completed');

        // 3. Metadaten an Ergebnis anhängen
        final msaResultWithMetadata = MsaType1Result(
          mode: msaResult.mode,
          mean: msaResult.mean,
          standardDeviation: msaResult.standardDeviation,
          min: msaResult.min,
          max: msaResult.max,
          sampleCount: msaResult.sampleCount,
          repeatability: msaResult.repeatability,
          bias: msaResult.bias,
          studyVariation: msaResult.studyVariation,
          percentStudyVariation: msaResult.percentStudyVariation,
          discriminationRatio: msaResult.discriminationRatio,
          numberOfDistinctCategories: msaResult.numberOfDistinctCategories,
          resolutionPercent: msaResult.resolutionPercent,
          confidenceIntervalLower: msaResult.confidenceIntervalLower,
          confidenceIntervalUpper: msaResult.confidenceIntervalUpper,
          controlLimitLower: msaResult.controlLimitLower,
          controlLimitUpper: msaResult.controlLimitUpper,
          cp: msaResult.cp,
          cpk: msaResult.cpk,
          toleranceUsedPercent: msaResult.toleranceUsedPercent,
          suitability: msaResult.suitability,
          interpretation: msaResult.interpretation,
          stabilityCheck: msaResult.stabilityCheck,
          metadata: _metadata,
        );

        analysisResult = msaResultWithMetadata;
        resultDisplay = msaResultWithMetadata.toFormattedString();

        // Debug: JSON Export
        print('\n📋 JSON Export:');
        print(msaResult.toJson());
      }

      // 4. UI aktualisieren
      if (mounted) {
        setState(() {
          _analysisResult = resultDisplay;
          _msaResult = analysisResult;
          _currentMode = parseResult.mode;
          if (analysisResult is MsaType1Result) {
            _measurements = _createMeasurementsFromResult(
              parseResult,
              analysisResult as MsaType1Result,
            );
          } else {
            _measurements = null; // Process Monitoring nutzt keine Measurements
          }
        });

        // Erfolgs-Meldung
        final sampleCount = analysisResult is MsaType1Result
            ? (analysisResult as MsaType1Result).sampleCount
            : (analysisResult as ProcessMonitoringResult).sampleCount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ $sampleCount Messungen analysiert (${_analysisType.description})',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
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
          PopupMenuButton<String>(
            tooltip: 'Select Language',
            onSelected: (String locale) {
              widget.onLocaleChanged(locale);
            },
            itemBuilder: (BuildContext context) =>
                LocalizationService.availableLocales
                    .map((locale) => PopupMenuItem<String>(
                          value: locale,
                          child: Row(
                            children: [
                              Icon(Icons.language, size: 18),
                              const SizedBox(width: 10),
                              Text(LocalizationService.getLocaleName(locale)),
                            ],
                          ),
                        ))
                    .toList(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Icon(Icons.language),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: LocalizationService().t('selectTheme'),
            onSelected: (String theme) {
              widget.onThemeChanged(theme);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'light',
                child: Row(
                  children: [
                    Icon(Icons.light_mode, size: 18),
                    SizedBox(width: 10),
                    Text('Light'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'dark',
                child: Row(
                  children: [
                    Icon(Icons.dark_mode, size: 18),
                    SizedBox(width: 10),
                    Text('Dark'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'dracula',
                child: Row(
                  children: [
                    Icon(Icons.palette, size: 18),
                    SizedBox(width: 10),
                    Text('Dracula'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Icon(
                  widget.currentTheme == 'dracula'
                      ? Icons.palette
                      : widget.currentTheme == 'dark'
                          ? Icons.dark_mode
                          : Icons.light_mode,
                ),
              ),
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
                Text(
                  LocalizationService().t('analysisTitle'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  LocalizationService().t('analysisSubtitle'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 1.5. Demo Mode Toggle & Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isDemoMode,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _isDemoMode = newValue ?? false;
                              if (_isDemoMode) {
                                _runDemoAnalysis();
                              } else {
                                _analysisResult = null;
                                _measurements = null;
                                _msaResult = null;
                              }
                            });
                          },
                        ),
                        Text(
                          LocalizationService().t('demoModeActivate'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          const Text(
                            'Analyse-Modus:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<AnalysisType>(
                              value: _analysisType,
                              isExpanded: true,
                              items: AnalysisType.values
                                  .map((mode) => DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode.description),
                                      ))
                                  .toList(),
                              onChanged: (AnalysisType? newType) {
                                if (newType != null) {
                                  setState(() {
                                    _analysisType = newType;
                                    _analysisResult = null;
                                    _msaResult = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isDemoMode && _analysisResult == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    LocalizationService().t('firstSteps'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInstructionStep(
                                1,
                                LocalizationService().t('demoStep1Title'),
                                LocalizationService().t('demoStep1Description'),
                              ),
                              const SizedBox(height: 10),
                              _buildInstructionStep(
                                2,
                                LocalizationService().t('step2Title'),
                                LocalizationService().t('step2Description'),
                              ),
                              const SizedBox(height: 10),
                              _buildInstructionStep(
                                3,
                                LocalizationService().t('demoStep3Title'),
                                '',
                              ),
                              const SizedBox(height: 10),
                              _buildInstructionStep(
                                4,
                                LocalizationService().t('step4Title'),
                                LocalizationService().t('step4Description'),
                              ),
                              const SizedBox(height: 10),
                              _buildInstructionStep(
                                5,
                                LocalizationService().t('step5Title'),
                                LocalizationService().t('step5Description'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 1.5. CSV Upload Instructions
          if (_analysisResult == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            LocalizationService().t('csvFormatLabel'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LocalizationService().t('format1D'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocalizationService().t('format2D'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LocalizationService().t('format2DDistances'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                LocalizationService().t('fileWillBeAnalyzed'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                      Text(
                        LocalizationService().t('datasetOverview'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_measurements != null && _measurements!.isNotEmpty)
                        Text(
                          LocalizationService().t('numMeasurements').replaceAll(
                              '{count}', _measurements!.length.toString()),
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (_measurements != null && _measurements!.isNotEmpty)
                        Text(
                          LocalizationService()
                              .t('firstMeasurement')
                              .replaceAll(
                                  '{value}',
                                  _measurements!.first.distance
                                      .toStringAsFixed(6)),
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (_measurements == null || _measurements!.isEmpty)
                        Text(
                          LocalizationService().t('noMeasurementData'),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      if (_measurements != null && _measurements!.isNotEmpty)
                        Text(
                          LocalizationService().t('lastMeasurement').replaceAll(
                              '{value}',
                              _measurements!.last.distance.toStringAsFixed(6)),
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // 2.5 Metadata Form
          _buildMetadataForm(),

          // 3. Analyse-Ergebnisse
          if (_analysisResult != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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

          if (_msaResult is MsaType1Result)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Builder(
                    builder: (context) {
                      final result = _msaResult as MsaType1Result;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocalizationService()
                                .t('discriminationSectionTitle'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${LocalizationService().t('discriminationRatio')}: '
                            '${_formatMetricValue(result.discriminationRatio)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('distinctCategories')}: '
                            '${result.numberOfDistinctCategories ?? LocalizationService().t('na')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('resolutionPercentLabel')}: '
                            '${result.resolutionPercent != null ? '${_formatMetricValue(result.resolutionPercent)}%' : LocalizationService().t('na')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocalizationService().t('confidenceSectionTitle'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${LocalizationService().t('ciLower')}: '
                            '${_formatMetricValue(result.confidenceIntervalLower, decimals: 6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('ciUpper')}: '
                            '${_formatMetricValue(result.confidenceIntervalUpper, decimals: 6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('controlLimitLower')}: '
                            '${_formatMetricValue(result.controlLimitLower, decimals: 6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('controlLimitUpper')}: '
                            '${_formatMetricValue(result.controlLimitUpper, decimals: 6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LocalizationService().t('processCapabilityTitle'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${LocalizationService().t('cpLabel')}: '
                            '${_formatMetricValue(result.cp, decimals: 3)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('cpkLabel')}: '
                            '${_formatMetricValue(result.cpk, decimals: 3)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${LocalizationService().t('toleranceUsedPercentLabel')}: '
                            '${result.toleranceUsedPercent != null ? '${_formatMetricValue(result.toleranceUsedPercent)}%' : LocalizationService().t('na')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // 4. Analysis Mode Selector (nur wenn Demo Mode aktiv)
          if (_isDemoMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService().t('demoAnalysisMode'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      SegmentedButton<AnalysisMode>(
                        segments: <ButtonSegment<AnalysisMode>>[
                          ButtonSegment<AnalysisMode>(
                            value: AnalysisMode.oneD,
                            label: Text(LocalizationService().t('mode1DLabel')),
                            tooltip: LocalizationService().t('mode1DTooltip'),
                          ),
                          ButtonSegment<AnalysisMode>(
                            value: AnalysisMode.twoD_direct,
                            label: Text(
                                LocalizationService().t('mode2DDirectLabel')),
                            tooltip:
                                LocalizationService().t('mode2DDirectTooltip'),
                          ),
                          ButtonSegment<AnalysisMode>(
                            value: AnalysisMode.twoD_distances,
                            label: Text(LocalizationService()
                                .t('mode2DDistancesLabel')),
                            tooltip: LocalizationService()
                                .t('mode2DDistancesTooltip'),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _runDemoAnalysis,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(LocalizationService().t('demo')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showCsvUploadDialog(),
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(LocalizationService().t('csvLoad')),
                ),
                if (_msaResult != null)
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _exportToPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: Text(LocalizationService().t('pdf')),
                  ),
                if (_msaResult != null)
                  FilledButton.tonalIcon(
                    onPressed: _isLoading ? null : _saveAnalysis,
                    icon: const Icon(Icons.save, size: 18),
                    label: Text(LocalizationService().t('save')),
                  ),
                FilledButton.tonalIcon(
                  onPressed: _isLoading ? null : _loadAnalysis,
                  icon: const Icon(Icons.folder_open, size: 18),
                  label: Text(LocalizationService().t('load')),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    exit(0);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(LocalizationService().t('exit')),
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
        dialogTitle: LocalizationService().t('selectCsvFile'),
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
            content: Text(LocalizationService()
                .t('fileOpenError')
                .replaceAll('{error}', e.toString())),
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
        throw Exception(LocalizationService()
            .t('fileNotFound')
            .replaceAll('{path}', filePath));
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
        _analysisResult = LocalizationService()
            .t('errorLoadingFile')
            .replaceAll('{error}', e.toString());
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService()
                .t('error')
                .replaceAll('{error}', e.toString())),
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
          title: Text(LocalizationService().t('selectAnalysisMode')),
          content: Text(
            LocalizationService().t('csvTwoColumnsInfo') +
                '\n\n'
                    '${LocalizationService().t('howToAnalyze')}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, AnalysisMode.twoD_direct);
              },
              child: Text(LocalizationService().t('modeSelectDirect')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, AnalysisMode.twoD_distances);
              },
              child: Text(LocalizationService().t('modeSelectDistances')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToPdf() async {
    if (_msaResult == null) {
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
      String pdfPath;

      if (_msaResult is MsaType1Result) {
        // Export MSA Type 1 report
        if (_measurements == null) {
          throw Exception('Messungen erforderlich für MSA Type 1 PDF');
        }
        pdfPath = await PdfExportService.generatePdfReport(
          result: _msaResult as MsaType1Result,
          measurements: _measurements!,
        );
      } else if (_msaResult is ProcessMonitoringResult) {
        // Export Process Monitoring report
        pdfPath = await PdfExportService.generateProcessMonitoringPdfReport(
          result: _msaResult as ProcessMonitoringResult,
        );
      } else {
        throw Exception('Unbekannter Analyseergebnistyp');
      }

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

  /// Save analysis to JSON file
  Future<void> _saveAnalysis() async {
    if (_measurements == null || _msaResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Analysedaten zum Speichern'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create save package
      final analysisName = _customerController.text.isEmpty
          ? _partNumberController.text.isEmpty
              ? 'Analyse_${DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-')}'
              : 'Analyse_${_partNumberController.text}'
          : 'Analyse_${_customerController.text}';

      final package = AnalysisSavePackage(
        createdAt: DateTime.now(),
        analysisName: analysisName,
        measurements: _measurements!,
        metadata: _metadata,
        result: _msaResult,
      );

      // Get Documents folder
      String filePath;
      if (Platform.isWindows) {
        final documentsFolder = Directory(
            'C:\\Users\\${Platform.environment['USERNAME']}\\Documents\\MSA Analysen');
        if (!await documentsFolder.exists()) {
          await documentsFolder.create(recursive: true);
        }
        final fileName =
            '${analysisName}_${DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-')}.json';
        filePath = '${documentsFolder.path}\\$fileName';
      } else {
        // For other platforms, use Documents folder (usually)
        final fileName =
            '${analysisName}_${DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-')}.json';
        filePath =
            '${Platform.environment['HOME']}/Documents/MSA Analysen/$fileName';
      }

      // Write file
      final file = File(filePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(package.toJsonString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Analyse gespeichert: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Load analysis from JSON file
  Future<void> _loadAnalysis() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Analyse laden',
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);

        final file = File(result.files.first.path!);
        final jsonString = await file.readAsString();

        final package = AnalysisSavePackage.fromJsonString(jsonString);

        setState(() {
          // Restore measurements
          _measurements = package.measurements;

          // Restore metadata
          _metadata = package.metadata ?? AnalysisMetadata();
          _partNumberController.text = _metadata.partNumber ?? '';
          _partNameController.text = _metadata.partName ?? '';
          _drawingReferenceController.text = _metadata.drawingReference ?? '';
          _instrumentNameController.text = _metadata.instrumentName ?? '';
          _instrumentIdController.text = _metadata.instrumentId ?? '';
          _calibrationStatusController.text = _metadata.calibrationStatus ?? '';
          _calibrationDateController.text =
              _metadata.calibrationDate?.toIso8601String().split('T').first ??
                  '';
          _analyzedByController.text = _metadata.analyzedBy ?? '';
          _reviewedByController.text = _metadata.reviewedBy ?? '';
          _customerController.text = _metadata.customer ?? '';
          _companyController.text = _metadata.company ?? '';
          _departmentController.text = _metadata.department ?? '';
          _machineController.text = _metadata.machine ?? '';
          _processOrOperationController.text =
              _metadata.processOrOperation ?? '';
          _measurementProcedureController.text =
              _metadata.measurementProcedure ?? '';
          _samplingPlanController.text = _metadata.samplingPlan ?? '';
          _temperatureController.text = _metadata.temperature?.toString() ?? '';
          _humidityController.text = _metadata.humidity?.toString() ?? '';
          _numberOfOperatorsController.text =
              _metadata.numberOfOperators?.toString() ?? '';
          _numberOfReplicatesController.text =
              _metadata.numberOfReplicates?.toString() ?? '';
          _numberOfPartsController.text =
              _metadata.numberOfParts?.toString() ?? '';
          _uslController.text = _metadata.upperSpecLimit?.toString() ?? '';
          _lslController.text = _metadata.lowerSpecLimit?.toString() ?? '';

          // Restore analysis result
          _msaResult = package.result;

          // Update UI to show loaded data
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Analyse geladen: ${package.analysisName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  /// Builds an instruction step for the beginner guide
  Widget _buildInstructionStep(
      int stepNumber, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the metadata form section
  Widget _buildMetadataForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocalizationService().t('analysisInfo'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Part Information Section
              Text(
                LocalizationService().t('partInfo'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _partNumberController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('partNumber'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _partNameController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('partName'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _drawingReferenceController,
                decoration: InputDecoration(
                  labelText: LocalizationService().t('drawingReference'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => _updateMetadataFromControllers(),
              ),
              const SizedBox(height: 12),
              // Specification Limits
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _uslController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('upperLimit'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _lslController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('lowerLimit'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Measurement System Section
              Text(
                LocalizationService().t('measurementSystem'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instrumentNameController,
                decoration: InputDecoration(
                  labelText: LocalizationService().t('instrumentName'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => _updateMetadataFromControllers(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _instrumentIdController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('instrumentId'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _calibrationStatusController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('calibrationStatus'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _calibrationDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: LocalizationService().t('calibrationDate'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => _updateMetadataFromControllers(),
              ),
              const SizedBox(height: 20),
              // Analysis Information Section
              Text(
                LocalizationService().t('analysisDetails'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _analyzedByController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('analyzedBy'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _customerController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('customer'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reviewedByController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('reviewedBy'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('department'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('company'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _machineController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('machine'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _processOrOperationController,
                      decoration: InputDecoration(
                        labelText:
                            LocalizationService().t('processOrOperation'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _measurementProcedureController,
                      decoration: InputDecoration(
                        labelText:
                            LocalizationService().t('measurementProcedure'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _samplingPlanController,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('samplingPlan'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _temperatureController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('temperature'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _humidityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('humidity'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _numberOfOperatorsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: LocalizationService().t('numberOfOperators'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _numberOfReplicatesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            LocalizationService().t('numberOfReplicates'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateMetadataFromControllers(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _numberOfPartsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: LocalizationService().t('numberOfParts'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
                onChanged: (_) => _updateMetadataFromControllers(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMetricValue(double? value, {int decimals = 2}) {
    if (value == null) {
      return LocalizationService().t('na');
    }
    return value.toStringAsFixed(decimals);
  }
}
