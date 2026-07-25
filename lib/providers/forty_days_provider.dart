import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../models/forty_days_model.dart';

class FortyDaysProvider with ChangeNotifier {
  FortyDaysState? _state;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _autoCheckInSuccessMessage;

  String? get autoCheckInSuccessMessage => _autoCheckInSuccessMessage;

  void clearAutoCheckInSuccessMessage() {
    _autoCheckInSuccessMessage = null;
  }

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
      history: const [],
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
        final updatedHistory = List<DailyProgress>.from(_state!.history);
        updatedHistory.add(DailyProgress(
          dayIndex: _state!.currentDayIndex,
          date: lastUpdated,
          completedPrayers: _state!.todaysPrayers.keys.toList(),
        ));
        
        if (_state!.currentDayIndex < 39) {
          _state = FortyDaysState(
            startDate: _state!.startDate,
            currentDayIndex: _state!.currentDayIndex + 1,
            todaysPrayers: _createEmptyPrayers(),
            savedMosques: _state!.savedMosques,
            mosqueLocation: _state!.mosqueLocation,
            history: updatedHistory,
            lastUpdatedDate: now,
          );
        }
      } else {
        // Failed the challenge, restart!
        _state = FortyDaysState(
          startDate: now,
          currentDayIndex: 0,
          todaysPrayers: _createEmptyPrayers(),
          savedMosques: _state!.savedMosques,
          mosqueLocation: _state!.mosqueLocation,
          history: const [],
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

  Future<void> markPrayerCompleted(String prayerName, {bool byGps = false, String? mosqueName}) async {
    if (_state == null) return;
    
    final currentPrayers = Map<String, PrayerLog>.from(_state!.todaysPrayers);
    currentPrayers[prayerName] = PrayerLog(
      prayerName: prayerName,
      isCompleted: true,
      completedAt: DateTime.now(),
      mosqueName: mosqueName,
      verifiedByGps: byGps,
    );

    _state = FortyDaysState(
      startDate: _state!.startDate,
      currentDayIndex: _state!.currentDayIndex,
      todaysPrayers: currentPrayers,
      savedMosques: _state!.savedMosques,
      mosqueLocation: _state!.mosqueLocation,
      history: _state!.history,
      lastUpdatedDate: DateTime.now(),
    );
    
    await _saveState();
  }

  Future<void> saveMosqueLocation(String name) async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      if (_state != null) {
        final updatedMosques = List<SavedMosque>.from(_state!.savedMosques);
        updatedMosques.removeWhere((m) => m.name.trim().toLowerCase() == name.trim().toLowerCase());
        updatedMosques.add(SavedMosque(
          name: name.trim(),
          latitude: position.latitude,
          longitude: position.longitude,
        ));

        _state = FortyDaysState(
          startDate: _state!.startDate,
          currentDayIndex: _state!.currentDayIndex,
          todaysPrayers: _state!.todaysPrayers,
          savedMosques: updatedMosques,
          mosqueLocation: _state!.mosqueLocation,
          history: _state!.history,
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

  Future<void> deleteMosque(String name) async {
    if (_state == null) return;
    
    final updatedMosques = List<SavedMosque>.from(_state!.savedMosques);
    updatedMosques.removeWhere((m) => m.name == name);

    _state = FortyDaysState(
      startDate: _state!.startDate,
      currentDayIndex: _state!.currentDayIndex,
      todaysPrayers: _state!.todaysPrayers,
      savedMosques: updatedMosques,
      mosqueLocation: _state!.mosqueLocation,
      history: _state!.history,
      lastUpdatedDate: _state!.lastUpdatedDate,
    );
    await _saveState();
  }

  Future<SavedMosque?> verifyLocationWithGps() async {
    if (_state == null || _state!.savedMosques.isEmpty) {
      _errorMessage = 'لم يتم حفظ أي موقع مسجد مسبقاً.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      double minDistance = double.infinity;
      SavedMosque? closestMosque;
      
      for (var mosque in _state!.savedMosques) {
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          mosque.latitude, mosque.longitude
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestMosque = mosque;
        }
      }

      if (minDistance <= 150 && closestMosque != null) {
        return closestMosque;
      } else {
        final name = closestMosque?.name ?? '';
        _errorMessage = 'أنت لست قريباً من أي مسجد محفوظ. (أقرب مسجد: $name على بعد ${minDistance.toStringAsFixed(0)} متر)';
        return null;
      }
    } catch (e) {
      _errorMessage = 'خطأ في التحقق من الموقع: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetChallenge() async {
    _initializeNewChallenge();
  }

  Future<SavedMosque?> _verifyLocationGpsSilently() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 4));
      
      double minDistance = double.infinity;
      SavedMosque? closestMosque;
      
      for (var mosque in _state!.savedMosques) {
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          mosque.latitude, mosque.longitude
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestMosque = mosque;
        }
      }

      if (minDistance <= 150 && closestMosque != null) {
        return closestMosque;
      }
    } catch (_) {}
    return null;
  }

  Future<void> runAutomaticGpsCheckIn({
    required PrayerTimes prayerTimes,
  }) async {
    if (_isLoading || _state == null || _state!.savedMosques.isEmpty) return;

    final now = DateTime.now();
    
    final challengePrayers = {
      'الفجر': {
        'time': prayerTimes.fajr,
        'window': 5,
      },
      'الظهر': {
        'time': prayerTimes.dhuhr,
        'window': 5,
      },
      'العصر': {
        'time': prayerTimes.asr,
        'window': 5,
      },
      'المغرب': {
        'time': prayerTimes.maghrib,
        'window': 1,
      },
      'العشاء': {
        'time': prayerTimes.isha,
        'window': 5,
      },
    };

    String? activePrayerName;

    for (var entry in challengePrayers.entries) {
      final pName = entry.key;
      final pTime = entry.value['time'] as DateTime;
      final window = entry.value['window'] as int;

      final diffSeconds = now.difference(pTime).inSeconds;
      if (diffSeconds >= 0 && diffSeconds <= (window * 60)) {
        final log = _state!.todaysPrayers[pName];
        if (log == null || !log.isCompleted) {
          activePrayerName = pName;
          break;
        }
      }
    }

    if (activePrayerName == null) return;

    final matchedMosque = await _verifyLocationGpsSilently();
    if (matchedMosque != null) {
      await markPrayerCompleted(activePrayerName, byGps: true, mosqueName: matchedMosque.name);
      _autoCheckInSuccessMessage = 'تم إثبات صلاة $activePrayerName جماعة تلقائياً في مسجد "${matchedMosque.name}"! 🎉';
      notifyListeners();
    }
  }
}
