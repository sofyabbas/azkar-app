import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/forty_days_model.dart';
import '../services/notification_service.dart';

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

  Future<void> setPastDayPrayerStatus(
    int historyIndex,
    String prayerName,
    bool isCompleted, {
    String? mosqueName,
  }) async {
    if (_state == null || historyIndex < 0 || historyIndex >= _state!.history.length) return;

    final updatedHistory = List<DailyProgress>.from(_state!.history);
    final dayProgress = updatedHistory[historyIndex];
    
    final updatedPrayers = Map<String, PrayerLog>.from(dayProgress.prayers);
    
    if (isCompleted) {
      updatedPrayers[prayerName] = PrayerLog(
        prayerName: prayerName,
        isCompleted: true,
        completedAt: DateTime.now(),
        mosqueName: mosqueName?.trim().isEmpty == true ? null : mosqueName?.trim(),
        verifiedByGps: false,
      );
    } else {
      updatedPrayers[prayerName] = PrayerLog(
        prayerName: prayerName,
        isCompleted: false,
      );
    }

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
      // Window is from Adhan (0s) to +45 mins (2700s) after Adhan
      if (diffSeconds >= 0 && diffSeconds <= 2700) {
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
      
      try {
        await NotificationService().showImmediateNotification(
          id: 888,
          title: 'إثبات صلاة تلقائي 🕌',
          body: 'تم إثبات صلاة $activePrayerName جماعة تلقائياً في مسجد "${matchedMosque.name}"',
        );
      } catch (e) {
        debugPrint("Error sending GPS check-in notification: $e");
      }
      
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

  static String normalizeMosqueName(String? name) {
    if (name == null || name.trim().isEmpty) return '';
    String normalized = name.trim();
    
    // Remove trailing periods and commas
    while (normalized.endsWith('.') || normalized.endsWith('،') || normalized.endsWith(',')) {
      normalized = normalized.substring(0, normalized.length - 1).trim();
    }
    
    // Normalize Arabic characters: Alifs, Ta Marbuta, Alif Maqsura
    normalized = normalized
        .replaceAll(RegExp(r'[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        // Remove Arabic tashkeel (diacritics)
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '');
        
    // Normalize multiple spaces to a single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    return normalized.trim();
  }

  Future<void> renameSavedMosque(String oldName, String newName) async {
    if (_state == null) return;
    final cleanOld = oldName.trim();
    final cleanNew = newName.trim();
    if (cleanOld.isEmpty || cleanNew.isEmpty || cleanOld == cleanNew) return;

    // 1. Update in savedMosques
    final updatedMosques = _state!.savedMosques.map((m) {
      if (m.name.trim() == cleanOld) {
        return SavedMosque(name: cleanNew, latitude: m.latitude, longitude: m.longitude);
      }
      return m;
    }).toList();

    // 2. Update in todaysPrayers
    final updatedToday = _state!.todaysPrayers.map((pName, log) {
      if (log.isCompleted && log.mosqueName?.trim() == cleanOld) {
        return MapEntry(
          pName,
          PrayerLog(
            prayerName: log.prayerName,
            isCompleted: log.isCompleted,
            completedAt: log.completedAt,
            mosqueName: cleanNew,
            verifiedByGps: log.verifiedByGps,
          ),
        );
      }
      return MapEntry(pName, log);
    });

    // 3. Update in history
    final updatedHistory = _state!.history.map((progress) {
      final updatedPrayers = progress.prayers.map((pName, log) {
        if (log.isCompleted && log.mosqueName?.trim() == cleanOld) {
          return MapEntry(
            pName,
            PrayerLog(
              prayerName: log.prayerName,
              isCompleted: log.isCompleted,
              completedAt: log.completedAt,
              mosqueName: cleanNew,
              verifiedByGps: log.verifiedByGps,
            ),
          );
        }
        return MapEntry(pName, log);
      });
      return DailyProgress(
        dayIndex: progress.dayIndex,
        date: progress.date,
        prayers: updatedPrayers,
        isSuccess: progress.isSuccess,
      );
    }).toList();

    _state = FortyDaysState(
      startDate: _state!.startDate,
      currentDayIndex: _state!.currentDayIndex,
      todaysPrayers: updatedToday,
      savedMosques: updatedMosques,
      history: updatedHistory,
      lastUpdatedDate: _state!.lastUpdatedDate,
    );

    await _saveState();
  }

  Future<void> updatePrayerMosqueName(String prayerName, String? newMosqueName, {int? historyDayIndex}) async {
    if (_state == null) return;
    
    final cleanName = newMosqueName?.trim().isEmpty == true ? null : newMosqueName?.trim();
    
    if (historyDayIndex == null) {
      // Update today's prayer
      final currentPrayers = Map<String, PrayerLog>.from(_state!.todaysPrayers);
      final log = currentPrayers[prayerName];
      if (log != null && log.isCompleted) {
        currentPrayers[prayerName] = PrayerLog(
          prayerName: log.prayerName,
          isCompleted: log.isCompleted,
          completedAt: log.completedAt,
          mosqueName: cleanName,
          verifiedByGps: log.verifiedByGps,
        );
        _state = FortyDaysState(
          startDate: _state!.startDate,
          currentDayIndex: _state!.currentDayIndex,
          todaysPrayers: currentPrayers,
          savedMosques: _state!.savedMosques,
          history: _state!.history,
          lastUpdatedDate: DateTime.now(),
        );
        await _saveState();
      }
    } else {
      // Update historical prayer
      if (historyDayIndex < 0 || historyDayIndex >= _state!.history.length) return;
      final updatedHistory = List<DailyProgress>.from(_state!.history);
      final progress = updatedHistory[historyDayIndex];
      final updatedPrayers = Map<String, PrayerLog>.from(progress.prayers);
      final log = updatedPrayers[prayerName];
      if (log != null && log.isCompleted) {
        updatedPrayers[prayerName] = PrayerLog(
          prayerName: log.prayerName,
          isCompleted: log.isCompleted,
          completedAt: log.completedAt,
          mosqueName: cleanName,
          verifiedByGps: log.verifiedByGps,
        );
        updatedHistory[historyDayIndex] = DailyProgress(
          dayIndex: progress.dayIndex,
          date: progress.date,
          prayers: updatedPrayers,
          isSuccess: progress.isSuccess,
        );
        _state = FortyDaysState(
          startDate: _state!.startDate,
          currentDayIndex: _state!.currentDayIndex,
          todaysPrayers: _state!.todaysPrayers,
          savedMosques: _state!.savedMosques,
          history: updatedHistory,
          lastUpdatedDate: _state!.lastUpdatedDate,
        );
        await _saveState();
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
