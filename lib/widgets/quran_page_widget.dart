import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  final List<TapGestureRecognizer> _tapRecognizers = [];

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    _tapRecognizers.clear();
  }

  String _toArabicDigits(int number) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i) - 48;
      if (code >= 0 && code <= 9) {
        buffer.write(digits[code]);
      } else {
        buffer.write(s[i]);
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _clearRecognizers();
    final provider = context.watch<QuranProvider>();
    final pageData = _quranService.getPageDataSync(widget.pageNumber);
    final segments = quran.getPageData(widget.pageNumber);

    // Filter themes matching authentic Mushaf styles
    Color bgColor;
    Color textColor;
    Color borderColor;
    Color innerBorderColor;
    Color goldAccent;
    Color bannerBgColor;
    Color highlightColor;

    switch (widget.filter) {
      case QuranReadingFilter.original:
        bgColor = const Color(0xFFFBF8F1); // Natural Madinah Mushaf paper
        textColor = const Color(0xFF1B1B1B);
        borderColor = const Color(0xFFC5A059); // Authentic Antique Gold
        innerBorderColor = const Color(0xFFDFCBA2);
        goldAccent = const Color(0xFF9E7B35);
        bannerBgColor = const Color(0xFFF6EFE0);
        highlightColor = const Color(0xFFE8D39A).withValues(alpha: 0.50);
        break;
      case QuranReadingFilter.sepia:
        bgColor = const Color(0xFFF4E8D1); // Warm eye-comfort sepia
        textColor = const Color(0xFF332214);
        borderColor = const Color(0xFFB08C4A);
        innerBorderColor = const Color(0xFFD2B582);
        goldAccent = const Color(0xFF8A6223);
        bannerBgColor = const Color(0xFFEBD9B7);
        highlightColor = const Color(0xFFD9BD88).withValues(alpha: 0.50);
        break;
      case QuranReadingFilter.dark:
        bgColor = const Color(0xFF121415); // Night OLED Black
        textColor = const Color(0xFFE6EAEB);
        borderColor = const Color(0xFF9A8044);
        innerBorderColor = const Color(0xFF2C3236);
        goldAccent = const Color(0xFFD4AF37);
        bannerBgColor = const Color(0xFF1D2225);
        highlightColor = const Color(0xFFD4AF37).withValues(alpha: 0.32);
        break;
      case QuranReadingFilter.mint:
        bgColor = const Color(0xFFEFF7F2); // Soft mint reading tone
        textColor = const Color(0xFF11241D);
        borderColor = const Color(0xFF4C876F);
        innerBorderColor = const Color(0xFFA3CEC0);
        goldAccent = const Color(0xFF2A6854);
        bannerBgColor = const Color(0xFFDCEDE3);
        highlightColor = const Color(0xFF55BA96).withValues(alpha: 0.36);
        break;
    }

    final double baseFontSize = provider.fontSize;
    final bool isFirstTwoPages = widget.pageNumber <= 2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: innerBorderColor, width: 1.0),
              ),
              child: Column(
                children: [
                  // 1. Top Page Header
                  _buildTopHeader(pageData, textColor, borderColor, innerBorderColor, goldAccent),

                  // Decorative divider
                  Container(
                    height: 1.2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: innerBorderColor.withValues(alpha: 0.8),
                  ),

                  // 2. Middle Quran Page Body (Interactive & Pinch-to-zoom)
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 1.0,
                      maxScale: 2.6,
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isFirstTwoPages ? 20.0 : 12.0,
                          vertical: isFirstTwoPages ? 16.0 : 6.0,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: isFirstTwoPages
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              for (final seg in segments) ...[
                                _buildSegmentWidget(
                                  seg: seg,
                                  textColor: textColor,
                                  goldAccent: goldAccent,
                                  borderColor: borderColor,
                                  innerBorderColor: innerBorderColor,
                                  bannerBgColor: bannerBgColor,
                                  highlightColor: highlightColor,
                                  baseFontSize: baseFontSize,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Decorative divider
                  Container(
                    height: 1.2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: innerBorderColor.withValues(alpha: 0.8),
                  ),

                  // 3. Bottom Page Footer
                  _buildBottomFooter(widget.pageNumber, textColor, borderColor, innerBorderColor, goldAccent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    QuranPageData pageData,
    Color textColor,
    Color borderColor,
    Color innerBorderColor,
    Color goldAccent,
  ) {
    final arabicJuz = _toArabicDigits(pageData.juzNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Surah Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 14, color: goldAccent),
              const SizedBox(width: 5),
              Text(
                'سُورَةُ ${pageData.primarySurahName}',
                style: const TextStyle(
                  fontFamily: 'UthmanTN',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),

          // Center: Decorative Emblem
          Text(
            '۞',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: goldAccent,
            ),
          ),

          // Right: Juz indicator
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'الجزء $arabicJuz',
                style: const TextStyle(
                  fontFamily: 'UthmanTN',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Image.asset(
                'assets/quran_ui/joza_mark.png',
                width: 15,
                height: 15,
                errorBuilder: (_, __, ___) => Icon(Icons.star_rate_rounded, size: 14, color: goldAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFooter(
    int pageNumber,
    Color textColor,
    Color borderColor,
    Color innerBorderColor,
    Color goldAccent,
  ) {
    final arabicPage = _toArabicDigits(pageNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: innerBorderColor.withValues(alpha: 0.9), width: 1.0),
            ),
            child: Text(
              '—  $arabicPage  —',
              style: const TextStyle(
                fontFamily: 'UthmanTN',
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentWidget({
    required Map<String, dynamic> seg,
    required Color textColor,
    required Color goldAccent,
    required Color borderColor,
    required Color innerBorderColor,
    required Color bannerBgColor,
    required Color highlightColor,
    required double baseFontSize,
  }) {
    final int surah = seg['surah']!;
    final int start = seg['start']!;
    final int end = seg['end']!;

    final bool isSurahStart = start == 1;
    final String surahName = quran.getSurahNameArabic(surah);
    final int verseCount = quran.getVerseCount(surah);
    final String place = quran.getPlaceOfRevelation(surah) == 'Makkah' ? 'مَكِّيَّة' : 'مَدَنِيَّة';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Ornate Surah Header Banner if it's the start of the surah
        if (isSurahStart) ...[
          _buildSurahHeaderBanner(
            surah: surah,
            surahName: surahName,
            verseCount: verseCount,
            place: place,
            borderColor: borderColor,
            innerBorderColor: innerBorderColor,
            bannerBgColor: bannerBgColor,
            goldAccent: goldAccent,
          ),
        ],

        // 2. Basmala (Every surah except At-Tawbah 9 and Al-Fatiha 1 which has it as verse 1)
        if (isSurahStart && surah != 9 && surah != 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Center(
              child: Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UthmanTN',
                  fontSize: baseFontSize + 1.5,
                  fontWeight: FontWeight.bold,
                  height: 1.8,
                  color: goldAccent,
                ),
              ),
            ),
          ),
        ],

        // 3. Flowing Verses Block (Justified Uthmani text with interactive verse tap)
        Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
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
                      borderColor: borderColor,
                      highlightColor: highlightColor,
                      baseFontSize: baseFontSize,
                    ),
                  ],
                ],
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSurahHeaderBanner({
    required int surah,
    required String surahName,
    required int verseCount,
    required String place,
    required Color borderColor,
    required Color innerBorderColor,
    required Color bannerBgColor,
    required Color goldAccent,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      height: 52,
      decoration: BoxDecoration(
        color: bannerBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left Ornate Floral Flourish
          Positioned(
            left: 2,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/quran_ui/tarwisa_left.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Right Ornate Floral Flourish
          Positioned(
            right: 2,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/quran_ui/tarwisa_right.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

          // Center Surah Information & Title
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'سُورَةُ $surahName',
                  style: TextStyle(
                    fontFamily: 'UthmanTN',
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: goldAccent,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$place • آيَاتُهَا ${_toArabicDigits(verseCount)}',
                  style: TextStyle(
                    fontFamily: 'UthmanTN',
                    fontSize: 11.5,
                    color: goldAccent.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InlineSpan _buildVerseSpan({
    required int surah,
    required int verse,
    required Color textColor,
    required Color goldAccent,
    required Color borderColor,
    required Color highlightColor,
    required double baseFontSize,
  }) {
    final bool isSelected = widget.selectedSurah == surah && widget.selectedVerse == verse;
    final String verseText = quran.getVerse(surah, verse, verseEndSymbol: false);
    final String ayahNumArabic = _toArabicDigits(verse);

    final recognizer = widget.onVerseTap != null
        ? (TapGestureRecognizer()
          ..onTap = () {
            widget.onVerseTap?.call(surah, verse);
          })
        : null;
    if (recognizer != null) {
      _tapRecognizers.add(recognizer);
    }

    return TextSpan(
      recognizer: recognizer,
      style: TextStyle(
        backgroundColor: isSelected ? highlightColor : Colors.transparent,
      ),
      children: [
        // The sacred verse text in King Fahd Complex Uthman Taha font
        TextSpan(
          text: '$verseText ',
          style: TextStyle(
            fontFamily: 'UthmanTN',
            fontSize: baseFontSize,
            height: 2.15,
            color: textColor,
            fontWeight: FontWeight.normal,
          ),
        ),

        // The ornate circular ayah end badge
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: widget.onVerseTap != null ? () => widget.onVerseTap?.call(surah, verse) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? goldAccent.withValues(alpha: 0.22) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? goldAccent : borderColor.withValues(alpha: 0.85),
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Text(
                ayahNumArabic,
                style: TextStyle(
                  fontFamily: 'UthmanTN',
                  fontSize: (baseFontSize * 0.58).clamp(11.0, 16.0),
                  fontWeight: FontWeight.bold,
                  color: goldAccent,
                ),
              ),
            ),
          ),
        ),

        const TextSpan(text: ' '),
      ],
    );
  }
}
