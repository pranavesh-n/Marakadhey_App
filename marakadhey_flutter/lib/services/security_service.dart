import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

class SecurityService extends ChangeNotifier {
  static const String _keyPinEnabled = "@marakadhey_screen_pin_enabled_v1";
  static const String _keyUserPin = "@marakadhey_user_screen_pin_v1";
  static const int gracePeriodSeconds = 30;

  bool _isPinEnabled = false;
  String? _savedPin;
  bool _isLocked = false;
  DateTime? _backgroundedAt;

  bool get isPinEnabled => _isPinEnabled && (_savedPin != null && _savedPin!.isNotEmpty);
  bool get hasPinSet => _savedPin != null && _savedPin!.isNotEmpty;
  bool get isLocked => _isLocked;

  SecurityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPinEnabled = prefs.getBool(_keyPinEnabled) ?? false;
      _savedPin = prefs.getString(_keyUserPin);
      
      // When app starts fresh with PIN enabled, require PIN lock
      if (_isPinEnabled && _savedPin != null && _savedPin!.isNotEmpty) {
        _isLocked = true;
      } else {
        _isLocked = false;
      }
    } catch (e) {
      debugPrint("SecurityService init error: $e");
    }
    notifyListeners();
  }

  /// Set a new 4-digit PIN and enable Screen Lock
  Future<bool> setPin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserPin, pin);
      await prefs.setBool(_keyPinEnabled, true);
      _savedPin = pin;
      _isPinEnabled = true;
      // Keep unlocked while currently configuring in settings
      _isLocked = false;
      _backgroundedAt = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Set PIN error: $e");
      return false;
    }
  }

  /// Disable PIN lock completely
  Future<void> disablePin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserPin);
      await prefs.setBool(_keyPinEnabled, false);
      _savedPin = null;
      _isPinEnabled = false;
      _isLocked = false;
      _backgroundedAt = null;
      notifyListeners();
    } catch (e) {
      debugPrint("Disable PIN error: $e");
    }
  }

  /// Called when the app goes into background
  void onAppBackgrounded() {
    if (isPinEnabled) {
      _backgroundedAt = DateTime.now();
    }
  }

  /// Called when the app returns from background
  void onAppResumed() {
    if (isPinEnabled && _backgroundedAt != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!).inSeconds;
      if (elapsed >= gracePeriodSeconds) {
        _isLocked = true;
        notifyListeners();
      }
      _backgroundedAt = null;
    }
  }

  /// Explicitly lock app
  void lock() {
    if (isPinEnabled && !_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Explicitly unlock app (on login / valid PIN)
  void unlock() {
    _isLocked = false;
    _backgroundedAt = null;
    notifyListeners();
  }

  /// Verify entered 4-digit PIN and unlock
  bool verifyAndUnlock(String enteredPin) {
    if (!isPinEnabled) {
      unlock();
      return true;
    }

    if (enteredPin == _savedPin) {
      unlock();
      return true;
    }

    return false;
  }
}
