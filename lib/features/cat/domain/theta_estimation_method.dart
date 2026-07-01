enum ThetaEstimationMethod {
  heuristic,
  newtonRaphson,
  map,
  eap;

  String get label {
    return switch (this) {
      ThetaEstimationMethod.heuristic => 'Heuristic',
      ThetaEstimationMethod.newtonRaphson => 'Newton-Raphson',
      ThetaEstimationMethod.map => 'MAP',
      ThetaEstimationMethod.eap => 'EAP',
    };
  }
}
