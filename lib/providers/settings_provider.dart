import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static SettingsProvider? _instance;
  static SettingsProvider get instance => _instance!;

  late SharedPreferences _prefs;

  // ─────────────────────────────────────────────
  // FIXED BACKEND LEAK RULES
  // ─────────────────────────────────────────────
  // Backend now uses fixed delta logic:
  // 0–5      = normal
  // 5–10     = leak_detected
  // >10      = critical
  //
  // These are displayed in the app only.
  // They are NOT synced to backend anymore.
  final double normalDeltaMax = 5.0;
  final double leakDeltaMax = 10.0;

  // ─────────────────────────────────────────────
  // NOTIFICATION PREFERENCES
  // ─────────────────────────────────────────────
  bool _criticalAlerts = true;
  bool _leakAlerts = true;
  bool _dailyReport = true;
  bool _soundAlerts = true;

  bool get criticalAlerts => _criticalAlerts;
  bool get leakAlerts => _leakAlerts;
  bool get dailyReport => _dailyReport;
  bool get soundAlerts => _soundAlerts;

  // ─────────────────────────────────────────────
  // DISPLAY SETTINGS
  // ─────────────────────────────────────────────
  String _selectedUnit = 'Liters';
  String _selectedCurrency = 'UGX';
  String _selectedRefreshRate = '5 seconds';
  bool _darkMode = false;

  String get selectedUnit => _selectedUnit;
  String get selectedCurrency => _selectedCurrency;
  String get selectedRefreshRate => _selectedRefreshRate;
  bool get darkMode => _darkMode;

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

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────
  static Future<SettingsProvider> init() async {
    final provider = SettingsProvider();
    provider._prefs = await SharedPreferences.getInstance();

    // Load settings locally only.
    // No backend threshold call here, so app startup is faster.
    provider._loadFromLocal();

    _instance = provider;
    return provider;
  }

  void _loadFromLocal() {
    _criticalAlerts = _prefs.getBool('criticalAlerts') ?? true;
    _leakAlerts = _prefs.getBool('leakAlerts') ?? true;
    _dailyReport = _prefs.getBool('dailyReport') ?? true;
    _soundAlerts = _prefs.getBool('soundAlerts') ?? true;

    _selectedUnit = _prefs.getString('selectedUnit') ?? 'Liters';
    _selectedCurrency = _prefs.getString('selectedCurrency') ?? 'UGX';
    _selectedRefreshRate =
        _prefs.getString('selectedRefreshRate') ?? '5 seconds';
    _darkMode = _prefs.getBool('darkMode') ?? false;
  }

  // ─────────────────────────────────────────────
  // LOCAL SETTINGS SETTERS
  // ─────────────────────────────────────────────
  Future<void> setCriticalAlerts(bool value) async {
    _criticalAlerts = value;
    await _prefs.setBool('criticalAlerts', value);
    notifyListeners();
  }

  Future<void> setLeakAlerts(bool value) async {
    _leakAlerts = value;
    await _prefs.setBool('leakAlerts', value);
    notifyListeners();
  }

  Future<void> setDailyReport(bool value) async {
    _dailyReport = value;
    await _prefs.setBool('dailyReport', value);
    notifyListeners();
  }

  Future<void> setSoundAlerts(bool value) async {
    _soundAlerts = value;
    await _prefs.setBool('soundAlerts', value);
    notifyListeners();
  }

  Future<void> setSelectedUnit(String value) async {
    _selectedUnit = value;
    await _prefs.setString('selectedUnit', value);
    notifyListeners();
  }

  Future<void> setSelectedCurrency(String value) async {
    _selectedCurrency = value;
    await _prefs.setString('selectedCurrency', value);
    notifyListeners();
  }

  Future<void> setSelectedRefreshRate(String value) async {
    _selectedRefreshRate = value;
    await _prefs.setString('selectedRefreshRate', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _prefs.setBool('darkMode', value);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // FORMATTERS
  // ─────────────────────────────────────────────
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

  String formatCurrency(double amount) {
    switch (_selectedCurrency) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'KES':
        return 'KES ${amount.toStringAsFixed(0)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      case 'UGX':
      default:
        return 'UGX ${amount.toStringAsFixed(0)}';
    }
  }

  // ─────────────────────────────────────────────
  // ALERT DISPLAY HELPERS
  // ─────────────────────────────────────────────
  bool shouldAlert(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return _criticalAlerts;
      case 'leak_detected':
      case 'leak':
        return _leakAlerts;
      default:
        return false;
    }
  }

  String leakRuleDescription() {
    return 'Normal: 0–5, Leak: 5–10, Critical: above 10';
  }
}