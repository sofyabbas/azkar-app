import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:azkar/screens/forty_days_screen.dart';
import 'package:azkar/providers/forty_days_provider.dart';
import 'package:azkar/providers/prayer_provider.dart';
import 'package:azkar/models/forty_days_model.dart';
import 'dart:convert';

import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tapping mosque in manual check-in sheet for previous day closes the sheet', (tester) async {
    await initializeDateFormatting('ar', null);
    // Setup state with 1 history day where prayers are uncompleted, and 1 saved mosque
    final pastDate = DateTime.now().subtract(const Duration(days: 1));
    final initialState = FortyDaysState(
      startDate: pastDate,
      currentDayIndex: 1,
      todaysPrayers: {
        'الفجر': PrayerLog(prayerName: 'الفجر'),
        'الظهر': PrayerLog(prayerName: 'الظهر'),
        'العصر': PrayerLog(prayerName: 'العصر'),
        'المغرب': PrayerLog(prayerName: 'المغرب'),
        'العشاء': PrayerLog(prayerName: 'العشاء'),
      },
      savedMosques: [
        SavedMosque(name: 'مسجد النور', latitude: 30.0, longitude: 31.0),
      ],
      history: [
        DailyProgress(
          dayIndex: 0,
          date: pastDate,
          prayers: {
            'الفجر': PrayerLog(prayerName: 'الفجر'),
            'الظهر': PrayerLog(prayerName: 'الظهر'),
            'العصر': PrayerLog(prayerName: 'العصر'),
            'المغرب': PrayerLog(prayerName: 'المغرب'),
            'العشاء': PrayerLog(prayerName: 'العشاء'),
          },
          isSuccess: false,
        ),
      ],
      lastUpdatedDate: DateTime.now(),
    );

    SharedPreferences.setMockInitialValues({
      'fortyDaysState': json.encode(initialState.toJson()),
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FortyDaysProvider()),
          ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ],
        child: const MaterialApp(
          home: FortyDaysScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Day 1 square
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();

    // Day details bottom sheet is open
    expect(find.text('تفاصيل اليوم 1'), findsOneWidget);

    // Find the manual check-in button for Fajr in Day 1
    final manualCheckInButtons = find.byTooltip('إثبات الصلاة يدوياً في المسجد');
    expect(manualCheckInButtons, findsWidgets);
    await tester.tap(manualCheckInButtons.first);
    await tester.pumpAndSettle();

    // Now Mosque sheet should be open
    expect(find.text('مسجد النور'), findsOneWidget);

    // Tap on 'مسجد النور'
    await tester.tap(find.text('مسجد النور'));
    await tester.pumpAndSettle();

    // After tapping, the mosque selection sheet should be closed!
    expect(find.text('اختر مسجداً من قائمتك أو اكتب اسماً جديداً للبحث والإثبات.'), findsNothing);

    // And the Day Details sheet should now show the prayer completed in 'مسجد النور'
    expect(find.textContaining('في "مسجد النور"'), findsOneWidget);
    expect(find.textContaining('أديت في جماعة (يدوي)'), findsOneWidget);
  });
}
