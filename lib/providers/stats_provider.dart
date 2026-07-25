import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryStat {
  int readCount; // عدد مرات إكمال الفئة
  int itemsReadCount; // عدد الأذكار المقروءة
  int timeSpentSeconds; // الوقت بالثواني

  CategoryStat({
    this.readCount = 0,
    this.itemsReadCount = 0,
    this.timeSpentSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
        'readCount': readCount,
        'itemsReadCount': itemsReadCount,
        'timeSpentSeconds': timeSpentSeconds,
      };

  factory CategoryStat.fromJson(Map<String, dynamic> json) => CategoryStat(
        readCount: json['readCount'] ?? 0,
        itemsReadCount: json['itemsReadCount'] ?? 0,
        timeSpentSeconds: json['timeSpentSeconds'] ?? 0,
      );
}

class StatsProvider with ChangeNotifier {
  int _dailyAzkarCount = 0;
  int _fortyDaysCount = 0;
  int _totalTimeSeconds = 0;

  // Streak & Habit Tracking
  int _currentStreak = 0;
  int _longestStreak = 0;
  String _lastActiveDate = '';
  List<String> _activeDates = [];

  Map<String, CategoryStat> _categoryStats = {};

  User? _currentUser;
  bool _hasLoadedAsGuest = false;
  StreamSubscription<User?>? _authSubscription;

  int get totalAzkarCount => _dailyAzkarCount + _fortyDaysCount;
  int get dailyAzkarCount => _dailyAzkarCount;
  int get fortyDaysCount => _fortyDaysCount;
  int get totalTimeSeconds => _totalTimeSeconds;
  Map<String, CategoryStat> get categoryStats => _categoryStats;

  // Streak getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  String get lastActiveDate => _lastActiveDate;
  List<String> get activeDates => _activeDates;

  String get streakBadgeName {
    if (_currentStreak >= 40) return 'حافظ العهد 👑';
    if (_currentStreak >= 30) return 'بطل المواظبة 🏆';
    if (_currentStreak >= 14) return 'محافظ على الأذكار 🥇';
    if (_currentStreak >= 7) return 'ثبات الورد 🥈';
    if (_currentStreak >= 3) return 'مستجد المواظبة 🥉';
    return 'بداية مباركة 🌱';
  }

  StatsProvider() {
    _loadStats();
    _setupAuthListener();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailyAzkarCount = prefs.getInt('stats_dailyAzkarCount') ?? 0;
      _fortyDaysCount = prefs.getInt('stats_fortyDaysCount') ?? 0;
      _totalTimeSeconds = prefs.getInt('stats_totalTimeSeconds') ?? 0;

      // Load streak data
      _currentStreak = prefs.getInt('stats_currentStreak') ?? 0;
      _longestStreak = prefs.getInt('stats_longestStreak') ?? 0;
      _lastActiveDate = prefs.getString('stats_lastActiveDate') ?? '';
      _activeDates = prefs.getStringList('stats_activeDates') ?? [];

      // Validate if streak was broken yesterday
      _checkStreakValidity();

      final String? catJson = prefs.getString('stats_categoryStats');
      if (catJson != null) {
        final Map<String, dynamic> decoded = json.decode(catJson);
        _categoryStats = decoded.map(
          (key, value) => MapEntry(key, CategoryStat.fromJson(value)),
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading stats: $e");
    }
  }

  void _checkStreakValidity() {
    if (_lastActiveDate.isEmpty) return;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastActiveDate == todayStr) return;

    try {
      final lastDate = DateTime.parse(_lastActiveDate);
      final today = DateTime.parse(todayStr);
      final diff = today.difference(lastDate).inDays;

      if (diff > 1) {
        // Streak broken
        _currentStreak = 0;
      }
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stats_dailyAzkarCount', _dailyAzkarCount);
      await prefs.setInt('stats_fortyDaysCount', _fortyDaysCount);
      await prefs.setInt('stats_totalTimeSeconds', _totalTimeSeconds);

      // Save streak data
      await prefs.setInt('stats_currentStreak', _currentStreak);
      await prefs.setInt('stats_longestStreak', _longestStreak);
      await prefs.setString('stats_lastActiveDate', _lastActiveDate);
      await prefs.setStringList('stats_activeDates', _activeDates);

      final Map<String, dynamic> catMap =
          _categoryStats.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString('stats_categoryStats', json.encode(catMap));

      // Sync with Firestore if logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'totalAzkarCount': totalAzkarCount,
          'dailyAzkarCount': _dailyAzkarCount,
          'fortyDaysCount': _fortyDaysCount,
          'totalTimeSeconds': _totalTimeSeconds,
          'currentStreak': _currentStreak,
          'longestStreak': _longestStreak,
          'lastActiveDate': _lastActiveDate,
          'activeDates': _activeDates,
          'categoryStats': catMap,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving stats: $e");
    }
  }

  /// Record daily activity & streak
  void recordDailyActivity() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastActiveDate == todayStr) {
      return; // Already logged today
    }

    if (_lastActiveDate.isNotEmpty) {
      try {
        final lastDate = DateTime.parse(_lastActiveDate);
        final today = DateTime.parse(todayStr);
        final diff = today.difference(lastDate).inDays;

        if (diff == 1) {
          _currentStreak += 1;
        } else {
          _currentStreak = 1;
        }
      } catch (_) {
        _currentStreak = 1;
      }
    } else {
      _currentStreak = 1;
    }

    _lastActiveDate = todayStr;
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    if (!_activeDates.contains(todayStr)) {
      _activeDates.add(todayStr);
    }

    _saveStats();
    notifyListeners();
  }

  /// Increment zikr count
  void recordZikrRead({String? categoryId, int count = 1, bool isFortyDays = false}) {
    recordDailyActivity();

    if (isFortyDays) {
      _fortyDaysCount += count;
    } else {
      _dailyAzkarCount += count;
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      final stat = _categoryStats.putIfAbsent(categoryId, () => CategoryStat());
      stat.itemsReadCount += count;
    }

    _saveStats();
    notifyListeners();
  }

  /// Record category completion
  void recordCategoryCompleted(String categoryId) {
    recordDailyActivity();
    final stat = _categoryStats.putIfAbsent(categoryId, () => CategoryStat());
    stat.readCount += 1;
    _saveStats();
    notifyListeners();
  }

  /// Record time spent reading azkar in seconds
  void recordTimeSpent({String? categoryId, int seconds = 1}) {
    recordDailyActivity();
    _totalTimeSeconds += seconds;
    if (categoryId != null && categoryId.isNotEmpty) {
      final stat = _categoryStats.putIfAbsent(categoryId, () => CategoryStat());
      stat.timeSpentSeconds += seconds;
    }
    _saveStats();
    notifyListeners();
  }

  /// Check if a specific DateTime was active
  bool isDateActive(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _activeDates.contains(dateStr);
  }

  /// Reset all statistics
  Future<void> resetStats() async {
    _dailyAzkarCount = 0;
    _fortyDaysCount = 0;
    _totalTimeSeconds = 0;
    _currentStreak = 0;
    _longestStreak = 0;
    _lastActiveDate = '';
    _activeDates.clear();
    _categoryStats.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stats_dailyAzkarCount');
    await prefs.remove('stats_fortyDaysCount');
    await prefs.remove('stats_totalTimeSeconds');
    await prefs.remove('stats_currentStreak');
    await prefs.remove('stats_longestStreak');
    await prefs.remove('stats_lastActiveDate');
    await prefs.remove('stats_activeDates');
    await prefs.remove('stats_categoryStats');

    // Also reset stats on cloud if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'totalAzkarCount': 0,
          'dailyAzkarCount': 0,
          'fortyDaysCount': 0,
          'totalTimeSeconds': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'lastActiveDate': '',
          'activeDates': [],
          'categoryStats': {},
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error resetting Firestore stats: $e");
      }
    }

    notifyListeners();
  }

  void resetLocalStatsInMemory() {
    _dailyAzkarCount = 0;
    _fortyDaysCount = 0;
    _totalTimeSeconds = 0;
    _currentStreak = 0;
    _longestStreak = 0;
    _lastActiveDate = '';
    _activeDates.clear();
    _categoryStats.clear();
    notifyListeners();
  }

  Future<void> resetLocalStats() async {
    resetLocalStatsInMemory();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stats_dailyAzkarCount');
    await prefs.remove('stats_fortyDaysCount');
    await prefs.remove('stats_totalTimeSeconds');
    await prefs.remove('stats_currentStreak');
    await prefs.remove('stats_longestStreak');
    await prefs.remove('stats_lastActiveDate');
    await prefs.remove('stats_activeDates');
    await prefs.remove('stats_categoryStats');
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final bool wasGuest = _currentUser == null && user != null;
      final bool wasUser = _currentUser != null && user == null;
      _currentUser = user;

      if (user != null) {
        _syncWithFirestore(wasGuest && _hasLoadedAsGuest);
        _hasLoadedAsGuest = false;
      } else {
        _hasLoadedAsGuest = true;
        if (wasUser) {
          // Logged out: Clear user stats from local storage so next guest has a clean session
          resetLocalStats();
        }
      }
    });
  }

  Future<void> _syncWithFirestore(bool mergeGuestStats) async {
    if (_currentUser == null) return;
    final uid = _currentUser!.uid;

    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final int cloudDaily = data['dailyAzkarCount'] ?? 0;
          final int cloudFortyDays = data['fortyDaysCount'] ?? 0;
          final int cloudTotalTime = data['totalTimeSeconds'] ?? 0;
          final int cloudCurrentStreak = data['currentStreak'] ?? 0;
          final int cloudLongestStreak = data['longestStreak'] ?? 0;
          final String cloudLastActiveDate = data['lastActiveDate'] ?? '';
          final List<String> cloudActiveDates = List<String>.from(data['activeDates'] ?? []);

          Map<String, CategoryStat> cloudCategoryStats = {};
          if (data['categoryStats'] != null) {
            final Map<String, dynamic> catMap = data['categoryStats'];
            cloudCategoryStats = catMap.map(
              (key, value) => MapEntry(key, CategoryStat.fromJson(value)),
            );
          }

          if (mergeGuestStats) {
            // Merge guest progress into cloud progress
            _dailyAzkarCount = cloudDaily + _dailyAzkarCount;
            _fortyDaysCount = cloudFortyDays + _fortyDaysCount;
            _totalTimeSeconds = cloudTotalTime + _totalTimeSeconds;

            _currentStreak = _currentStreak > cloudCurrentStreak ? _currentStreak : cloudCurrentStreak;
            _longestStreak = _longestStreak > cloudLongestStreak ? _longestStreak : cloudLongestStreak;
            if (_longestStreak < _currentStreak) {
              _longestStreak = _currentStreak;
            }

            if (_lastActiveDate.isEmpty || (cloudLastActiveDate.isNotEmpty && cloudLastActiveDate.compareTo(_lastActiveDate) > 0)) {
              _lastActiveDate = cloudLastActiveDate;
            }

            final Set<String> activeDatesSet = {..._activeDates, ...cloudActiveDates};
            _activeDates = activeDatesSet.toList();

            for (var entry in cloudCategoryStats.entries) {
              final catId = entry.key;
              final cloudStat = entry.value;
              final localStat = _categoryStats.putIfAbsent(catId, () => CategoryStat());
              localStat.readCount += cloudStat.readCount;
              localStat.itemsReadCount += cloudStat.itemsReadCount;
              localStat.timeSpentSeconds += cloudStat.timeSpentSeconds;
            }

            // Save the merged stats to both local and cloud
            await _saveStats();
          } else {
            // Overwrite memory and local cache with cloud data (normal app startup login sync)
            _dailyAzkarCount = cloudDaily;
            _fortyDaysCount = cloudFortyDays;
            _totalTimeSeconds = cloudTotalTime;
            _currentStreak = cloudCurrentStreak;
            _longestStreak = cloudLongestStreak;
            _lastActiveDate = cloudLastActiveDate;
            _activeDates = cloudActiveDates;
            _categoryStats = cloudCategoryStats;

            _checkStreakValidity();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('stats_dailyAzkarCount', _dailyAzkarCount);
            await prefs.setInt('stats_fortyDaysCount', _fortyDaysCount);
            await prefs.setInt('stats_totalTimeSeconds', _totalTimeSeconds);
            await prefs.setInt('stats_currentStreak', _currentStreak);
            await prefs.setInt('stats_longestStreak', _longestStreak);
            await prefs.setString('stats_lastActiveDate', _lastActiveDate);
            await prefs.setStringList('stats_activeDates', _activeDates);

            final Map<String, dynamic> catMap =
                _categoryStats.map((key, value) => MapEntry(key, value.toJson()));
            await prefs.setString('stats_categoryStats', json.encode(catMap));
          }
          notifyListeners();
        }
      } else {
        // Document does not exist in cloud: upload local stats to initialize
        await _saveStats();
      }
    } catch (e) {
      debugPrint("Error syncing stats with Firestore: $e");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Helper to format seconds
  static String formatDuration(int totalSeconds) {
    final int days = totalSeconds ~/ 86400;
    final int hours = (totalSeconds % 86400) ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    final String hStr = hours.toString().padLeft(2, '0');
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');

    return '$days يوم $hStr س : $mStr د : $sStr ث';
  }
}
