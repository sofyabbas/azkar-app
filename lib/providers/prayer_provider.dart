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

  Timer? _timer;
  Duration timeUntilNextPrayer = Duration.zero;

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

  Future<void> updateSettings(bool isAuto, String manualText, CalculationMethod method) async {
    _isAutomaticLocation = isAuto;
    _manualLocationText = manualText;
    _calculationMethod = method;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAutomaticLocation', _isAutomaticLocation);
    await prefs.setString('manualLocationText', _manualLocationText);
    await prefs.setInt('calculationMethodIndex', _calculationMethod.index);
    
    _initPrayerTimes();
  }

  Future<void> _initPrayerTimes() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _loadSettings();

      double? latitude;
      double? longitude;

      if (_isAutomaticLocation) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _errorMessage = 'خدمات الموقع معطلة. يرجى تفعيلها.';
          _isLoading = false;
          notifyListeners();
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _errorMessage = 'تم رفض صلاحيات الموقع.';
            _isLoading = false;
            notifyListeners();
            return;
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          _errorMessage = 'صلاحيات الموقع مرفوضة بشكل دائم.';
          _isLoading = false;
          notifyListeners();
          return;
        }

        final position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
        
        try {
          List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(latitude, longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final city = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
            _locationName = '${city ?? ''}, ${place.country ?? ''}'.trim();
            if (_locationName.startsWith(',')) _locationName = _locationName.substring(1).trim();
          }
        } catch (e) {
          _locationName = 'إحداثيات: ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
        }
      } else {
        // Manual Location
        if (_manualLocationText.isEmpty) {
          _errorMessage = 'يرجى إدخال اسم المدينة في الإعدادات.';
          _isLoading = false;
          notifyListeners();
          return;
        }
        
        try {
          List<Location> locations = await Geocoding().locationFromAddress(_manualLocationText);
          if (locations.isNotEmpty) {
            latitude = locations.first.latitude;
            longitude = locations.first.longitude;
            
            // Try to resolve properly formatted name
            try {
              List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(latitude, longitude);
              if (placemarks.isNotEmpty) {
                final place = placemarks.first;
                final city = place.locality?.isNotEmpty == true ? place.locality : place.subAdministrativeArea;
                _locationName = '${city ?? ''}, ${place.country ?? ''}'.trim();
                if (_locationName.startsWith(',')) _locationName = _locationName.substring(1).trim();
              } else {
                _locationName = _manualLocationText;
              }
            } catch (e) {
              _locationName = _manualLocationText;
            }
          }
        } catch (e) {
          _errorMessage = 'لم يتم العثور على المدينة. يرجى التحقق من الاسم في الإعدادات.';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (latitude == null || longitude == null) {
        _errorMessage = 'لم يتم التمكن من تحديد الموقع.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      if (_locationName.isEmpty) {
        _locationName = 'موقع غير معروف';
      }

      final coordinates = Coordinates(latitude, longitude);
      final params = _calculationMethod.getParameters();
      params.madhab = Madhab.shafi;
      
      final date = DateComponents.from(DateTime.now());
      _prayerTimes = PrayerTimes(coordinates, date, params);
      _errorMessage = '';
      
      _startCountdownTimer();
      await _scheduleNotifications();
      
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب مواقيت الصلاة: $e';
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
    await _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    if (_prayerTimes == null) return;
    
    final ns = NotificationService();
    for (int i = 0; i < 6; i++) {
      await ns.cancelNotification(i);
    }
    
    final prayers = [
      {'id': 0, 'prayer': Prayer.fajr, 'name': 'الفجر', 'time': _prayerTimes!.fajr},
      {'id': 1, 'prayer': Prayer.sunrise, 'name': 'الشروق', 'time': _prayerTimes!.sunrise},
      {'id': 2, 'prayer': Prayer.dhuhr, 'name': 'الظهر', 'time': _prayerTimes!.dhuhr},
      {'id': 3, 'prayer': Prayer.asr, 'name': 'العصر', 'time': _prayerTimes!.asr},
      {'id': 4, 'prayer': Prayer.maghrib, 'name': 'المغرب', 'time': _prayerTimes!.maghrib},
      {'id': 5, 'prayer': Prayer.isha, 'name': 'العشاء', 'time': _prayerTimes!.isha},
    ];

    for (var p in prayers) {
      final prayerType = p['prayer'] as Prayer;
      final isEnabled = prayerToggles[prayerType] ?? false;
      final time = p['time'] as DateTime;
      
      if (isEnabled && time.isAfter(DateTime.now())) {
        await ns.schedulePrayerNotification(
          id: p['id'] as int,
          title: 'حان الآن وقت صلاة ${p['name']}',
          body: 'الصلاة خير من النوم',
          scheduledTime: time,
        );
      }
    }
  }

  String formatTime(DateTime time) {
    return DateFormat.jm().format(time);
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
