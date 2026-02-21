import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/msa_result.dart';
import '../models/measurement_data.dart';
import '../models/analysis_metadata.dart';

/// Service für PDF-Export von MSA-Analyseergebnissen
class PdfExportService {
  /// Erstellt ein professionelles PDF mit den MSA-Analyseergebnissen
  static Future<String> generatePdfReport({
    required MsaType1Result result,
    List<MeasurementData>? measurements,
    String? fileName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(result),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTitleSection(),
          pw.SizedBox(height: 20),
          if (result.metadata != null) ...[
            _buildMetadataSection(result.metadata!),
            pw.SizedBox(height: 20),
          ],
          _buildStatisticsSection(result),
          pw.SizedBox(height: 20),
          _buildMsaSection(result),
          pw.SizedBox(height: 20),
          // New advanced parameters
          _buildDiscriminationSection(result),
          pw.SizedBox(height: 20),
          _buildConfidenceIntervalsSection(result),
          pw.SizedBox(height: 20),
          _buildProcessCapabilitySection(result),
          pw.SizedBox(height: 20),
          _buildSuitabilitySection(result),
          if (result.stabilityCheck != null) ...[
            pw.SizedBox(height: 20),
            _buildStabilitySection(result),
          ],
          if (measurements != null && measurements.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildMeasurementTable(measurements),
          ],
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = fileName ?? 'MSA_Analysis_$timestamp.pdf';
    final filePath = '${directory.path}/$filename';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  static pw.Widget _buildHeader(MsaType1Result result) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blue,
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MSA Typ 1 - Messsystemanalyse',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.Text(
                'AIAG Standard',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Stichprobenumfang: ${result.sampleCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey400,
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MSA Type 1 - Measurement System Analysis',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
          pw.Text(
            'Seite ${context.pageNumber} von ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitleSection() {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bericht: MSA Typ 1 Messsystemanalyse',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Messsystemanalyse nach AIAG Standard (Automotive Industry Action Group)',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatisticsSection(MsaType1Result result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Statistische Grundlagen',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Parameter',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Wert',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Stichprobenumfang (n)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('${result.sampleCount}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Mittelwert (μ)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.mean.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Standardabweichung (σ)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.standardDeviation.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Minimum',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.min.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Maximum',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.max.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMsaSection(MsaType1Result result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Messsystemparameter',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Parameter',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Wert',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Wiederholbarkeit (σ)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.repeatability.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Study Variation (6σ)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.studyVariation.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('%Study Variation (%TV)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                        '${(result.percentStudyVariation * 100).toStringAsFixed(2)}%',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              if (result.bias != null)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('Bias (Abweichung)',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(result.bias!.toStringAsFixed(6),
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSuitabilitySection(MsaType1Result result) {
    final String statusText = switch (result.suitability) {
      MsaSuitability.suitable => 'GEEIGNET',
      MsaSuitability.marginal => 'BEDINGT GEEIGNET',
      MsaSuitability.notSuitable => 'NICHT GEEIGNET',
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AIAG-Bewertung',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            statusText,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            result.interpretation,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStabilitySection(MsaType1Result result) {
    final stabilityCheck = result.stabilityCheck!;
    final hasTrend = stabilityCheck['hasTrend'] as bool;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Stabilitätsprüfung',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Parameter',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Wert',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Trend erkannt',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(hasTrend ? 'Ja' : 'Nein',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Trendsteigung',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                        '${(stabilityCheck['trendSlope'] as double).toStringAsFixed(6)}',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('R² (Bestimmtheitsmaß)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                        '${((stabilityCheck['r_squared'] as double) * 100).toStringAsFixed(2)}%',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMeasurementTable(List<MeasurementData> measurements) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Messdaten-Übersicht (erste 20 Messungen)',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.blue),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'ID',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'd (Abstand)',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Δx',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    'Δy',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
            ...measurements.take(20).map(
                  (m) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${m.id}',
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(m.distance.toStringAsFixed(6),
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(m.deltaX.toStringAsFixed(6),
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(m.deltaY.toStringAsFixed(6),
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                ),
            if (measurements.length > 20)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child:
                        pw.Text('...', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                        '${measurements.length - 20} weitere Messungen',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('', style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('', style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMetadataSection(AnalysisMetadata metadata) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Analyse Informationen & Traceability',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Teil-Information',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (metadata.partNumber != null) ...[
                      pw.Text(
                        'Teilnummer: ${metadata.partNumber}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.partName != null) ...[
                      pw.Text(
                        'Teilname: ${metadata.partName}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.drawingReference != null) ...[
                      pw.Text(
                        'Zeichnungsreferenz: ${metadata.drawingReference}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.tolerance != null) ...[
                      pw.Text(
                        'Toleranz: ±${(metadata.tolerance! / 2).toStringAsFixed(4)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.upperSpecLimit != null &&
                        metadata.lowerSpecLimit != null) ...[
                      pw.Text(
                        'USL: ${metadata.upperSpecLimit!.toStringAsFixed(4)} / LSL: ${metadata.lowerSpecLimit!.toStringAsFixed(4)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Analyse Info',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (metadata.analyzedBy != null) ...[
                      pw.Text(
                        'Analysiert von: ${metadata.analyzedBy}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.reviewedBy != null) ...[
                      pw.Text(
                        'Geprueft von: ${metadata.reviewedBy}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.customer != null) ...[
                      pw.Text(
                        'Kunde: ${metadata.customer}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.company != null) ...[
                      pw.Text(
                        'Unternehmen: ${metadata.company}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.department != null) ...[
                      pw.Text(
                        'Abteilung: ${metadata.department}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.machine != null) ...[
                      pw.Text(
                        'Maschine: ${metadata.machine}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.processOrOperation != null) ...[
                      pw.Text(
                        'Prozess/Operation: ${metadata.processOrOperation}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.measurementProcedure != null) ...[
                      pw.Text(
                        'Messverfahren: ${metadata.measurementProcedure}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.samplingPlan != null) ...[
                      pw.Text(
                        'Stichprobenplan: ${metadata.samplingPlan}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.numberOfOperators != null) ...[
                      pw.Text(
                        'Anzahl Pruefer: ${metadata.numberOfOperators}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.numberOfReplicates != null) ...[
                      pw.Text(
                        'Wiederholungen: ${metadata.numberOfReplicates}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.numberOfParts != null) ...[
                      pw.Text(
                        'Anzahl Teile: ${metadata.numberOfParts}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.temperature != null) ...[
                      pw.Text(
                        'Temperatur: ${metadata.temperature!.toStringAsFixed(1)} C',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.humidity != null) ...[
                      pw.Text(
                        'Feuchte: ${metadata.humidity!.toStringAsFixed(1)}%',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    pw.Text(
                      'Datum: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Messmittel',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (metadata.instrumentName != null) ...[
                      pw.Text(
                        'Messmittel: ${metadata.instrumentName}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.instrumentId != null) ...[
                      pw.Text(
                        'Messmittel-ID: ${metadata.instrumentId}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.calibrationStatus != null) ...[
                      pw.Text(
                        'Kalibrierstatus: ${metadata.calibrationStatus}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    if (metadata.calibrationDate != null) ...[
                      pw.Text(
                        'Kalibrierdatum: ${DateFormat('dd.MM.yyyy').format(metadata.calibrationDate!)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDiscriminationSection(MsaType1Result result) {
    final drText = result.discriminationRatio != null
        ? '${result.discriminationRatio!.toStringAsFixed(2)} (Empfohlen: >= 4)'
        : 'N/A';
    final ndcText = result.numberOfDistinctCategories != null
        ? '${result.numberOfDistinctCategories} (Empfohlen: >= 5)'
        : 'N/A';
    final resolutionText = result.resolutionPercent != null
        ? '${result.resolutionPercent!.toStringAsFixed(2)}%'
        : 'N/A';
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Discrimination & Auflösung (AIAG)',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Parameter',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Wert',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Discrimination Ratio (DR)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child:
                        pw.Text(drText, style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Distinct Categories (NDC)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(ndcText,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Auflösung (% Toleranz)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(resolutionText,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildConfidenceIntervalsSection(MsaType1Result result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Konfidenzintervalle & Kontrollgrenzen',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Parameter',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Wert',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('95% Konfidenzintervall (Untergrenze)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                        result.confidenceIntervalLower.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('95% Konfidenzintervall (Obergrenze)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                        result.confidenceIntervalUpper.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Kontrollgrenze (LCL)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.controlLimitLower.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Kontrollgrenze (UCL)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(result.controlLimitUpper.toStringAsFixed(6),
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProcessCapabilitySection(MsaType1Result result) {
    final cpText = result.cp != null
        ? '${result.cp!.toStringAsFixed(3)} (Empfohlen: >= 1.33)'
        : 'N/A';
    final cpkText = result.cpk != null
        ? '${result.cpk!.toStringAsFixed(3)} (Empfohlen: >= 1.33)'
        : 'N/A';
    final toleranceUsedText = result.toleranceUsedPercent != null
        ? '${result.toleranceUsedPercent!.toStringAsFixed(2)}%'
        : 'N/A';
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Prozessfähigkeit',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.blue),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Parameter',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Wert',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Cp (Potenzial)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child:
                        pw.Text(cpText, style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Cpk (Tatsächlich)',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(cpkText,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('Toleranznutzung',
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(toleranceUsedText,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
