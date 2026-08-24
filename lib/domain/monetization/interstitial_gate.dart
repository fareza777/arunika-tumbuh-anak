class InterstitialGate {
  static const _cooldown = Duration(minutes: 10);

  DateTime? _lastShown;
  var _successfulSaves = 0;

  bool canShow(DateTime now) {
    if (_successfulSaves < 3) return false;
    final lastShown = _lastShown;
    if (lastShown == null) return true;
    return now.difference(lastShown) >= _cooldown;
  }

  void recordShown(DateTime now) {
    _lastShown = now;
    _successfulSaves = 0;
  }

  void recordMeasurementSaved() {
    if (_successfulSaves < 3) {
      _successfulSaves++;
    }
  }
}
