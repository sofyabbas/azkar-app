import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:azkar/screens/forty_days_screen.dart';
import 'package:azkar/providers/forty_days_provider.dart';
import 'package:azkar/providers/prayer_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FortyDaysScreen displays legend and handles small screen widths without overflow', (tester) async {
    // Set screen to very narrow width (320px) to verify overflow resistance
    tester.view.physicalSize = const Size(320 * 3, 600 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    FlutterErrorDetails? errorDetails;
    FlutterError.onError = (details) {
      errorDetails = details;
    };

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

    if (errorDetails != null) {
      debugPrint('OVERFLOW DIAGNOSTICS: ${errorDetails!.summary}');
      debugPrint('FULL DETAILS:\n${errorDetails!.toString()}');
    }
    expect(errorDetails, isNull);
  });

  testWidgets('FortyDaysScreen streak and day counter counts both Dark Green (all 5) and Light Green (Fajr+Isha) days', (tester) async {
    final now = DateTime.now();
    final day1 = now.subtract(const Duration(days: 2));
    final day2 = now.subtract(const Duration(days: 1));

    final testState = {
      'startDate': day1.toIso8601String(),
      'currentDayIndex': 2,
      'todaysPrayers': {
        'الفجر': {'prayerName': 'الفجر', 'isCompleted': true},
        'الظهر': {'prayerName': 'الظهر', 'isCompleted': false},
        'العصر': {'prayerName': 'العصر', 'isCompleted': false},
        'المغرب': {'prayerName': 'المغرب', 'isCompleted': false},
        'العشاء': {'prayerName': 'العشاء', 'isCompleted': true},
      },
      'savedMosques': [],
      'history': [
        // Day 1: Dark Green (all 5)
        {
          'dayIndex': 0,
          'date': day1.toIso8601String(),
          'prayers': {
            'الفجر': {'prayerName': 'الفجر', 'isCompleted': true},
            'الظهر': {'prayerName': 'الظهر', 'isCompleted': true},
            'العصر': {'prayerName': 'العصر', 'isCompleted': true},
            'المغرب': {'prayerName': 'المغرب', 'isCompleted': true},
            'العشاء': {'prayerName': 'العشاء', 'isCompleted': true},
          },
          'isSuccess': true,
        },
        // Day 2: Light Green (Fajr & Isha only)
        {
          'dayIndex': 1,
          'date': day2.toIso8601String(),
          'prayers': {
            'الفجر': {'prayerName': 'الفجر', 'isCompleted': true},
            'الظهر': {'prayerName': 'الظهر', 'isCompleted': false},
            'العصر': {'prayerName': 'العصر', 'isCompleted': false},
            'المغرب': {'prayerName': 'المغرب', 'isCompleted': false},
            'العشاء': {'prayerName': 'العشاء', 'isCompleted': true},
          },
          'isSuccess': true,
        },
      ],
      'lastUpdatedDate': now.toIso8601String(),
    };

    SharedPreferences.setMockInitialValues({
      'fortyDaysState': json.encode(testState),
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

    // Streak should be 3 (Day 1: all 5 + Day 2: Fajr+Isha + Today: Fajr+Isha)
    expect(find.text('السلسلة الحالية: 3 من 40 يوم'), findsOneWidget);

    // Breakdown should show 1 full day and 2 Fajr+Isha days
    expect(find.text('صلوات كاملة: 1'), findsOneWidget);
    expect(find.text('فجر وعشاء: 2'), findsOneWidget);
  });
}
