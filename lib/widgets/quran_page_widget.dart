import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quran_models.dart';
import '../providers/quran_provider.dart';
import 'package:quran/quran.dart' as quran;

class QuranPageWidget extends StatelessWidget {
  final QuranPageData pageData;
  final double fontSize;
  final QuranThemeType themeType;

  const QuranPageWidget({
    super.key,
    required this.pageData,
    required this.fontSize,
    required this.themeType,
  });

  @override
  Widget build(BuildContext context) {
    // Theme color definitions
    final Color bgColor;
    final Color innerBgColor;
    final Color textColor;
    final Color borderColor;
    final Color accentBorderColor;
    final Color headerFooterColor;
    final Color bannerBgColor;
    final Color bannerTextColor;

    switch (themeType) {
      case QuranThemeType.cream:
        bgColor = const Color(0xFFFAF6EE);
        innerBgColor = const Color(0xFFFFFDF9);
        textColor = const Color(0xFF1E2827);
        borderColor = const Color(0xFFCBB282);
        accentBorderColor = const Color(0xFFE5D8BA);
        headerFooterColor = const Color(0xFF5A4928);
        bannerBgColor = const Color(0xFFF3EBDA);
        bannerTextColor = const Color(0xFF1E3A37);
        break;
      case QuranThemeType.sepia:
        bgColor = const Color(0xFFF0E4CE);
        innerBgColor = const Color(0xFFF7EEDD);
        textColor = const Color(0xFF2E2419);
        borderColor = const Color(0xFFBCA073);
        accentBorderColor = const Color(0xFFD8C7A3);
        headerFooterColor = const Color(0xFF5D472B);
        bannerBgColor = const Color(0xFFE6D6B9);
        bannerTextColor = const Color(0xFF3F2F1C);
        break;
      case QuranThemeType.dark:
        bgColor = const Color(0xFF101414);
        innerBgColor = const Color(0xFF161B1B);
        textColor = const Color(0xFFE2E9E8);
        borderColor = const Color(0xFF4A4432);
        accentBorderColor = const Color(0xFF2C3534);
        headerFooterColor = const Color(0xFF9E9580);
        bannerBgColor = const Color(0xFF1E2827);
        bannerTextColor = const Color(0xFFD6C8A7);
        break;
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: innerBgColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: themeType == QuranThemeType.dark ? 0.4 : 0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: borderColor, width: 1.6),
        ),
        child: Container(
          margin: const EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: accentBorderColor, width: 1.0),
          ),
          child: Column(
            children: [
              // Top Mushaf Header (Surah & Juz)
              _buildTopHeader(headerFooterColor, borderColor),

              // Divider under header
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: accentBorderColor,
              ),

              // Page Verses & Banners Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: pageData.segments.map((segment) {
                        return _buildSurahSegment(
                          segment: segment,
                          textColor: textColor,
                          bannerBgColor: bannerBgColor,
                          bannerTextColor: bannerTextColor,
                          borderColor: borderColor,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Divider above footer
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: accentBorderColor,
              ),

              // Bottom Mushaf Footer (Page number)
              _buildBottomFooter(headerFooterColor, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(Color textColor, Color goldColor) {
    final arabicJuz = _toArabicDigits(pageData.juzNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Juz indicator
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 14, color: goldColor),
              const SizedBox(width: 4),
              Text(
                'الجزء $arabicJuz',
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),

          // Center decorative symbol
          Text(
            '۞',
            style: TextStyle(
              fontSize: 14,
              color: goldColor,
            ),
          ),

          // Right: Primary Surah name
          Row(
            children: [
              Text(
                'سُورَةُ ${pageData.primarySurahName}',
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.menu_book, size: 14, color: goldColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFooter(Color textColor, Color goldColor) {
    final arabicPage = _toArabicDigits(pageData.pageNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '—  $arabicPage  —',
            style: GoogleFonts.amiri(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahSegment({
    required QuranSurahPageSegment segment,
    required Color textColor,
    required Color bannerBgColor,
    required Color bannerTextColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah Ornate Header Banner if Surah starts on this page
        if (segment.isSurahStart) ...[
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 8),
            decoration: BoxDecoration(
              color: bannerBgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ornate background flourish
                Positioned(
                  left: 8,
                  child: Text('⚜', style: TextStyle(color: borderColor, fontSize: 16)),
                ),
                Positioned(
                  right: 8,
                  child: Text('⚜', style: TextStyle(color: borderColor, fontSize: 16)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 32),
                  child: Text(
                    'سُورَةُ ${segment.surahNameArabic}',
                    style: GoogleFonts.amiri(
                      fontSize: fontSize + 1,
                      fontWeight: FontWeight.bold,
                      color: bannerTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Basmala if applicable
        if (segment.showBasmala) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: Text(
              quran.basmala,
              style: GoogleFonts.amiri(
                fontSize: fontSize + 1,
                fontWeight: FontWeight.bold,
                color: bannerTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // Flowing Verses Block (Justified text wrap with ayah end marks)
        Directionality(
          textDirection: TextDirection.rtl,
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              children: segment.verses.map((verse) {
                final ayahNumArabic = _toArabicDigits(verse.verseNumber);
                return TextSpan(
                  children: [
                    TextSpan(
                      text: '${verse.text} ',
                      style: GoogleFonts.amiri(
                        fontSize: fontSize,
                        height: 2.15,
                        color: textColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Ayah end symbol with decorated numbering
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1.0),
                        ),
                        child: Text(
                          ayahNumArabic,
                          style: GoogleFonts.amiri(
                            fontSize: (fontSize * 0.58).clamp(11.0, 18.0),
                            fontWeight: FontWeight.bold,
                            color: bannerTextColor,
                          ),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' '),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  static String _toArabicDigits(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i) - 48;
      if (code >= 0 && code <= 9) {
        buffer.write(arabicDigits[code]);
      } else {
        buffer.write(s[i]);
      }
    }
    return buffer.toString();
  }
}
