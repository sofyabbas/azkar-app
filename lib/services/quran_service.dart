import 'dart:async';
import 'package:quran/quran.dart' as quran;
import '../models/quran_models.dart';

class QuranService {
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  // In-memory cache for page data to avoid repeated parsing
  final Map<int, QuranPageData> _pageCache = {};

  // Cached surahs and juzs list
  List<QuranSurah>? _cachedSurahs;
  List<QuranJuz>? _cachedJuzs;

  /// Retrieves page data asynchronously with caching
  Future<QuranPageData> getPageData(int pageNumber) async {
    if (pageNumber < 1) pageNumber = 1;
    if (pageNumber > 604) pageNumber = 604;

    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    // Run building of page data
    final pageData = _buildPageData(pageNumber);
    _pageCache[pageNumber] = pageData;
    return pageData;
  }

  /// Synchronous retrieval if cached, otherwise builds immediately
  QuranPageData getPageDataSync(int pageNumber) {
    if (pageNumber < 1) pageNumber = 1;
    if (pageNumber > 604) pageNumber = 604;

    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

    final pageData = _buildPageData(pageNumber);
    _pageCache[pageNumber] = pageData;
    return pageData;
  }

  /// Pre-fetches surrounding pages into memory for smooth flipping
  Future<void> prefetchPages(int currentPage, {int radius = 3}) async {
    final start = (currentPage - radius).clamp(1, 604);
    final end = (currentPage + radius).clamp(1, 604);

    for (int p = start; p <= end; p++) {
      if (!_pageCache.containsKey(p)) {
        // Schedule next event loop tick
        await Future.microtask(() {
          if (!_pageCache.containsKey(p)) {
            _pageCache[p] = _buildPageData(p);
          }
        });
      }
    }
  }

  QuranPageData _buildPageData(int pageNumber) {
    final rawItems = quran.getPageData(pageNumber);
    if (rawItems.isEmpty) {
      return QuranPageData(
        pageNumber: pageNumber,
        juzNumber: 1,
        primarySurahName: 'الفاتحة',
        segments: const [],
      );
    }

    final firstSurah = rawItems.first['surah']!;
    final firstVerse = rawItems.first['start']!;
    final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
    final primarySurahName = quran.getSurahNameArabic(firstSurah);

    final segments = <QuranSurahPageSegment>[];

    for (final raw in rawItems) {
      final sNum = raw['surah']!;
      final start = raw['start']!;
      final end = raw['end']!;

      final surahNameAr = quran.getSurahNameArabic(sNum);
      final surahNameEn = quran.getSurahName(sNum);
      final isStart = start == 1;
      final showBasmala = sNum != 1 && sNum != 9 && isStart;

      final verses = <QuranVerse>[];
      for (int v = start; v <= end; v++) {
        String vText = quran.getVerse(sNum, v, verseEndSymbol: true);

        // Strip repeated Basmala from first ayah if present in data
        if (showBasmala && v == 1) {
          const cleanBasmala = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
          if (vText.startsWith(cleanBasmala)) {
            vText = vText.substring(cleanBasmala.length).trim();
          }
        }

        verses.add(QuranVerse(
          surahNumber: sNum,
          verseNumber: v,
          text: vText,
          juzNumber: quran.getJuzNumber(sNum, v),
          pageNumber: pageNumber,
        ));
      }

      segments.add(QuranSurahPageSegment(
        surahNumber: sNum,
        surahNameArabic: surahNameAr,
        surahNameEnglish: surahNameEn,
        startVerse: start,
        endVerse: end,
        isSurahStart: isStart,
        showBasmala: showBasmala,
        verses: verses,
      ));
    }

    return QuranPageData(
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      primarySurahName: primarySurahName,
      segments: segments,
    );
  }

  /// Returns list of all 114 Surahs
  List<QuranSurah> getAllSurahs() {
    if (_cachedSurahs != null) return _cachedSurahs!;

    final list = <QuranSurah>[];
    for (int i = 1; i <= 114; i++) {
      list.add(QuranSurah(
        number: i,
        nameArabic: quran.getSurahNameArabic(i),
        nameEnglish: quran.getSurahName(i),
        versesCount: quran.getVerseCount(i),
        revelationPlace: quran.getPlaceOfRevelation(i),
        startPage: quran.getPageNumber(i, 1),
      ));
    }
    _cachedSurahs = list;
    return list;
  }

  /// Returns list of all 30 Juzs with start locations
  List<QuranJuz> getAllJuzs() {
    if (_cachedJuzs != null) return _cachedJuzs!;

    final list = <QuranJuz>[];
    for (int j = 1; j <= 30; j++) {
      // Find start page of this juz by looking up first page where juzNumber == j
      int startPage = 1;
      int startSurah = 1;
      int startVerse = 1;

      for (int p = 1; p <= 604; p++) {
        final pData = quran.getPageData(p);
        if (pData.isNotEmpty) {
          final s = pData.first['surah']!;
          final v = pData.first['start']!;
          if (quran.getJuzNumber(s, v) == j) {
            startPage = p;
            startSurah = s;
            startVerse = v;
            break;
          }
        }
      }

      list.add(QuranJuz(
        number: j,
        nameArabic: _getJuzArabicName(j),
        startSurah: startSurah,
        startSurahName: quran.getSurahNameArabic(startSurah),
        startVerse: startVerse,
        startPage: startPage,
      ));
    }
    _cachedJuzs = list;
    return list;
  }

  String _getJuzArabicName(int juz) {
    const names = [
      'الجزء الأول',
      'سيقول السفهاء',
      'تلك الرسل',
      'لن تنالوا البر',
      'والمحصنات',
      'لا يحب الله',
      'وإذا سمعوا',
      'ولو أننا',
      'قال الملأ',
      'واعلموا',
      'يعتذرون',
      'وما من دابة',
      'وما أبرئ نفسي',
      'ربما',
      'سبحان الذي',
      'قال ألم',
      'اقترب للناس',
      'قد أفلح',
      'وقال الذين',
      'أمن خلق',
      'اتل ما أوحي',
      'ومن يقنت',
      'وما لي',
      'فمن أظلم',
      'إليه يرد',
      'حم (الأحقاف)',
      'قال فما خطبكم',
      'قد سمع الله',
      'تبارك الذي',
      'عم يتساءلون',
    ];
    if (juz >= 1 && juz <= names.length) {
      return 'الجزء $juz (${names[juz - 1]})';
    }
    return 'الجزء $juz';
  }

  /// Normalizes Arabic text by removing tashkeel and standardizing letters
  String normalizeArabic(String input) {
    var text = input;
    // Remove diacritics / tashkeel
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    // Standardize Alef
    text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    // Standardize Yaa / Alef Maqsoora
    text = text.replaceAll('ى', 'ي');
    // Standardize Taa Marboota
    text = text.replaceAll('ة', 'ه');
    // Remove tatweel
    text = text.replaceAll('ـ', '');
    return text.trim().toLowerCase();
  }

  /// Asynchronous search across Surahs and Verses
  Future<List<QuranSearchResult>> searchVerses(String query, {int limit = 40}) async {
    final cleanQuery = normalizeArabic(query);
    if (cleanQuery.isEmpty) return [];

    final results = <QuranSearchResult>[];

    await Future.microtask(() {
      for (int s = 1; s <= 114; s++) {
        final count = quran.getVerseCount(s);
        final surahName = quran.getSurahNameArabic(s);

        for (int v = 1; v <= count; v++) {
          final rawVerse = quran.getVerse(s, v, verseEndSymbol: false);
          final normVerse = normalizeArabic(rawVerse);

          if (normVerse.contains(cleanQuery)) {
            final page = quran.getPageNumber(s, v);
            final juz = quran.getJuzNumber(s, v);
            results.add(QuranSearchResult(
              surahNumber: s,
              surahName: surahName,
              verseNumber: v,
              text: rawVerse,
              pageNumber: page,
              juzNumber: juz,
            ));

            if (results.length >= limit) return;
          }
        }
      }
    });

    return results;
  }
}
