class QuitSmokingState {
  final DateTime startDate;
  final int normalCigarettesPerDay;
  final int yearsOfSmoking;
  final double packPrice;
  final Map<String, int> dailyLogs; // 'YYYY-MM-DD' -> cigarettes smoked
  final bool isConfigured;

  QuitSmokingState({
    required this.startDate,
    required this.normalCigarettesPerDay,
    required this.yearsOfSmoking,
    required this.packPrice,
    required this.dailyLogs,
    this.isConfigured = false,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
        'normalCigarettesPerDay': normalCigarettesPerDay,
        'yearsOfSmoking': yearsOfSmoking,
        'packPrice': packPrice,
        'dailyLogs': dailyLogs,
        'isConfigured': isConfigured,
      };

  factory QuitSmokingState.fromJson(Map<String, dynamic> json) {
    var logsRaw = json['dailyLogs'] as Map<String, dynamic>? ?? {};
    Map<String, int> logs = {};
    logsRaw.forEach((key, value) {
      logs[key] = (value as num).toInt();
    });

    return QuitSmokingState(
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      normalCigarettesPerDay: json['normalCigarettesPerDay'] ?? 20,
      yearsOfSmoking: json['yearsOfSmoking'] ?? 5,
      packPrice: (json['packPrice'] as num? ?? 50.0).toDouble(),
      dailyLogs: logs,
      isConfigured: json['isConfigured'] ?? false,
    );
  }

  // Create an empty state
  factory QuitSmokingState.empty() {
    return QuitSmokingState(
      startDate: DateTime.now(),
      normalCigarettesPerDay: 20,
      yearsOfSmoking: 5,
      packPrice: 50.0,
      dailyLogs: const {},
      isConfigured: false,
    );
  }
}
