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

  void _startCountdownTimer() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (_prayerTimes == null) return;
    
    final now = DateTime.now();
    DateTime nextTime = _prayerTimes!.timeForPrayer(_prayerTimes!.nextPrayer()) ?? now;
    
    if (_prayerTimes!.nextPrayer() == Prayer.none) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
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
    return _prayerTimes!.currentPrayer();
  }

  Prayer get nextPrayer {
    if (_prayerTimes == null) return Prayer.fajr;
    final next = _prayerTimes!.nextPrayer();
    return next == Prayer.none ? Prayer.fajr : next;
  }

  String get formattedCountdownShort {
    final hours = timeUntilNextPrayer.inHours;
    final mins = timeUntilNextPrayer.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours hours ${mins}m left';
    } else {
      return '${mins}m left';
    }
  }

  String get formattedCountdownArabic {
    final hours = timeUntilNextPrayer.inHours;
    final mins = timeUntilNextPrayer.inMinutes.remainder(60);
    if (hours > 0) {
      return 'متبقي $hours ساعة و $mins دقيقة';
    } else {
      return 'متبقي $mins دقيقة';
    }
  }
  
  String get formattedCountdown {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(timeUntilNextPrayer.inHours);
    String minutes = twoDigits(timeUntilNextPrayer.inMinutes.remainder(60));
    String seconds = twoDigits(timeUntilNextPrayer.inSeconds.remainder(60));
    return "- $hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
