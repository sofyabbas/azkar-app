import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/forty_days_model.dart';

class FortyDaysProvider with ChangeNotifier {
  FortyDaysState? _state;
  bool _isLoading = true;
  String _errorMessage = '';

  FortyDaysState? get state => _state;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  FortyDaysProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('fortyDaysState');
      if (dataStr != null) {
        _state = FortyDaysState.fromJson(json.decode(dataStr));
        _checkDayRollover();
      } else {
        _initializeNewChallenge();
      }
    } catch (e) {
      _errorMessage = 'Error loading challenge data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeNewChallenge() {
    _state = FortyDaysState(
      startDate: DateTime.now(),
      currentDayIndex: 0,
      todaysPrayers: _createEmptyPrayers(),
      lastUpdatedDate: DateTime.now(),
    );
    _saveState();
  }

  Map<String, PrayerLog> _createEmptyPrayers() {
    return {
      'الفجر': PrayerLog(prayerName: 'الفجر'),
      'الظهر': PrayerLog(prayerName: 'الظهر'),
      'العصر': PrayerLog(prayerName: 'العصر'),
      'المغرب': PrayerLog(prayerName: 'المغرب'),
      'العشاء': PrayerLog(prayerName: 'العشاء'),
    };
  }

  void _checkDayRollover() {
    if (_state == null) return;
    
    final now = DateTime.now();
    final lastUpdated = _state!.lastUpdatedDate ?? _state!.startDate;
    
    if (now.day != lastUpdated.day || now.month != lastUpdated.month || now.year != lastUpdated.year) {
      // It's a new day! Check if yesterday was completed.
      bool allCompleted = _state!.todaysPrayers.values.every((p) => p.isCompleted);
      
      if (allCompleted) {
        if (_state!.currentDayIndex < 39) {
          _state = FortyDaysState(
            startDate: _state!.startDate,
            currentDayIndex: _state!.currentDayIndex + 1,
            todaysPrayers: _createEmptyPrayers(),
            mosqueLocation: _state!.mosqueLocation,
            lastUpdatedDate: now,
          );
        }
      } else {
        // Failed the challenge, restart!
        _state = FortyDaysState(
          startDate: now,
          currentDayIndex: 0,
          todaysPrayers: _createEmptyPrayers(),
          mosqueLocation: _state!.mosqueLocation,
          lastUpdatedDate: now,
        );
      }
      _saveState();
    }
  }

  Future<void> _saveState() async {
    if (_state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fortyDaysState', json.encode(_state!.toJson()));
    notifyListeners();
  }

  Future<void> markPrayerCompleted(String prayerName, {bool byGps = false}) async {
    if (_state == null) return;
    
    final currentPrayers = Map<String, PrayerLog>.from(_state!.todaysPrayers);
    currentPrayers[prayerName] = PrayerLog(
      prayerName: prayerName,
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    _state = FortyDaysState(
      startDate: _state!.startDate,
      currentDayIndex: _state!.currentDayIndex,
      todaysPrayers: currentPrayers,
      mosqueLocation: _state!.mosqueLocation,
      lastUpdatedDate: DateTime.now(),
    );
    
    await _saveState();
  }

  Future<void> saveMosqueLocation() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition();
      
      if (_state != null) {
        _state = FortyDaysState(
          startDate: _state!.startDate,
          currentDayIndex: _state!.currentDayIndex,
          todaysPrayers: _state!.todaysPrayers,
          mosqueLocation: [position.latitude, position.longitude],
          lastUpdatedDate: _state!.lastUpdatedDate,
        );
        await _saveState();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyLocationWithGps() async {
    if (_state == null || _state!.mosqueLocation.isEmpty) {
      _errorMessage = 'لم يتم حفظ موقع المسجد مسبقاً.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        _state!.mosqueLocation[0], _state!.mosqueLocation[1]
      );

      if (distanceInMeters <= 150) {
        return true;
      } else {
        _errorMessage = 'أنت لست قريباً من المسجد المحفوظ. (المسافة: ${distanceInMeters.toStringAsFixed(0)} متر)';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ في التحقق من الموقع: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetChallenge() async {
    _initializeNewChallenge();
  }
}
