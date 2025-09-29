import 'package:flutter/foundation.dart';

/// Dev-only motion debug state (not persisted).
/// Controls overlays, slow-mo, and markers to aid animation debugging.
class MotionDebug with ChangeNotifier {
  static final MotionDebug instance = MotionDebug._();
  MotionDebug._();

  bool _enabled = false;
  bool _showPerformanceOverlay = false;
  bool _showMarkers = false; // draw start/target markers, paths
  double _timeDilation = 1.0; // 1.0 normal, >1.0 slow
  bool _logFrameTimings = false;

  bool get enabled => _enabled && kDebugMode;
  bool get showPerformanceOverlay => _showPerformanceOverlay && enabled;
  bool get showMarkers => _showMarkers && enabled;
  double get timeDilation => _timeDilation;
  bool get logFrameTimings => _logFrameTimings && enabled;

  void toggleEnabled() {
    _enabled = !_enabled;
    notifyListeners();
  }

  void setEnabled(bool v) {
    _enabled = v;
    notifyListeners();
  }

  void setShowPerformanceOverlay(bool v) {
    _showPerformanceOverlay = v;
    notifyListeners();
  }

  void setShowMarkers(bool v) {
    _showMarkers = v;
    notifyListeners();
  }

  void setTimeDilation(double v) {
    _timeDilation = v.clamp(0.1, 10.0);
    notifyListeners();
  }

  void setLogFrameTimings(bool v) {
    _logFrameTimings = v;
    notifyListeners();
  }
}
