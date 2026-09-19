import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';
import 'package:azkar/providers/prayer_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrayerProvider provider;
  late Coordinates coords;
  late CalculationParameters params;
  late PrayerTimes pt;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = PrayerProvider();
    // Cairo coordinates
    coords = Coordinates(30.0444, 31.2357);
    params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    // Use a fixed date: 2026-06-15
    final date = DateComponents(2026, 6, 15);
    pt = PrayerTimes(coords, date, params);
    provider.setPrayerTimesForTesting(pt);
  });

  tearDown(() {
    provider.dispose();
  });

  group('Post-Adhan Periods and Countdowns', () {
    test('Dhuhr: post-adhan active for 15 minutes, then switches to Asr', () {
      final dhuhrTime = pt.dhuhr;

      // Exactly at Dhuhr (0 mins elapsed)
      provider.nowProvider = () => dhuhrTime;
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.activePostAdhanPrayer, equals(Prayer.dhuhr));
      expect(provider.displayPrayer, equals(Prayer.dhuhr));
      expect(provider.formattedCountdownArabic, contains('الآن أذان الظهر'));

      // 1 minute after Dhuhr
      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 1));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.formattedCountdownArabic, contains('مرت دقيقة على أذان الظهر'));

      // 2 minutes after Dhuhr
      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 2));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.formattedCountdownArabic, contains('مرت دقيقتان على أذان الظهر'));

      // 5 minutes after Dhuhr
      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 5));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.formattedCountdownArabic, contains('مرت 5 دقائق على أذان الظهر'));

      // 15 minutes after Dhuhr (upper boundary)
      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 15, seconds: 30));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.formattedCountdownArabic, contains('مرت 15 دقيقة على أذان الظهر'));

      // 16 minutes after Dhuhr (exceeded 15 min threshold -> switches to Asr)
      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 16));
      expect(provider.isPostAdhanPeriod, isFalse);
      expect(provider.activePostAdhanPrayer, isNull);
      expect(provider.displayPrayer, equals(Prayer.asr));
      expect(provider.formattedCountdownArabic, contains('متبقي'));
    });

    test('Maghrib: post-adhan active for 5 minutes, then switches to Isha', () {
      final maghribTime = pt.maghrib;

      // 3 minutes after Maghrib
      provider.nowProvider = () => maghribTime.add(const Duration(minutes: 3));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.activePostAdhanPrayer, equals(Prayer.maghrib));
      expect(provider.displayPrayer, equals(Prayer.maghrib));
      expect(provider.formattedCountdownArabic, contains('مرت 3 دقائق على أذان المغرب'));

      // 5 minutes after Maghrib
      provider.nowProvider = () => maghribTime.add(const Duration(minutes: 5, seconds: 20));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.formattedCountdownArabic, contains('مرت 5 دقائق على أذان المغرب'));

      // 6 minutes after Maghrib (exceeded 5 min threshold -> switches to Isha)
      provider.nowProvider = () => maghribTime.add(const Duration(minutes: 6));
      expect(provider.isPostAdhanPeriod, isFalse);
      expect(provider.displayPrayer, equals(Prayer.isha));
      expect(provider.formattedCountdownArabic, contains('متبقي'));
    });

    test('Fajr: post-adhan active for 20 minutes, then switches to Sunrise', () {
      final fajrTime = pt.fajr;

      // 10 minutes after Fajr
      provider.nowProvider = () => fajrTime.add(const Duration(minutes: 10));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.activePostAdhanPrayer, equals(Prayer.fajr));
      expect(provider.displayPrayer, equals(Prayer.fajr));
      expect(provider.formattedCountdownArabic, contains('مرت 10 دقائق على أذان الفجر'));

      // 20 minutes after Fajr
      provider.nowProvider = () => fajrTime.add(const Duration(minutes: 20, seconds: 40));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.formattedCountdownArabic, contains('مرت 20 دقيقة على أذان الفجر'));

      // 21 minutes after Fajr (exceeded 20 min threshold -> switches to Sunrise)
      provider.nowProvider = () => fajrTime.add(const Duration(minutes: 21));
      expect(provider.isPostAdhanPeriod, isFalse);
      expect(provider.displayPrayer, equals(Prayer.sunrise));
      expect(provider.formattedCountdownArabic, contains('متبقي'));
    });

    test('Asr: post-adhan active for 15 minutes', () {
      final asrTime = pt.asr;

      provider.nowProvider = () => asrTime.add(const Duration(minutes: 15));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.activePostAdhanPrayer, equals(Prayer.asr));
      expect(provider.formattedCountdownArabic, contains('مرت 15 دقيقة على أذان العصر'));

      provider.nowProvider = () => asrTime.add(const Duration(minutes: 16));
      expect(provider.isPostAdhanPeriod, isFalse);
      expect(provider.displayPrayer, equals(Prayer.maghrib));
    });

    test('Isha: post-adhan active for 15 minutes', () {
      final ishaTime = pt.isha;

      provider.nowProvider = () => ishaTime.add(const Duration(minutes: 7));
      expect(provider.isPostAdhanPeriod, isTrue);
      expect(provider.activePostAdhanPrayer, equals(Prayer.isha));
      expect(provider.formattedCountdownArabic, contains('مرت 7 دقائق على أذان العشاء'));

      provider.nowProvider = () => ishaTime.add(const Duration(minutes: 16));
      expect(provider.isPostAdhanPeriod, isFalse);
      expect(provider.displayPrayer, equals(Prayer.fajr));
    });

    test('Sunrise: does NOT trigger post-adhan period', () {
      final sunriseTime = pt.sunrise;

      provider.nowProvider = () => sunriseTime.add(const Duration(minutes: 2));
      expect(provider.isPostAdhanPeriod, isFalse);
      expect(provider.activePostAdhanPrayer, isNull);
    });

    test('English countdown format', () {
      final dhuhrTime = pt.dhuhr;

      provider.nowProvider = () => dhuhrTime;
      expect(provider.formattedCountdownShort, contains('Dhuhr Adhan is now'));

      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 1));
      expect(provider.formattedCountdownShort, contains('1m since Dhuhr Adhan'));

      provider.nowProvider = () => dhuhrTime.add(const Duration(minutes: 12));
      expect(provider.formattedCountdownShort, contains('12m since Dhuhr Adhan'));
    });
  });
}
