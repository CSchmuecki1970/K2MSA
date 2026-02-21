import 'dart:convert';
import 'analysis_metadata.dart';
import 'msa_result.dart';
import 'analysis_mode.dart';
import 'measurement_data.dart';
import 'coordinate_point.dart';

/// Complete analysis package for saving/loading to JSON
class AnalysisSavePackage {
  final DateTime createdAt;
  final String? analysisName;
  final List<MeasurementData> measurements;
  final AnalysisMetadata? metadata;
  final MsaType1Result? result;

  AnalysisSavePackage({
    required this.createdAt,
    this.analysisName,
    required this.measurements,
    this.metadata,
    this.result,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'analysisName': analysisName,
      'measurements': measurements.map((m) => _measurementToJson(m)).toList(),
      'metadata': metadata != null ? _metadataToJson(metadata!) : null,
      'result': result != null ? _resultToJson(result!) : null,
    };
  }

  /// Convert from JSON map
  factory AnalysisSavePackage.fromJson(Map<String, dynamic> json) {
    return AnalysisSavePackage(
      createdAt: DateTime.parse(json['createdAt'] as String),
      analysisName: json['analysisName'] as String?,
      measurements: (json['measurements'] as List)
          .map((m) => _measurementFromJson(m as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] != null
          ? _metadataFromJson(json['metadata'] as Map<String, dynamic>)
          : null,
      result: json['result'] != null
          ? _resultFromJson(json['result'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Convert from JSON string
  factory AnalysisSavePackage.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return AnalysisSavePackage.fromJson(json);
  }

  /// Helper to convert measurement to JSON
  static Map<String, dynamic> _measurementToJson(MeasurementData measurement) {
    return {
      'id': measurement.id,
      'point1_x': measurement.point1.x,
      'point1_y': measurement.point1.y,
      'point2_x': measurement.point2.x,
      'point2_y': measurement.point2.y,
      'distance': measurement.distance,
      'deltaX': measurement.deltaX,
      'deltaY': measurement.deltaY,
      'timestamp': measurement.timestamp?.toIso8601String(),
    };
  }

  /// Helper to convert measurement from JSON
  static MeasurementData _measurementFromJson(Map<String, dynamic> json) {
    return MeasurementData(
      id: json['id'] as int,
      point1: CoordinatePoint(
        x: json['point1_x'] as double,
        y: json['point1_y'] as double,
      ),
      point2: CoordinatePoint(
        x: json['point2_x'] as double,
        y: json['point2_y'] as double,
      ),
      distance: json['distance'] as double,
      deltaX: json['deltaX'] as double,
      deltaY: json['deltaY'] as double,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// Helper to convert metadata to JSON
  static Map<String, dynamic> _metadataToJson(AnalysisMetadata metadata) {
    return {
      'partNumber': metadata.partNumber,
      'partName': metadata.partName,
      'drawingReference': metadata.drawingReference,
      'upperSpecLimit': metadata.upperSpecLimit,
      'lowerSpecLimit': metadata.lowerSpecLimit,
      'instrumentName': metadata.instrumentName,
      'instrumentId': metadata.instrumentId,
      'calibrationStatus': metadata.calibrationStatus,
      'calibrationDate': metadata.calibrationDate?.toIso8601String(),
      'customer': metadata.customer,
      'company': metadata.company,
      'department': metadata.department,
      'analyzedBy': metadata.analyzedBy,
      'reviewedBy': metadata.reviewedBy,
      'machine': metadata.machine,
      'processOrOperation': metadata.processOrOperation,
      'measurementProcedure': metadata.measurementProcedure,
      'samplingPlan': metadata.samplingPlan,
      'temperature': metadata.temperature,
      'humidity': metadata.humidity,
      'numberOfOperators': metadata.numberOfOperators,
      'numberOfReplicates': metadata.numberOfReplicates,
      'numberOfParts': metadata.numberOfParts,
    };
  }

  /// Helper to convert metadata from JSON
  static AnalysisMetadata _metadataFromJson(Map<String, dynamic> json) {
    return AnalysisMetadata(
      partNumber: json['partNumber'] as String?,
      partName: json['partName'] as String?,
      drawingReference: json['drawingReference'] as String?,
      upperSpecLimit: json['upperSpecLimit'] as double?,
      lowerSpecLimit: json['lowerSpecLimit'] as double?,
      instrumentName: json['instrumentName'] as String?,
      instrumentId: json['instrumentId'] as String?,
      calibrationStatus: json['calibrationStatus'] as String?,
      calibrationDate: json['calibrationDate'] != null
          ? DateTime.parse(json['calibrationDate'] as String)
          : null,
      customer: json['customer'] as String?,
      company: json['company'] as String?,
      department: json['department'] as String?,
      analyzedBy: json['analyzedBy'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      machine: json['machine'] as String?,
      processOrOperation: json['processOrOperation'] as String?,
      measurementProcedure: json['measurementProcedure'] as String?,
      samplingPlan: json['samplingPlan'] as String?,
      temperature: json['temperature'] as double?,
      humidity: json['humidity'] as double?,
      numberOfOperators: json['numberOfOperators'] as int?,
      numberOfReplicates: json['numberOfReplicates'] as int?,
      numberOfParts: json['numberOfParts'] as int?,
    );
  }

  /// Helper to convert result to JSON
  static Map<String, dynamic> _resultToJson(MsaType1Result result) {
    return {
      'mode': result.mode.toString(),
      'mean': result.mean,
      'standardDeviation': result.standardDeviation,
      'min': result.min,
      'max': result.max,
      'sampleCount': result.sampleCount,
      'repeatability': result.repeatability,
      'bias': result.bias,
      'studyVariation': result.studyVariation,
      'percentStudyVariation': result.percentStudyVariation,
      'discriminationRatio': result.discriminationRatio,
      'numberOfDistinctCategories': result.numberOfDistinctCategories,
      'resolutionPercent': result.resolutionPercent,
      'confidenceIntervalLower': result.confidenceIntervalLower,
      'confidenceIntervalUpper': result.confidenceIntervalUpper,
      'controlLimitLower': result.controlLimitLower,
      'controlLimitUpper': result.controlLimitUpper,
      'cp': result.cp,
      'cpk': result.cpk,
      'toleranceUsedPercent': result.toleranceUsedPercent,
      'suitability': result.suitability.toString(),
      'interpretation': result.interpretation,
    };
  }

  /// Helper to convert result from JSON
  static MsaType1Result _resultFromJson(Map<String, dynamic> json) {
    // Parse the mode enum
    final modeStr = json['mode'] as String;
    final mode = AnalysisMode.values.firstWhere(
      (e) => e.toString() == modeStr,
      orElse: () => AnalysisMode.oneD,
    );

    // Parse the suitability enum
    final suitabilityStr = json['suitability'] as String;
    final suitability = MsaSuitability.values.firstWhere(
      (e) => e.toString() == suitabilityStr,
      orElse: () => MsaSuitability.notSuitable,
    );

    return MsaType1Result(
      mode: mode,
      mean: json['mean'] as double? ?? 0.0,
      standardDeviation: json['standardDeviation'] as double? ?? 0.0,
      min: json['min'] as double? ?? 0.0,
      max: json['max'] as double? ?? 0.0,
      sampleCount: json['sampleCount'] as int? ?? 0,
      repeatability: json['repeatability'] as double? ?? 0.0,
      bias: json['bias'] as double?,
      studyVariation: json['studyVariation'] as double? ?? 0.0,
      percentStudyVariation: json['percentStudyVariation'] as double? ?? 0.0,
      discriminationRatio: json['discriminationRatio'] as double?,
      numberOfDistinctCategories: json['numberOfDistinctCategories'] as int?,
      resolutionPercent: json['resolutionPercent'] as double?,
      confidenceIntervalLower:
          json['confidenceIntervalLower'] as double? ?? 0.0,
      confidenceIntervalUpper:
          json['confidenceIntervalUpper'] as double? ?? 0.0,
      controlLimitLower: json['controlLimitLower'] as double? ?? 0.0,
      controlLimitUpper: json['controlLimitUpper'] as double? ?? 0.0,
      cp: json['cp'] as double?,
      cpk: json['cpk'] as double?,
      toleranceUsedPercent: json['toleranceUsedPercent'] as double?,
      suitability: suitability,
      interpretation: json['interpretation'] as String? ?? '',
    );
  }
}
