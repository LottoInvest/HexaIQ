enum CalibrationState { notCalibrated, calibrating, stable }

extension CalibrationStateInfo on CalibrationState {
  String get label {
    return switch (this) {
      CalibrationState.notCalibrated => 'Not Calibrated',
      CalibrationState.calibrating => 'Calibrating',
      CalibrationState.stable => 'Stable',
    };
  }
}
