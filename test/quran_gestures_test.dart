import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:azkar/models/quran_models.dart';
import 'package:azkar/providers/quran_provider.dart';
import 'package:azkar/services/quran_audio_service.dart';
import 'package:azkar/services/quran_service.dart';
import 'package:azkar/widgets/quran_page_widget.dart';

void main() {
  testWidgets('QuranPageWidget responds to single tap and double tap', (WidgetTester tester) async {
    bool singleTapped = false;
    bool doubleTapped = false;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => QuranProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: QuranPageWidget(
              pageNumber: 1,
              filter: QuranReadingFilter.original,
              onTap: () {
                singleTapped = true;
              },
              onDoubleTap: () {
                doubleTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify widget rendered
    expect(find.byType(QuranPageWidget), findsOneWidget);

    // Test single tap
    await tester.tap(find.byType(QuranPageWidget));
    await tester.pump(const Duration(milliseconds: 400));
    expect(singleTapped, isTrue);

    // Reset and test double tap
    singleTapped = false;
    await tester.tap(find.byType(QuranPageWidget));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(QuranPageWidget));
    await tester.pumpAndSettle();
    expect(doubleTapped, isTrue);
  });

  test('QuranService generates correct EveryAyah verse audio URL', () {
    final quranService = QuranService();
    final url = quranService.getVerseAudioUrl(
      reciterId: 'afasy',
      surahNumber: 2,
      verseNumber: 255,
    );
    expect(url, equals('https://everyayah.com/data/Alafasy_128kbps/002255.mp3'));
  });

  test('QuranAudioService handles verse mode and navigation states', () {
    final audio = QuranAudioService();
    expect(audio.isVerseMode, isFalse);
    expect(audio.currentVerse, isNull);
  });
}
