import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quit_smoking_model.dart';

class QuitSmokingProvider with ChangeNotifier {
  QuitSmokingState? _state;
  bool _isLoading = true;
  String _errorMessage = '';
  
  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;

  QuitSmokingState? get state => _state;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  QuitSmokingProvider() {
    _loadState();
    _setupAuthListener();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('quitSmokingState');
      if (dataStr != null) {
        _state = QuitSmokingState.fromJson(json.decode(dataStr));
      } else {
        _state = QuitSmokingState.empty();
      }
    } catch (e) {
      _errorMessage = 'Error loading smoking data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final bool wasGuest = _currentUser == null && user != null;
      _currentUser = user;

      if (user != null) {
        _syncWithFirestore(wasGuest);
      }
    });
  }

  Future<void> _syncWithFirestore(bool wasGuest) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['quitSmokingState'] != null) {
          final cloudState = QuitSmokingState.fromJson(data['quitSmokingState']);
          
          if (_state != null && _state!.isConfigured) {
            // Merge logs: keep all logs from both
            final Map<String, int> mergedLogs = Map<String, int>.from(_state!.dailyLogs);
            cloudState.dailyLogs.forEach((key, value) {
              if (!mergedLogs.containsKey(key) || value > mergedLogs[key]!) {
                mergedLogs[key] = value;
              }
            });

            // If local is not configured, or cloud has a more recent startDate, or we just merge
            _state = QuitSmokingState(
              startDate: cloudState.startDate.isBefore(_state!.startDate) ? cloudState.startDate : _state!.startDate,
              normalCigarettesPerDay: _state!.isConfigured ? _state!.normalCigarettesPerDay : cloudState.normalCigarettesPerDay,
              yearsOfSmoking: _state!.isConfigured ? _state!.yearsOfSmoking : cloudState.yearsOfSmoking,
              packPrice: _state!.isConfigured ? _state!.packPrice : cloudState.packPrice,
              dailyLogs: mergedLogs,
              isConfigured: _state!.isConfigured || cloudState.isConfigured,
            );
          } else {
            _state = cloudState;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('quitSmokingState', json.encode(_state!.toJson()));
          await docRef.set({'quitSmokingState': _state!.toJson()}, SetOptions(merge: true));
        } else {
          if (_state != null && _state!.isConfigured) {
            await docRef.set({'quitSmokingState': _state!.toJson()}, SetOptions(merge: true));
          }
        }
      } else {
        if (_state != null && _state!.isConfigured) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'quitSmokingState': _state!.toJson()}, SetOptions(merge: true));
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error syncing quitSmokingState with Firestore: $e");
    }
  }

  Future<void> _saveState() async {
    if (_state == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quitSmokingState', json.encode(_state!.toJson()));
    
    if (_currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .set({'quitSmokingState': _state!.toJson()}, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error saving quitSmokingState to Firestore: $e");
      }
    }
    notifyListeners();
  }

  Future<void> configure({
    required int years,
    required int dailyRate,
    required double price,
    required DateTime date,
  }) async {
    _state = QuitSmokingState(
      startDate: date,
      normalCigarettesPerDay: dailyRate,
      yearsOfSmoking: years,
      packPrice: price,
      dailyLogs: _state?.dailyLogs ?? {},
      isConfigured: true,
    );
    await _saveState();
  }

  Future<void> logCigarettes(DateTime date, int count) async {
    if (_state == null) return;
    
    final Map<String, int> updatedLogs = Map<String, int>.from(_state!.dailyLogs);
    final key = _formatDateKey(date);
    
    if (count < 0) count = 0;
    updatedLogs[key] = count;

    _state = QuitSmokingState(
      startDate: _state!.startDate,
      normalCigarettesPerDay: _state!.normalCigarettesPerDay,
      yearsOfSmoking: _state!.yearsOfSmoking,
      packPrice: _state!.packPrice,
      dailyLogs: updatedLogs,
      isConfigured: _state!.isConfigured,
    );

    await _saveState();
  }

  Future<void> resetProgress() async {
    _state = QuitSmokingState.empty();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quitSmokingState');
    
    if (_currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'quitSmokingState': FieldValue.delete()});
      } catch (_) {}
    }
    notifyListeners();
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

  // --- Calculations & Getters ---
  
  double get lungHealth {
    if (_state == null || !_state!.isConfigured) return 1.0;
    
    // 1. Initial damage calculation
    final double totalPastCigarettes = _state!.yearsOfSmoking * 365.0 * _state!.normalCigarettesPerDay;
    // Max damage reached at 50,000 cigarettes, starting health clamp between 5% and 95%
    final double initialHealth = (1.0 - (totalPastCigarettes / 50000.0)).clamp(0.05, 0.95);

    // 2. Calculate days since start date
    final today = DateTime.now();
    final cleanStartDate = DateTime(_state!.startDate.year, _state!.startDate.month, _state!.startDate.day);
    final cleanToday = DateTime(today.year, today.month, today.day);
    
    int totalDays = cleanToday.difference(cleanStartDate).inDays + 1;
    if (totalDays < 1) totalDays = 1;

    int cleanDays = 0;
    int slipUpCigarettes = 0;

    for (int i = 0; i < totalDays; i++) {
      final dateToCheck = cleanStartDate.add(Duration(days: i));
      final dateKey = _formatDateKey(dateToCheck);
      final int smokedCount = _state!.dailyLogs[dateKey] ?? 0;
      
      if (smokedCount == 0) {
        cleanDays++;
      } else {
        slipUpCigarettes += smokedCount;
      }
    }

    // 3. Recovery math: +1.1% per smoke-free day, -1.5% per cigarette smoked as slip-up
    final double healthRecovery = (cleanDays * 0.011) - (slipUpCigarettes * 0.015);
    final double currentHealth = (initialHealth + healthRecovery).clamp(0.0, 1.0);

    return currentHealth;
  }

  int get daysSinceStart {
    if (_state == null || !_state!.isConfigured) return 0;
    final today = DateTime.now();
    final cleanStartDate = DateTime(_state!.startDate.year, _state!.startDate.month, _state!.startDate.day);
    final cleanToday = DateTime(today.year, today.month, today.day);
    final diff = cleanToday.difference(cleanStartDate).inDays + 1;
    return diff < 1 ? 1 : diff;
  }

  int get smokeFreeDays {
    if (_state == null || !_state!.isConfigured) return 0;
    int count = 0;
    final cleanStartDate = DateTime(_state!.startDate.year, _state!.startDate.month, _state!.startDate.day);
    final totalDays = daysSinceStart;
    
    for (int i = 0; i < totalDays; i++) {
      final dateToCheck = cleanStartDate.add(Duration(days: i));
      final dateKey = _formatDateKey(dateToCheck);
      final int smoked = _state!.dailyLogs[dateKey] ?? 0;
      if (smoked == 0) {
        count++;
      }
    }
    return count;
  }

  int get avoidedCigarettes {
    if (_state == null || !_state!.isConfigured) return 0;
    final int wouldHaveSmoked = daysSinceStart * _state!.normalCigarettesPerDay;
    
    int actuallySmoked = 0;
    _state!.dailyLogs.forEach((key, val) {
      try {
        final logDate = DateTime.parse(key);
        final cleanStartDate = DateTime(_state!.startDate.year, _state!.startDate.month, _state!.startDate.day);
        if (!logDate.isBefore(cleanStartDate)) {
          actuallySmoked += val;
        }
      } catch (_) {}
    });

    final diff = wouldHaveSmoked - actuallySmoked;
    return diff < 0 ? 0 : diff;
  }

  double get moneySaved {
    if (_state == null || !_state!.isConfigured) return 0.0;
    final double pricePerCigarette = _state!.packPrice / 20.0;
    return avoidedCigarettes * pricePerCigarette;
  }

  int get lifeMinutesRegained {
    return avoidedCigarettes * 11;
  }

  int get cigarettesSmokedToday {
    if (_state == null || !_state!.isConfigured) return 0;
    final dateKey = _formatDateKey(DateTime.now());
    return _state!.dailyLogs[dateKey] ?? 0;
  }

  int cigarettesSmokedOn(DateTime date) {
    if (_state == null || !_state!.isConfigured) return 0;
    final dateKey = _formatDateKey(date);
    return _state!.dailyLogs[dateKey] ?? 0;
  }

  String _formatDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
