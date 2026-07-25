class PrayerLog {
  final String prayerName;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? mosqueName;
  final bool? verifiedByGps;

  PrayerLog({
    required this.prayerName,
    this.isCompleted = false,
    this.completedAt,
    this.mosqueName,
    this.verifiedByGps,
  });

  Map<String, dynamic> toJson() => {
        'prayerName': prayerName,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'mosqueName': mosqueName,
        'verifiedByGps': verifiedByGps,
      };

  factory PrayerLog.fromJson(Map<String, dynamic> json) {
    return PrayerLog(
      prayerName: json['prayerName'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      mosqueName: json['mosqueName'],
      verifiedByGps: json['verifiedByGps'],
    );
  }
}

class DailyProgress {
  final int dayIndex;
  final DateTime date;
  final List<String> completedPrayers;

  DailyProgress({
    required this.dayIndex,
    required this.date,
    required this.completedPrayers,
  });

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'date': date.toIso8601String(),
        'completedPrayers': completedPrayers,
      };

  factory DailyProgress.fromJson(Map<String, dynamic> json) => DailyProgress(
        dayIndex: json['dayIndex'] ?? 0,
        date: DateTime.parse(json['date']),
        completedPrayers: List<String>.from(json['completedPrayers'] ?? []),
      );
}

class SavedMosque {
  final String name;
  final double latitude;
  final double longitude;

  SavedMosque({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory SavedMosque.fromJson(Map<String, dynamic> json) => SavedMosque(
        name: json['name'] ?? 'مسجد',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}

class FortyDaysState {
  final DateTime startDate;
  final int currentDayIndex; // 0 to 39
  final Map<String, PrayerLog> todaysPrayers;
  final List<SavedMosque> savedMosques;
  final List<double> mosqueLocation; // Kept for legacy parsing
  final List<DailyProgress> history;
  final DateTime? lastUpdatedDate;

  FortyDaysState({
    required this.startDate,
    this.currentDayIndex = 0,
    required this.todaysPrayers,
    this.savedMosques = const [],
    this.mosqueLocation = const [],
    this.history = const [],
    this.lastUpdatedDate,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'currentDayIndex': currentDayIndex,
        'todaysPrayers': todaysPrayers.map((k, v) => MapEntry(k, v.toJson())),
        'savedMosques': savedMosques.map((e) => e.toJson()).toList(),
        'mosqueLocation': mosqueLocation,
        'history': history.map((e) => e.toJson()).toList(),
        'lastUpdatedDate': lastUpdatedDate?.toIso8601String(),
      };

  factory FortyDaysState.fromJson(Map<String, dynamic> json) {
    var prayersMap = json['todaysPrayers'] as Map<String, dynamic>? ?? {};
    Map<String, PrayerLog> parsedPrayers = {};
    prayersMap.forEach((key, value) {
      parsedPrayers[key] = PrayerLog.fromJson(value);
    });

    List<dynamic> locDynamic = json['mosqueLocation'] ?? [];
    List<double> loc = locDynamic.map((e) => (e as num).toDouble()).toList();

    var savedMosquesList = json['savedMosques'] as List<dynamic>?;
    List<SavedMosque> mosques = [];
    if (savedMosquesList != null) {
      mosques = savedMosquesList.map((e) => SavedMosque.fromJson(e)).toList();
    } else if (loc.length == 2) {
      // Migrate legacy single mosque location
      mosques = [
        SavedMosque(name: 'المسجد الافتراضي', latitude: loc[0], longitude: loc[1])
      ];
    }

    var historyList = json['history'] as List<dynamic>? ?? [];
    List<DailyProgress> parsedHistory = historyList.map((e) => DailyProgress.fromJson(e)).toList();

    return FortyDaysState(
      startDate: DateTime.parse(json['startDate']),
      currentDayIndex: json['currentDayIndex'] ?? 0,
      todaysPrayers: parsedPrayers,
      savedMosques: mosques,
      mosqueLocation: loc,
      history: parsedHistory,
      lastUpdatedDate: json['lastUpdatedDate'] != null ? DateTime.parse(json['lastUpdatedDate']) : null,
    );
  }
}
