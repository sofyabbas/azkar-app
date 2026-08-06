import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forty_days_model.dart';

class FortyDaysProvider with ChangeNotifier {
  FortyDaysState? _state;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _autoCheckInSuccessMessage;
  
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;

  User? get currentUser => _currentUser;

  String? get autoCheckInSuccessMessage => _autoCheckInSuccessMessage;

  void clearAutoCheckInSuccessMessage() {
    _autoCheckInSuccessMessage = null;
  }

  FortyDaysState? get state => _state;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  FortyDaysProvider() {
    _loadState();
    _setupAuthListener();
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
      
      final updatedHistory = List<DailyProgress>.from(_state!.history);
      updatedHistory.add(DailyProgress(
        dayIndex: _state!.currentDayIndex,
        date: lastUpdated,
        prayers: _state!.todaysPrayers,
        isSuccess: allCompleted,
      ));
      
      _state = FortyDaysState(
        startDate: _state!.startDate,
        currentDayIndex: updatedHistory.length,
        todaysPrayers: _createEmptyPrayers(),
        savedMosques: _state!.savedMosques,
        mosqueLocation: _state!.mosqueLocation,
        history: updatedHistory,
        lastUpdatedDate: now,
      );
      _saveState();
    }
  }

  Future<void> _saveState() async {
    if (_state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fortyDaysState', json.encode(_state!.toJson()));
    
    if (_currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set({'fortyDaysState': _state!.toJson()}, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving fortyDaysState to Firestore: $e");
      }
    }
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

  Future<void> unmarkPrayerCompleted(String prayerName) async {
    if (_state == null) return;
    
    final currentPrayers = Map<String, PrayerLog>.from(_state!.todaysPrayers);
    currentPrayers[prayerName] = PrayerLog(
      prayerName: prayerName,
      isCompleted: false,
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

  Future<void> togglePastDayPrayer(int historyIndex, String prayerName) async {
    if (_state == null || historyIndex < 0 || historyIndex >= _state!.history.length) return;

    final updatedHistory = List<DailyProgress>.from(_state!.history);
    final dayProgress = updatedHistory[historyIndex];
    
    final updatedPrayers = Map<String, PrayerLog>.from(dayProgress.prayers);
    final currentLog = updatedPrayers[prayerName];
    final wasCompleted = currentLog?.isCompleted ?? false;
    
    updatedPrayers[prayerName] = PrayerLog(
      prayerName: prayerName,
      isCompleted: !wasCompleted,
      completedAt: !wasCompleted ? DateTime.now() : null,
      mosqueName: !wasCompleted ? 'تعديل يدوي' : null,
      verifiedByGps: false,
    );

    // Re-evaluate if all 5 prayers are completed
    final allCompleted = updatedPrayers.values.length == 5 && 
        updatedPrayers.values.every((p) => p.isCompleted);

    updatedHistory[historyIndex] = DailyProgress(
      dayIndex: dayProgress.dayIndex,
      date: dayProgress.date,
      prayers: updatedPrayers,
      isSuccess: allCompleted,
    );

    _state = FortyDaysState(
      startDate: _state!.startDate,
      currentDayIndex: _state!.currentDayIndex,
      todaysPrayers: _state!.todaysPrayers,
      savedMosques: _state!.savedMosques,
      mosqueLocation: _state!.mosqueLocation,
      history: updatedHistory,
      lastUpdatedDate: _state!.lastUpdatedDate,
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

  Future<SavedMosque?> verifyLocationGpsSilently() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      // Try fast last known position first
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
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
      }

      // Fallback to active location fetching with 10 seconds timeout and medium accuracy
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));
      
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
      'الفجر': prayerTimes.fajr,
      'الظهر': prayerTimes.dhuhr,
      'العصر': prayerTimes.asr,
      'المغرب': prayerTimes.maghrib,
      'العشاء': prayerTimes.isha,
    };

    String? activePrayerName;

    for (var entry in challengePrayers.entries) {
      final pName = entry.key;
      final pTime = entry.value;

      final diffSeconds = now.difference(pTime).inSeconds;
      // Window is -15 mins (-900s) before Adhan to +45 mins (2700s) after Adhan
      if (diffSeconds >= -900 && diffSeconds <= 2700) {
        final log = _state!.todaysPrayers[pName];
        if (log == null || !log.isCompleted) {
          activePrayerName = pName;
          break;
        }
      }
    }

    if (activePrayerName == null) return;

    final matchedMosque = await verifyLocationGpsSilently();
    if (matchedMosque != null) {
      await markPrayerCompleted(activePrayerName, byGps: true, mosqueName: matchedMosque.name);
      _autoCheckInSuccessMessage = 'تم إثبات صلاة $activePrayerName جماعة تلقائياً في مسجد "${matchedMosque.name}"! 🎉';
      notifyListeners();
    }
  }

  void _setupAuthListener() {
    try {
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
        final bool wasGuest = _currentUser == null && user != null;
        _currentUser = user;

        if (user != null) {
          _syncWithFirestore(wasGuest);
        }
      });
    } catch (e) {
      debugPrint("Firebase Auth not initialized: $e");
    }
  }

  Future<void> _syncWithFirestore(bool wasGuest) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['fortyDaysState'] != null) {
          final cloudState = FortyDaysState.fromJson(data['fortyDaysState']);
          
          if (_state != null) {
            final Map<String, SavedMosque> mergedMosques = {};
            for (var m in _state!.savedMosques) {
              mergedMosques[m.name] = m;
            }
            for (var m in cloudState.savedMosques) {
              mergedMosques[m.name] = m;
            }

            bool useCloudProgress = cloudState.currentDayIndex > _state!.currentDayIndex;
            if (cloudState.currentDayIndex == _state!.currentDayIndex) {
              final cloudCompleted = cloudState.todaysPrayers.values.where((p) => p.isCompleted).length;
              final localCompleted = _state!.todaysPrayers.values.where((p) => p.isCompleted).length;
              if (cloudCompleted > localCompleted) {
                useCloudProgress = true;
              }
            }

            if (useCloudProgress) {
              _state = FortyDaysState(
                startDate: cloudState.startDate,
                currentDayIndex: cloudState.currentDayIndex,
                todaysPrayers: cloudState.todaysPrayers,
                savedMosques: mergedMosques.values.toList(),
                history: cloudState.history,
                lastUpdatedDate: cloudState.lastUpdatedDate,
              );
            } else {
              _state = FortyDaysState(
                startDate: _state!.startDate,
                currentDayIndex: _state!.currentDayIndex,
                todaysPrayers: _state!.todaysPrayers,
                savedMosques: mergedMosques.values.toList(),
                history: _state!.history,
                lastUpdatedDate: _state!.lastUpdatedDate,
              );
            }
          } else {
            _state = cloudState;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fortyDaysState', json.encode(_state!.toJson()));
          await docRef.set({'fortyDaysState': _state!.toJson()}, SetOptions(merge: true));
        } else {
          if (_state != null) {
            await docRef.set({'fortyDaysState': _state!.toJson()}, SetOptions(merge: true));
          }
        }
      } else {
        if (_state != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'fortyDaysState': _state!.toJson()}, SetOptions(merge: true));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error syncing fortyDaysState with Firestore: $e");
    }
  }

  Future<void> syncData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _syncWithFirestore(false);
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء مزامنة البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
