enum GpsAccuracyClass { precise, fair, poor }

GpsAccuracyClass classifyGpsAccuracy(double? accuracyMeters) {
  if (accuracyMeters == null || !accuracyMeters.isFinite) {
    return GpsAccuracyClass.poor;
  }
  if (accuracyMeters <= 10) return GpsAccuracyClass.precise;
  if (accuracyMeters <= 30) return GpsAccuracyClass.fair;
  return GpsAccuracyClass.poor;
}
