import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class PrayerProvider with ChangeNotifier {
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  String _errorMessage = '';
  String _locationName = '';
  
  // Settings
  bool _isAutomaticLocation = true;
  String _manualLocationText = '';
  CalculationMethod _calculationMethod = CalculationMethod.egyptian;
  String _adhanSound = 'adhan';

  Timer? _timer;
  Duration timeUntilNextPrayer = Duration.zero;
  bool _isScheduling = false;
  bool _needsReschedule = false;

  final Map<Prayer, bool> prayerToggles = {
    Prayer.fajr: true,
    Prayer.sunrise: false,
    Prayer.dhuhr: true,
    Prayer.asr: true,
    Prayer.maghrib: true,
    Prayer.isha: true,
  };

  PrayerTimes? get prayerTimes => _prayerTimes;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get locationName => _locationName;
  
  bool get isAutomaticLocation => _isAutomaticLocation;
  String get manualLocationText => _manualLocationText;
  CalculationMethod get calculationMethod => _calculationMethod;
  String get adhanSound => _adhanSound;

  String get calculationMethodName {
    switch (_calculationMethod) {
      case CalculationMethod.egyptian: return 'الهيئة المصرية العامة للمساحة';
      case CalculationMethod.muslim_world_league: return 'رابطة العالم الإسلامي';
      case CalculationMethod.umm_al_qura: return 'أم القرى';
      case CalculationMethod.karachi: return 'جامعة العلوم الإسلامية بكراتشي';
      case CalculationMethod.qatar: return 'قطر';
      case CalculationMethod.kuwait: return 'الكويت';
      case CalculationMethod.moon_sighting_committee: return 'لجنة رؤية الهلال';
      default: return 'أخرى';
    }
  }

  PrayerProvider() {
    _initPrayerTimes();
  }

  Future<void> refreshLocation() async {
    await _initPrayerTimes();
  }

  Future<void> updateSettings(bool isAuto, String manualText, CalculationMethod method, String adhanSoundName) async {
    _isAutomaticLocation = isAuto;
    _manualLocationText = manualText;
    _calculationMethod = method;
    _adhanSound = adhanSoundName;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutomaticLocation', _isAutomaticLocation);
    await prefs.setString('manualLocationText', _manualLocationText);
    await prefs.setInt('calculationMethodIndex', _calculationMethod.index);
    await prefs.setString('adhanSound', _adhanSound);
    
    _initPrayerTimes();
  }

  Future<void> _initPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _loadSettings();

      double? cachedLat = prefs.getDouble('cached_lat');
      double? cachedLng = prefs.getDouble('cached_lng');
      String? cachedLocName = prefs.getString('cached_location_name');

      bool useCache = false;
      if (cachedLat != null && cachedLng != null) {
        if (_isAutomaticLocation) {
          useCache = true;
        } else {
          if (_manualLocationText.trim().toLowerCase() == (cachedLocName ?? '').trim().toLowerCase()) {
            useCache = true;
          }
        }
      }

      if (useCache) {
        _locationName = cachedLocName ?? 'موقع محفوظ محلياً';
        final coordinates = Coordinates(cachedLat!, cachedLng!);
        final params = _calculationMethod.getParameters();
        params.madhab = Madhab.shafi;
        
        final date = DateComponents.from(DateTime.now());
        _prayerTimes = PrayerTimes(coordinates, date, params);
        _errorMessage = '';
        _isLoading = false;
        notifyListeners();
        
        _startCountdownTimer();
        _scheduleNotifications();
      } else {
        _isLoading = true;
        notifyListeners();
      }

      double? latitude;
      double? longitude;
      String? freshLocationName;

      if (_isAutomaticLocation) {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }
            if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
              final position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.low,
                  timeLimit: Duration(seconds: 4),
                ),
              );
              latitude = position.latitude;
              longitude = position.longitude;

              try {
                List<Placemark> placemarks = await Geocoding()
                    .placemarkFromCoordinates(latitude, longitude)
                    .timeout(const Duration(seconds: 3));
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  final city = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
                  freshLocationName = '${city ?? ''}, ${place.country ?? ''}'.trim();
                  if (freshLocationName.startsWith(',')) freshLocationName = freshLocationName.substring(1).trim();
                }
              } catch (_) {
                if (cachedLat != null && cachedLng != null && cachedLocName != null) {
                  final double latDiff = (latitude - cachedLat).abs();
                  final double lngDiff = (longitude - cachedLng).abs();
                  if (latDiff < 0.15 && lngDiff < 0.15) {
                    freshLocationName = cachedLocName;
                  }
                }
                freshLocationName ??= 'إحداثيات: ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
              }
            }
          }
        } catch (_) {}
      } else {
        // Manual Location
        if (_manualLocationText.isNotEmpty) {
          try {
            List<Location> locations = await Geocoding()
                .locationFromAddress(_manualLocationText)
                .timeout(const Duration(seconds: 4));
            if (locations.isNotEmpty) {
              latitude = locations.first.latitude;
              longitude = locations.first.longitude;
              freshLocationName = _manualLocationText;
            }
          } catch (_) {}
        }
      }

      if (latitude != null && longitude != null) {
        _locationName = freshLocationName ?? 'موقع غير معروف';
        await prefs.setDouble('cached_lat', latitude);
        await prefs.setDouble('cached_lng', longitude);
        await prefs.setString('cached_location_name', _locationName);

        final coordinates = Coordinates(latitude, longitude);
        final params = _calculationMethod.getParameters();
        params.madhab = Madhab.shafi;
        
        final date = DateComponents.from(DateTime.now());
        _prayerTimes = PrayerTimes(coordinates, date, params);
        _errorMessage = '';
        
        _startCountdownTimer();
        _scheduleNotifications();
      } else {
        if (_prayerTimes == null) {
          _errorMessage = 'لم يتم التمكن من تحديد الموقع. يرجى التوصيل بالإنترنت مرة واحدة لتحديد موقعك أو كتابة اسم مدينتك في الإعدادات.';
        }
      }
      
    } catch (e) {
      if (_prayerTimes == null) {
        _errorMessage = 'حدث خطأ أثناء جلب مواقيت الصلاة: $e';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isDisposed = false;
  DateTime Function() nowProvider = DateTime.now;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_prayerTimes == null || _isDisposed) return;
    
    final now = nowProvider();
    final next = nextPrayer;
    DateTime nextTime = _prayerTimes!.timeForPrayer(next) ?? now;
    
    if (_prayerTimes!.nextPrayerByDateTime(now) == Prayer.none) {
      final tomorrow = now.add(const Duration(days: 1));
      final nextDate = DateComponents.from(tomorrow);
      
      // Calculate tomorrow's fajr using the same coordinates that was used for _prayerTimes
      final coords = _prayerTimes!.coordinates;
      final params = _calculationMethod.getParameters();
      params.madhab = Madhab.shafi;
      
      final nextDayTimes = PrayerTimes(coords, nextDate, params);
      nextTime = nextDayTimes.fajr;
    }
    
    timeUntilNextPrayer = nextTime.difference(now);
    if (timeUntilNextPrayer.isNegative) {
      timeUntilNextPrayer = Duration.zero;
      _initPrayerTimes(); 
    }
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isAutomaticLocation = prefs.getBool('isAutomaticLocation') ?? true;
    _manualLocationText = prefs.getString('manualLocationText') ?? '';
    
    final methodIndex = prefs.getInt('calculationMethodIndex');
    if (methodIndex != null && methodIndex >= 0 && methodIndex < CalculationMethod.values.length) {
      _calculationMethod = CalculationMethod.values[methodIndex];
    }
    
    _adhanSound = prefs.getString('adhanSound') ?? 'adhan';
    
    for (var prayer in prayerToggles.keys) {
      final val = prefs.getBool('prayer_${prayer.name}');
      if (val != null) {
        prayerToggles[prayer] = val;
      }
    }
  }

  Future<void> togglePrayerNotification(Prayer prayer) async {
    prayerToggles[prayer] = !(prayerToggles[prayer] ?? true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_${prayer.name}', prayerToggles[prayer]!);
    notifyListeners();
    _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    if (_prayerTimes == null) return;
    
    if (_isScheduling) {
      _needsReschedule = true;
      return;
    }
    _isScheduling = true;
    _needsReschedule = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final ns = NotificationService();
      await ns.cancelAllNotifications();

      final coords = _prayerTimes!.coordinates;
      final params = _calculationMethod.getParameters();
      params.madhab = Madhab.shafi;
      final now = DateTime.now();

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final targetDate = now.add(Duration(days: dayOffset));
        final dateComp = DateComponents.from(targetDate);
        final pTimes = PrayerTimes(coords, dateComp, params);

        final prayers = [
          {
            'id': dayOffset * 10 + 0,
            'prayer': Prayer.fajr,
            'name': 'الفجر',
            'time': pTimes.fajr,
            'title': 'حان الآن وقت صلاة الفجر 🕌',
            'hadith': 'قال ﷺ: «بَشِّرِ الْمَشَّائِينَ فِي الظُّلَمِ إِلَى الْمَسَاجِدِ بِالنُّورِ التَّامِّ يَوْمَ الْقِيَامَةِ» — قم لصلاة الجماعة.'
          },
          {
            'id': dayOffset * 10 + 1,
            'prayer': Prayer.sunrise,
            'name': 'الشروق',
            'time': pTimes.sunrise,
            'title': 'وقت الإشراق ☀️',
            'hadith': 'قال ﷺ: «مَنْ صَلَّى الْغَدَاةَ فِي جَمَاعَةٍ ثُمَّ قَعَدَ يَذْكُرُ اللَّهَ حَتَّى تَطْلُعَ الشَّمْسُ... كَانَتْ لَهُ كَأَجْرِ حَجَّةٍ وَعُمْرَةٍ»'
          },
          {
            'id': dayOffset * 10 + 2,
            'prayer': Prayer.dhuhr,
            'name': 'الظهر',
            'time': pTimes.dhuhr,
            'title': 'حان الآن وقت صلاة الظهر 🕌',
            'hadith': 'قال ﷺ: «صَلاَةُ الْجَمَاعَةِ تَفْضُلُ صَلاَةَ الْفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً» — لا تفوّت أجر الجماعة في المسجد.'
          },
          {
            'id': dayOffset * 10 + 3,
            'prayer': Prayer.asr,
            'name': 'العصر',
            'time': pTimes.asr,
            'title': 'حان الآن وقت صلاة العصر 🕌',
            'hadith': 'قال ﷺ: «مَنْ صَلَّى الْبَرَدَيْنِ دَخَلَ الْجَنَّةَ» — أسرِع لصلاة العصر مع الجماعة بالمسجد.'
          },
          {
            'id': dayOffset * 10 + 4,
            'prayer': Prayer.maghrib,
            'name': 'المغرب',
            'time': pTimes.maghrib,
            'title': 'حان الآن وقت صلاة المغرب 🕌',
            'hadith': 'قال ﷺ: «مَنْ غَدَا إِلَى الْمَسْجِدِ أَوْ رَاحَ أَعَدَّ اللَّهُ لَهُ نُزُلَهُ مِنَ الْجَنَّةِ كُلَّمَا غَدَا أَوْ رَاحَ»'
          },
          {
            'id': dayOffset * 10 + 5,
            'prayer': Prayer.isha,
            'name': 'العشاء',
            'time': pTimes.isha,
            'title': 'حان الآن وقت صلاة العشاء 🕌',
            'hadith': 'قال ﷺ: «مَنْ صَلَّى الْعِشَاءَ فِي جَمَأعَةٍ فَكَأَنَّمَا قَامَ نِصْفَ اللَّيْلِ» — أقبل إلى المسجد وثقِّل موازينك.'
          },
        ];

        for (var p in prayers) {
          final prayerType = p['prayer'] as Prayer;
          final isEnabled = prayerToggles[prayerType] ?? false;
          final time = p['time'] as DateTime;
          
          if (isEnabled && time.isAfter(now)) {
            await ns.schedulePrayerNotification(
              id: p['id'] as int,
              title: p['title'] as String,
              body: p['hadith'] as String,
              scheduledTime: time,
              soundName: _adhanSound,
            );
          }
        }

        // Schedule Forty Days Pre-Prayer Reminders (15 mins before)
        final fortyDaysReminders = prefs.getBool('fortyDaysReminders') ?? true;
        if (fortyDaysReminders) {
          final prayersList = [
            {'name': 'الفجر', 'time': pTimes.fajr},
            {'name': 'الظهر', 'time': pTimes.dhuhr},
            {'name': 'العصر', 'time': pTimes.asr},
            {'name': 'المغرب', 'time': pTimes.maghrib},
            {'name': 'العشاء', 'time': pTimes.isha},
          ];
          
          for (int i = 0; i < prayersList.length; i++) {
            final p = prayersList[i];
            final pTime = p['time'] as DateTime;
            final reminderTime = pTime.subtract(const Duration(minutes: 15));
            if (reminderTime.isAfter(now)) {
              await ns.scheduleAzkarNotification(
                id: 200 + dayOffset * 10 + i,
                title: 'تأهب لصلاة ${p['name']} جماعة 🕌',
                body: 'متبقي 15 دقيقة على الأذان. استعد للذهاب للمسجد لإدراك تكبيرة الإحرام والفوز بتحدي الأربعين يوماً!',
                scheduledTime: reminderTime,
              );
            }
          }
        }

        // Schedule Azkar Reminders for each day:
        // 1. Morning Azkar (25 mins after Sunrise)
        final morningAzkarTime = pTimes.sunrise.add(const Duration(minutes: 25));
        if (morningAzkarTime.isAfter(now)) {
          await ns.scheduleAzkarNotification(
            id: 100 + dayOffset * 3 + 0,
            title: '☀️ حان وقت أذكار الصباح والتحصين',
            body: 'قال تعالى: «أَلا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ» — ابدأ يومك بالبركة والحفظ التام.',
            scheduledTime: morningAzkarTime,
          );
        }

        // 2. Evening Azkar (30 mins after Asr)
        final eveningAzkarTime = pTimes.asr.add(const Duration(minutes: 30));
        if (eveningAzkarTime.isAfter(now)) {
          await ns.scheduleAzkarNotification(
            id: 100 + dayOffset * 3 + 1,
            title: '🌆 حان وقت أذكار المساء',
            body: 'حصّن نفسك وأهلك بورد أذكار المساء المأثورة عن النبي ﷺ لتبدو في حفظ الله حتى تصبح.',
            scheduledTime: eveningAzkarTime,
          );
        }

        // 3. Bedtime Azkar (1 hour after Isha / 10 PM)
        final sleepAzkarTime = pTimes.isha.add(const Duration(hours: 1));
        if (sleepAzkarTime.isAfter(now)) {
          await ns.scheduleAzkarNotification(
            id: 100 + dayOffset * 3 + 2,
            title: '🌙 أذكار النوم والتحصين قبل النوم',
            body: 'اقرأ آية الكرسي والمُعوّذتين وسورة الإخلاص قبل نومك لتكون في رعاية الله وحفظه.',
            scheduledTime: sleepAzkarTime,
          );
        }
      }
    } finally {
      _isScheduling = false;
      if (_needsReschedule) {
        _scheduleNotifications();
      }
    }
  }

  String formatTime(DateTime time) {
    return DateFormat.jm('ar').format(time);
  }

  String formatTimeWithAmPm(DateTime time, {String locale = 'ar'}) {
    try {
      return DateFormat('h:mm a', locale).format(time);
    } catch (_) {
      return DateFormat('h:mm a').format(time);
    }
  }
  
  Prayer get currentPrayer {
    if (_prayerTimes == null) return Prayer.none;
    return _prayerTimes!.currentPrayerByDateTime(nowProvider());
  }

  Prayer get nextPrayer {
    if (_prayerTimes == null) return Prayer.fajr;
    final next = _prayerTimes!.nextPrayerByDateTime(nowProvider());
    return next == Prayer.none ? Prayer.fajr : next;
  }

  int getPostAdhanThresholdMinutes(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 20;
      case Prayer.dhuhr:
        return 15;
      case Prayer.asr:
        return 15;
      case Prayer.maghrib:
        return 5;
      case Prayer.isha:
        return 15;
      default:
        return 0;
    }
  }

  Prayer? get activePostAdhanPrayer {
    if (_prayerTimes == null) return null;
    final now = nowProvider();

    // Check today's 5 adhan prayers
    final prayers = [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (final prayer in prayers) {
      final pTime = _prayerTimes!.timeForPrayer(prayer);
      if (pTime == null) continue;

      final threshold = getPostAdhanThresholdMinutes(prayer);
      if (now.isAfter(pTime) || now.isAtSameMomentAs(pTime)) {
        final diff = now.difference(pTime);
        if (diff.inMinutes <= threshold) {
          return prayer;
        }
      }
    }

    // Edge case: yesterday's Isha if now is shortly after midnight
    if (now.hour == 0 && now.minute < 20) {
      try {
        final yesterday = now.subtract(const Duration(days: 1));
        final coords = _prayerTimes!.coordinates;
        final params = _calculationMethod.getParameters();
        params.madhab = Madhab.shafi;
        final yesterdayTimes = PrayerTimes(coords, DateComponents.from(yesterday), params);
        final yesterdayIsha = yesterdayTimes.isha;
        final ishaThreshold = getPostAdhanThresholdMinutes(Prayer.isha);
        if (now.isAfter(yesterdayIsha) || now.isAtSameMomentAs(yesterdayIsha)) {
          final diff = now.difference(yesterdayIsha);
          if (diff.inMinutes <= ishaThreshold) {
            return Prayer.isha;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  bool get isPostAdhanPeriod => activePostAdhanPrayer != null;

  Duration get postAdhanElapsed {
    if (_prayerTimes == null) return Duration.zero;
    final prayer = activePostAdhanPrayer;
    if (prayer == null) return Duration.zero;

    final now = nowProvider();
    var pTime = _prayerTimes!.timeForPrayer(prayer);
    if (pTime == null || pTime.isAfter(now)) {
      // Must be yesterday's Isha
      try {
        final yesterday = now.subtract(const Duration(days: 1));
        final coords = _prayerTimes!.coordinates;
        final params = _calculationMethod.getParameters();
        params.madhab = Madhab.shafi;
        final yesterdayTimes = PrayerTimes(coords, DateComponents.from(yesterday), params);
        pTime = yesterdayTimes.isha;
      } catch (_) {}
    }

    if (pTime != null && (now.isAfter(pTime) || now.isAtSameMomentAs(pTime))) {
      return now.difference(pTime);
    }
    return Duration.zero;
  }

  Prayer get displayPrayer {
    if (isPostAdhanPeriod && activePostAdhanPrayer != null) {
      return activePostAdhanPrayer!;
    }
    return nextPrayer;
  }

  DateTime? get displayPrayerTime {
    if (_prayerTimes == null) return null;
    if (isPostAdhanPeriod && activePostAdhanPrayer != null) {
      final pTime = _prayerTimes!.timeForPrayer(activePostAdhanPrayer!);
      if (pTime != null && pTime.isBefore(nowProvider())) {
        return pTime;
      }
      // Handle yesterday's Isha if needed
      if (activePostAdhanPrayer == Prayer.isha) {
        try {
          final yesterday = nowProvider().subtract(const Duration(days: 1));
          final coords = _prayerTimes!.coordinates;
          final params = _calculationMethod.getParameters();
          params.madhab = Madhab.shafi;
          final yesterdayTimes = PrayerTimes(coords, DateComponents.from(yesterday), params);
          return yesterdayTimes.isha;
        } catch (_) {}
      }
      return pTime;
    }

    final next = nextPrayer;
    if (_prayerTimes!.nextPrayer() == Prayer.none) {
      // After Isha, next prayer is tomorrow's Fajr
      final tomorrow = nowProvider().add(const Duration(days: 1));
      final nextDate = DateComponents.from(tomorrow);
      final coords = _prayerTimes!.coordinates;
      final params = _calculationMethod.getParameters();
      params.madhab = Madhab.shafi;
      final nextDayTimes = PrayerTimes(coords, nextDate, params);
      return nextDayTimes.fajr;
    }
    return _prayerTimes!.timeForPrayer(next);
  }

  String getPrayerArabicName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      default:
        return 'الظهر';
    }
  }

  String getPrayerEnglishName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Shuruq';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      default:
        return 'Dhuhr';
    }
  }

  String get formattedCountdownShort {
    if (isPostAdhanPeriod && activePostAdhanPrayer != null) {
      final name = getPrayerEnglishName(activePostAdhanPrayer!);
      final elapsedMinutes = postAdhanElapsed.inMinutes;
      if (elapsedMinutes <= 0) {
        return '$name Adhan is now';
      } else if (elapsedMinutes == 1) {
        return '1m since $name Adhan';
      } else {
        return '${elapsedMinutes}m since $name Adhan';
      }
    }

    final hours = timeUntilNextPrayer.inHours;
    final mins = timeUntilNextPrayer.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hours ${mins}m left';
    } else {
      return '${mins}m left';
    }
  }

  String get formattedCountdownArabic {
    if (isPostAdhanPeriod && activePostAdhanPrayer != null) {
      final name = getPrayerArabicName(activePostAdhanPrayer!);
      final elapsedMinutes = postAdhanElapsed.inMinutes;
      if (elapsedMinutes <= 0) {
        return 'الآن أذان $name';
      } else if (elapsedMinutes == 1) {
        return 'مرت دقيقة على أذان $name';
      } else if (elapsedMinutes == 2) {
        return 'مرت دقيقتان على أذان $name';
      } else if (elapsedMinutes >= 3 && elapsedMinutes <= 10) {
        return 'مرت $elapsedMinutes دقائق على أذان $name';
      } else {
        return 'مرت $elapsedMinutes دقيقة على أذان $name';
      }
    }

    final hours = timeUntilNextPrayer.inHours;
    final mins = timeUntilNextPrayer.inMinutes.remainder(60);
    if (hours > 0) {
      return 'متبقي $hours ساعة و $mins دقيقة';
    } else if (mins > 0) {
      return 'متبقي $mins دقيقة';
    } else {
      return 'متبقي أقل من دقيقة';
    }
  }
  
  String get formattedCountdown {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(timeUntilNextPrayer.inHours);
    String minutes = twoDigits(timeUntilNextPrayer.inMinutes.remainder(60));
    String seconds = twoDigits(timeUntilNextPrayer.inSeconds.remainder(60));
    return "- $hours:$minutes:$seconds";
  }

  void setPrayerTimesForTesting(PrayerTimes pt) {
    _prayerTimes = pt;
    _updateCountdown();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
