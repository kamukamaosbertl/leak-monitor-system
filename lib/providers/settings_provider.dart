import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  static SettingsProvider? _instance;
  static SettingsProvider get instance => _instance!;

  late SharedPreferences _prefs;

  // ── Alert Thresholds ──────────────────────────────────────────────────────
  double _deltaThreshold = 5.0;
  double _waterLostThreshold = 50.0;
  int _durationThreshold = 10;

  double get deltaThreshold => _deltaThreshold;
  double get waterLostThreshold => _waterLostThreshold;
  int get durationThreshold => _durationThreshold;

  // ── Notifications ─────────────────────────────────────────────────────────
  bool _criticalAlerts = true;
  bool _leakAlerts = true;
  bool _warningAlerts = false;
  bool _dailyReport = true;
  bool _soundAlerts = true;

  bool get criticalAlerts => _criticalAlerts;
  bool get leakAlerts => _leakAlerts;
  bool get warningAlerts => _warningAlerts;
  bool get dailyReport => _dailyReport;
  bool get soundAlerts => _soundAlerts;

  // ── Display & Units ───────────────────────────────────────────────────────
  String _selectedUnit = 'Liters';
  String _selectedCurrency = 'USD';
  String _selectedRefreshRate = '5 seconds';
  bool _darkMode = false;

  String get selectedUnit => _selectedUnit;
  String get selectedCurrency => _selectedCurrency;
  String get selectedRefreshRate => _selectedRefreshRate;
  bool get darkMode => _darkMode;

  /// How many seconds between live data polls.
  int get refreshSeconds {
    switch (_selectedRefreshRate) {
      case '2 seconds':
        return 2;
      case '10 seconds':
        return 10;
      case '30 seconds':
        return 30;
      default:
        return 5;
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<SettingsProvider> init() async {
    final provider = SettingsProvider();
    provider._prefs = await SharedPreferences.getInstance();

    // 1. Load local values first so app starts fast
    provider._loadFromLocal();

    // 2. Then try to sync thresholds from backend
    await provider._syncThresholdsFromBackend();

    _instance = provider;
    return provider;
  }

  // ── Local load ────────────────────────────────────────────────────────────
  void _loadFromLocal() {
    _deltaThreshold = _prefs.getDouble('deltaThreshold') ?? 5.0;
    _waterLostThreshold = _prefs.getDouble('waterLostThreshold') ?? 50.0;
    _durationThreshold = _prefs.getInt('durationThreshold') ?? 10;

    _criticalAlerts = _prefs.getBool('criticalAlerts') ?? true;
    _leakAlerts = _prefs.getBool('leakAlerts') ?? true;
    _warningAlerts = _prefs.getBool('warningAlerts') ?? false;
    _dailyReport = _prefs.getBool('dailyReport') ?? true;
    _soundAlerts = _prefs.getBool('soundAlerts') ?? true;

    _selectedUnit = _prefs.getString('selectedUnit') ?? 'Liters';
    _selectedCurrency = _prefs.getString('selectedCurrency') ?? 'USD';
    _selectedRefreshRate =
        _prefs.getString('selectedRefreshRate') ?? '5 seconds';
    _darkMode = _prefs.getBool('darkMode') ?? false;
  }

  // ── Backend sync for alert thresholds ────────────────────────────────────
  Future<void> _syncThresholdsFromBackend() async {
    try {
      final data = await ApiService.fetchAlertSettings();

      _deltaThreshold =
          (data['delta_threshold'] as num?)?.toDouble() ?? _deltaThreshold;

      _waterLostThreshold =
          (data['water_lost_threshold'] as num?)?.toDouble() ??
          _waterLostThreshold;

      _durationThreshold =
          (data['duration_threshold'] as num?)?.toInt() ?? _durationThreshold;

      // Keep local cache updated too
      await _prefs.setDouble('deltaThreshold', _deltaThreshold);
      await _prefs.setDouble('waterLostThreshold', _waterLostThreshold);
      await _prefs.setInt('durationThreshold', _durationThreshold);

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to sync alert thresholds from backend: $e');
    }
  }

  // ── Threshold setters (local + backend) ──────────────────────────────────
  Future<void> setDeltaThreshold(double v) async {
    _deltaThreshold = v;
    await _prefs.setDouble('deltaThreshold', v);
    notifyListeners();

    try {
      await ApiService.updateAlertSettings(deltaThreshold: v);
    } catch (e) {
      debugPrint('Failed to update delta threshold in backend: $e');
    }
  }

  Future<void> setWaterLostThreshold(double v) async {
    _waterLostThreshold = v;
    await _prefs.setDouble('waterLostThreshold', v);
    notifyListeners();

    try {
      await ApiService.updateAlertSettings(waterLostThreshold: v);
    } catch (e) {
      debugPrint('Failed to update water lost threshold in backend: $e');
    }
  }

  Future<void> setDurationThreshold(int v) async {
    _durationThreshold = v;
    await _prefs.setInt('durationThreshold', v);
    notifyListeners();

    try {
      await ApiService.updateAlertSettings(durationThreshold: v);
    } catch (e) {
      debugPrint('Failed to update duration threshold in backend: $e');
    }
  }

  // ── Other setters (local only for now) ───────────────────────────────────
  Future<void> setCriticalAlerts(bool v) async {
    _criticalAlerts = v;
    await _prefs.setBool('criticalAlerts', v);
    notifyListeners();
  }

  Future<void> setLeakAlerts(bool v) async {
    _leakAlerts = v;
    await _prefs.setBool('leakAlerts', v);
    notifyListeners();
  }

  Future<void> setWarningAlerts(bool v) async {
    _warningAlerts = v;
    await _prefs.setBool('warningAlerts', v);
    notifyListeners();
  }

  Future<void> setDailyReport(bool v) async {
    _dailyReport = v;
    await _prefs.setBool('dailyReport', v);
    notifyListeners();
  }

  Future<void> setSoundAlerts(bool v) async {
    _soundAlerts = v;
    await _prefs.setBool('soundAlerts', v);
    notifyListeners();
  }

  Future<void> setSelectedUnit(String v) async {
    _selectedUnit = v;
    await _prefs.setString('selectedUnit', v);
    notifyListeners();
  }

  Future<void> setSelectedCurrency(String v) async {
    _selectedCurrency = v;
    await _prefs.setString('selectedCurrency', v);
    notifyListeners();
  }

  Future<void> setSelectedRefreshRate(String v) async {
    _selectedRefreshRate = v;
    await _prefs.setString('selectedRefreshRate', v);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    await _prefs.setBool('darkMode', v);
    notifyListeners();
  }

  // ── Helpers used by other screens ────────────────────────────────────────

  /// Convert a raw litre value to the user's preferred unit string.
  String formatVolume(double litres) {
    switch (_selectedUnit) {
      case 'Gallons':
        return '${(litres * 0.264172).toStringAsFixed(1)} gal';
      case 'Cubic meters':
        return '${(litres / 1000).toStringAsFixed(3)} m³';
      default:
        return '${litres.toStringAsFixed(1)} L';
    }
  }

  /// Format a monetary value in the user's preferred currency.
  String formatCurrency(double usdAmount) {
    switch (_selectedCurrency) {
      case 'UGX':
        return 'UGX ${(usdAmount * 3700).toStringAsFixed(0)}';
      case 'EUR':
        return '€${(usdAmount * 0.92).toStringAsFixed(2)}';
      case 'KES':
        return 'KES ${(usdAmount * 130).toStringAsFixed(0)}';
      case 'GBP':
        return '£${(usdAmount * 0.79).toStringAsFixed(2)}';
      default:
        return '\$${usdAmount.toStringAsFixed(2)}';
    }
  }

  /// Returns true if an alert should fire for the given status level.
  /// This is still frontend-side behavior for local UI decisions.
  bool shouldAlert(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return _criticalAlerts;
      case 'leak':
        return _leakAlerts;
      case 'warning':
        return _warningAlerts;
      default:
        return false;
    }
  }

  /// Manual refresh if you ever want to re-pull backend thresholds later.
  Future<void> refreshAlertThresholdsFromBackend() async {
    await _syncThresholdsFromBackend();
  }
}
