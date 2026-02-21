/// Metadata für MSA-Analyse (Part, Measurement System, Analysis Info)
class AnalysisMetadata {
  // Part Information
  final String? partNumber;
  final String? partName;
  final String? drawingReference;
  final double? upperSpecLimit; // USL
  final double? lowerSpecLimit; // LSL

  // Measurement System Information
  final String? instrumentName;
  final String? instrumentId;
  final String? calibrationStatus;
  final DateTime? calibrationDate;

  // Analysis Metadata
  final String? customer;
  final String? company;
  final String? department;
  final String? analyzedBy;
  final String? reviewedBy;
  final String? machine;
  final String? processOrOperation;
  final String? measurementProcedure;
  final String? samplingPlan;
  final double? temperature;
  final double? humidity;

  // Analysis Setup
  final int? numberOfOperators;
  final int? numberOfReplicates;
  final int? numberOfParts;

  AnalysisMetadata({
    // Part Information
    this.partNumber,
    this.partName,
    this.drawingReference,
    this.upperSpecLimit,
    this.lowerSpecLimit,
    // Measurement System Information
    this.instrumentName,
    this.instrumentId,
    this.calibrationStatus,
    this.calibrationDate,
    // Analysis Metadata
    this.customer,
    this.company,
    this.department,
    this.analyzedBy,
    this.reviewedBy,
    this.machine,
    this.processOrOperation,
    this.measurementProcedure,
    this.samplingPlan,
    this.temperature,
    this.humidity,
    // Analysis Setup
    this.numberOfOperators,
    this.numberOfReplicates,
    this.numberOfParts,
  });

  /// Helper method to get tolerance range
  double? get tolerance {
    if (upperSpecLimit != null && lowerSpecLimit != null) {
      return upperSpecLimit! - lowerSpecLimit!;
    }
    return null;
  }

  /// Helper method to get nominal value
  double? get nominal {
    if (upperSpecLimit != null && lowerSpecLimit != null) {
      return (upperSpecLimit! + lowerSpecLimit!) / 2;
    }
    return null;
  }

  /// Check if critical metadata is provided
  bool hasRequiredInfo() {
    return partNumber != null && partName != null && analyzedBy != null;
  }

  /// Get summary for display
  String getSummary() {
    final buffer = StringBuffer();
    if (partNumber != null) buffer.writeln('Teil-Nr.: $partNumber');
    if (partName != null) buffer.writeln('Teil-Name: $partName');
    if (instrumentName != null) buffer.writeln('Messmittel: $instrumentName');
    if (customer != null) buffer.writeln('Kunde: $customer');
    if (analyzedBy != null) buffer.writeln('Analysiert von: $analyzedBy');
    if (company != null) buffer.writeln('Unternehmen: $company');
    if (measurementProcedure != null) {
      buffer.writeln('Messverfahren: $measurementProcedure');
    }
    if (samplingPlan != null) buffer.writeln('Stichprobenplan: $samplingPlan');
    return buffer.toString();
  }
}
