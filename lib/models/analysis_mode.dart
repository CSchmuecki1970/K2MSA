/// Einstufung der Analyse-Modi für MSA
enum AnalysisMode {
  oneD, // 1D: Nur X-Werte (eine Spalte)
  twoD_direct, // 2D direkt: X,Y Wertepaare separat (zwei Spalten)
  twoD_distances // 2D Distanzen: Distances von zwei Punkten (vier Spalten)
}

extension AnalysisModeDescription on AnalysisMode {
  String get description {
    switch (this) {
      case AnalysisMode.oneD:
        return 'Eindimensional (nur X-Werte)';
      case AnalysisMode.twoD_direct:
        return 'Zweidimensional (X, Y direkt)';
      case AnalysisMode.twoD_distances:
        return 'Zweidimensional (Distanzen zwischen Punkten)';
    }
  }

  String get shortDescription {
    switch (this) {
      case AnalysisMode.oneD:
        return '1D';
      case AnalysisMode.twoD_direct:
        return '2D (direkt)';
      case AnalysisMode.twoD_distances:
        return '2D (Distanzen)';
    }
  }
}
