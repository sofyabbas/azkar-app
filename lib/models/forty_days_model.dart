class PrayerLog {
  final String prayerName;
  final bool isCompleted;
  final DateTime? completedAt;

  PrayerLog({
    required this.prayerName,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'prayerName': prayerName,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory PrayerLog.fromJson(Map<String, dynamic> json) {
    return PrayerLog(
      prayerName: json['prayerName'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}

class FortyDaysState {
  final DateTime startDate;
  final int currentDayIndex; // 0 to 39
  final Map<String, PrayerLog> todaysPrayers;
  final List<double> mosqueLocation; // [lat, lng]
  final DateTime? lastUpdatedDate;

  FortyDaysState({
    required this.startDate,
    this.currentDayIndex = 0,
    required this.todaysPrayers,
    this.mosqueLocation = const [],
    this.lastUpdatedDate,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'currentDayIndex': currentDayIndex,
        'todaysPrayers': todaysPrayers.map((k, v) => MapEntry(k, v.toJson())),
        'mosqueLocation': mosqueLocation,
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

    return FortyDaysState(
      startDate: DateTime.parse(json['startDate']),
      currentDayIndex: json['currentDayIndex'] ?? 0,
      todaysPrayers: parsedPrayers,
      mosqueLocation: loc,
      lastUpdatedDate: json['lastUpdatedDate'] != null ? DateTime.parse(json['lastUpdatedDate']) : null,
    );
  }
}
