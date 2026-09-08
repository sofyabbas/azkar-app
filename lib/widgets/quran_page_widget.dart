import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../models/quran_models.dart';
import '../providers/quran_provider.dart';
import '../services/quran_service.dart';

class QuranPageWidget extends StatefulWidget {
  final int pageNumber;
  final QuranReadingFilter filter;
  final QuranPageFit fit;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(int surah, int verse)? onVerseTap;
  final int? selectedSurah;
  final int? selectedVerse;

  const QuranPageWidget({
    super.key,
    required this.pageNumber,
    required this.filter,
    this.fit = QuranPageFit.stretchWidth,
    this.onTap,
    this.onDoubleTap,
    this.onVerseTap,
    this.selectedSurah,
    this.selectedVerse,
  });

  @override
  State<QuranPageWidget> createState() => _QuranPageWidgetState();
}

class _QuranPageWidgetState extends State<QuranPageWidget> {
  final QuranService _quranService = QuranService();
  final Map<String, LongPressGestureRecognizer> _longPressRecognizers = {};

  @override
  void dispose() {
    for (final r in _longPressRecognizers.values) {
      r.dispose();
    }
    _longPressRecognizers.clear();
    super.dispose();
  }

  String _toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((e) => digits[int.parse(e)]).join('');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final pageData = _quranService.getPageDataSync(widget.pageNumber);
    final segments = quran.getPageData(widget.pageNumber);

    // Filter themes
    Color bgColor;
    Color textColor;
    Color borderColor;
    Color goldAccent;
    Color surahBannerBg;
    Color surahBannerBorder;

    switch (widget.filter) {
      case QuranReadingFilter.original:
        bgColor = const Color(0xFFFBF8F1);
        textColor = const Color(0xFF1B1B1B);
        borderColor = const Color(0xFFD9C8A5);
        goldAccent = const Color(0xFFB88E3E);
        surahBannerBg = const Color(0xFFF5EFE0);
        surahBannerBorder = const Color(0xFFCBB282);
        break;
      case QuranReadingFilter.sepia:
        bgColor = const Color(0xFFF4E8D1);
        textColor = const Color(0xFF352516);
        borderColor = const Color(0xFFCBB180);
        goldAccent = const Color(0xFF9E6F28);
        surahBannerBg = const Color(0xFFEBDAB9);
        surahBannerBorder = const Color(0xFFB89658);
        break;
      case QuranReadingFilter.dark:
        bgColor = const Color(0xFF121415);
        textColor = const Color(0xFFE8ECEF);
        borderColor = const Color(0xFF2C3236);
        goldAccent = const Color(0xFFD4AF37);
        surahBannerBg = const Color(0xFF1E2327);
        surahBannerBorder = const Color(0xFF424C53);
        break;
      case QuranReadingFilter.mint:
        bgColor = const Color(0xFFEFF7F2);
        textColor = const Color(0xFF132822);
        borderColor = const Color(0xFFABC5B6);
        goldAccent = const Color(0xFF2C6B56);
        surahBannerBg = const Color(0xFFE0EEE5);
        surahBannerBorder = const Color(0xFF86AB97);
        break;
    }

    final double baseFontSize = provider.fontSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Top Page Header (Surah name right, Juz/Hizb left)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: borderColor.withValues(alpha: 0.6), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سورة ${pageData.primarySurahName}',
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: goldAccent,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star_rate_rounded, size: 12, color: goldAccent),
                        const SizedBox(width: 4),
                        Text(
                          'الجزء ${pageData.juzNumber}',
                          style: GoogleFonts.amiri(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Middle Quran Page Body with Islamic Border
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 2.5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final seg in segments) ...[
                              _buildSegmentWidget(
                                seg: seg,
                                textColor: textColor,
                                goldAccent: goldAccent,
                                surahBannerBg: surahBannerBg,
                                surahBannerBorder: surahBannerBorder,
                                baseFontSize: baseFontSize,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Bottom Page Footer with Page Number
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                margin: const EdgeInsets.only(top: 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _toArabicDigits(widget.pageNumber),
                      style: GoogleFonts.amiri(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: goldAccent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentWidget({
    required Map<String, dynamic> seg,
    required Color textColor,
    required Color goldAccent,
    required Color surahBannerBg,
    required Color surahBannerBorder,
    required double baseFontSize,
  }) {
    final int surah = seg['surah']!;
    final int start = seg['start']!;
    final int end = seg['end']!;

    final bool isSurahStart = start == 1;
    final String surahName = quran.getSurahNameArabic(surah);
    final int verseCount = quran.getVerseCount(surah);
    final String place = quran.getPlaceOfRevelation(surah) == 'Makkah' ? 'مكية' : 'مدنية';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah Banner if it's the start of the surah
        if (isSurahStart) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: surahBannerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surahBannerBorder, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$place • آياتها ${_toArabicDigits(verseCount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'سورة $surahName',
                  style: GoogleFonts.amiri(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: goldAccent,
                  ),
                ),
              ],
            ),
          ),
          // Basmalah (except for Surah 9 and Surah 1)
          if (surah != 9 && surah != 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: baseFontSize + 1,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],

        // Flow of verses
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text.rich(
            TextSpan(
              children: [
                for (int v = start; v <= end; v++) ...[
                  _buildVerseSpan(
                    surah: surah,
                    verse: v,
                    textColor: textColor,
                    goldAccent: goldAccent,
                    baseFontSize: baseFontSize,
                  ),
                ],
              ],
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  TextSpan _buildVerseSpan({
    required int surah,
    required int verse,
    required Color textColor,
    required Color goldAccent,
    required double baseFontSize,
  }) {
    final bool isSelected = widget.selectedSurah == surah && widget.selectedVerse == verse;
    final String verseText = quran.getVerse(surah, verse, verseEndSymbol: false);
    final String verseEnd = ' ﴿${_toArabicDigits(verse)}﴾ ';
    final verseKey = '$surah:$verse';

    final recognizer = _longPressRecognizers.putIfAbsent(
      verseKey,
      () => LongPressGestureRecognizer()
        ..onLongPress = () {
          if (widget.onVerseTap != null) {
            widget.onVerseTap!(surah, verse);
          }
        },
    );

    return TextSpan(
      text: '$verseText ',
      recognizer: recognizer,
      style: GoogleFonts.amiri(
        fontSize: baseFontSize,
        height: 2.2,
        color: textColor,
        backgroundColor: isSelected ? goldAccent.withValues(alpha: 0.25) : null,
      ),
      children: [
        TextSpan(
          text: verseEnd,
          recognizer: recognizer,
          style: GoogleFonts.amiri(
            fontSize: baseFontSize - 3,
            fontWeight: FontWeight.bold,
            color: goldAccent,
          ),
        ),
      ],
    );
  }
}
