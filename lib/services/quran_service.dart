import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import '../models/quran_models.dart';

class QuranService {
  static final QuranService _instance = QuranService._internal();
  factory QuranService() => _instance;
  QuranService._internal();

  // In-memory caches
  final Map<int, QuranPageData> _pageCache = {};
  List<QuranSurah>? _cachedSurahs;
  List<QuranJuz>? _cachedJuzs;

  Map<String, dynamic>? _cachedMeanings;
  Map<String, dynamic>? _cachedTafsir;
  List<QuranReciter>? _cachedReciters;
  Map<String, dynamic>? _cachedSubjects;
  String? _cachedDoaa;
  String? _cachedWaqf;

  /// Loads word meanings JSON from assets
  Future<Map<String, dynamic>> _loadMeanings() async {
    if (_cachedMeanings != null) return _cachedMeanings!;
    try {
      final str = await rootBundle.loadString('assets/quran_data/word_meanings.json');
      _cachedMeanings = jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      _cachedMeanings = {};
    }
    return _cachedMeanings!;
  }

  /// Loads tafsir JSON from assets
  Future<Map<String, dynamic>> _loadTafsir() async {
    if (_cachedTafsir != null) return _cachedTafsir!;
    try {
      final str = await rootBundle.loadString('assets/quran_data/tafsir.json');
      _cachedTafsir = jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      _cachedTafsir = {};
    }
    return _cachedTafsir!;
  }

  /// Loads reciters list
  Future<List<QuranReciter>> getReciters() async {
    if (_cachedReciters != null) return _cachedReciters!;
    try {
      final str = await rootBundle.loadString('assets/quran_data/reciters.json');
      final list = jsonDecode(str) as List;
      _cachedReciters = list.map((i) => QuranReciter.fromJson(i as Map<String, dynamic>)).toList();
    } catch (_) {
      _cachedReciters = [];
    }
    return _cachedReciters!;
  }

  /// EveryAyah CDN folders for verse-by-verse recitation
  static const Map<String, String> everyAyahFolders = {
    'afasy': 'Alafasy_128kbps',
    'minshawi': 'Minshawy_Murattal_128kbps',
    'husary': 'Husary_128kbps',
    'abdulbasit': 'Abdul_Basit_Murattal_192kbps',
    'maher': 'MaherAlMuaiqly128kbps',
    'shatri': 'Abu_Bakr_Ash-Shaatree_128kbps',
    'ghamdi': 'Ghamadi_40kbps',
    'ajamy': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    'hudhaify': 'Hudhaify_128kbps',
    'yasser': 'Yasser_Ad-Dussary_128kbps',
  };

  /// Builds MP3 audio URL for a given reciter and surah
  String getAudioUrl(String baseUrl, int surahNumber) {
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final s = surahNumber.toString().padLeft(3, '0');
    return '$cleanBase/$s.mp3';
  }

  /// Builds MP3 audio URL for a specific verse from EveryAyah CDN
  String getVerseAudioUrl({
    required String reciterId,
    required int surahNumber,
    required int verseNumber,
  }) {
    final folder = everyAyahFolders[reciterId] ?? 'Alafasy_128kbps';
    final s = surahNumber.toString().padLeft(3, '0');
    final v = verseNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$folder/$s$v.mp3';
  }

  /// Returns Tafsir text for a specific verse
  Future<String?> getTafsir(int surah, int verse) async {
    final tafsirMap = await _loadTafsir();
    final key = '${surah}_$verse';
    return tafsirMap[key] as String?;
  }

  /// Returns Tafsir for all verses on a specific page
  Future<List<Map<String, dynamic>>> getPageTafsir(int pageNumber) async {
    final tafsirMap = await _loadTafsir();
    final pageSegments = quran.getPageData(pageNumber);
    final results = <Map<String, dynamic>>[];

    for (final seg in pageSegments) {
      final surah = seg['surah']!;
      final start = seg['start']!;
      final end = seg['end']!;
      final surahName = quran.getSurahNameArabic(surah);

      for (int v = start; v <= end; v++) {
        final key = '${surah}_$v';
        final tafsirText = tafsirMap[key] as String? ?? 'تفسير هذه الآية غير متوفر حالياً.';
        final verseText = quran.getVerse(surah, v, verseEndSymbol: false);

        results.add({
          'surah': surah,
          'surahName': surahName,
          'verse': v,
          'verseText': verseText,
          'tafsir': tafsirText,
        });
      }
    }
    return results;
  }

  /// Returns word meanings for a specific verse
  Future<List<QuranVerseMeaning>> getWordMeanings(int surah, int verse) async {
    final meaningsMap = await _loadMeanings();
    final key = '${surah}_$verse';
    final raw = meaningsMap[key] as List?;
    if (raw == null) return [];
    return raw.map((i) => QuranVerseMeaning.fromJson(i as Map<String, dynamic>)).toList();
  }

  /// Returns word meanings for all verses on a specific page
  Future<List<Map<String, dynamic>>> getPageWordMeanings(int pageNumber) async {
    final meaningsMap = await _loadMeanings();
    final pageSegments = quran.getPageData(pageNumber);
    final results = <Map<String, dynamic>>[];

    for (final seg in pageSegments) {
      final surah = seg['surah']!;
      final start = seg['start']!;
      final end = seg['end']!;
      final surahName = quran.getSurahNameArabic(surah);

      for (int v = start; v <= end; v++) {
        final key = '${surah}_$v';
        final raw = meaningsMap[key] as List?;
        if (raw != null && raw.isNotEmpty) {
          for (final item in raw) {
            results.add({
              'surah': surah,
              'surahName': surahName,
              'verse': v,
              'word': item['word'] as String,
              'meaning': item['meaning'] as String,
            });
          }
        }
      }
    }
    return results;
  }

  /// Returns full text of Du'a Khatm Al-Quran
  Future<String> getDoaaKhatm() async {
    if (_cachedDoaa != null) return _cachedDoaa!;
    try {
      _cachedDoaa = await rootBundle.loadString('assets/quran_data/doaa_khatm.txt');
    } catch (_) {
      _cachedDoaa = '';
    }
    return _cachedDoaa!;
  }

  /// Returns full text of Waqf Marks guide
  Future<String> getWaqfMarks() async {
    if (_cachedWaqf != null) return _cachedWaqf!;
    try {
      _cachedWaqf = await rootBundle.loadString('assets/quran_data/waqf_marks.txt');
    } catch (_) {
      _cachedWaqf = '';
    }
    return _cachedWaqf!;
  }

  /// Returns thematic subjects for a surah
  Future<List<QuranSubject>> getSurahSubjects(int surahNumber) async {
    if (_cachedSubjects == null) {
      try {
        final str = await rootBundle.loadString('assets/quran_data/subjects.json');
        _cachedSubjects = jsonDecode(str) as Map<String, dynamic>;
      } catch (_) {
        _cachedSubjects = {};
      }
    }
    final rawList = _cachedSubjects?[surahNumber.toString()] as List?;
    if (rawList == null) return [];
    return rawList.map((i) => QuranSubject.fromJson(i as Map<String, dynamic>)).toList();
  }

  /// Retrieves page data asynchronously with caching
  Future<QuranPageData> getPageData(int pageNumber) async {
    if (pageNumber < 1) pageNumber = 1;
    if (pageNumber > 604) pageNumber = 604;

    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }

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

  QuranPageData _buildPageData(int pageNumber) {
    final rawItems = quran.getPageData(pageNumber);
    if (rawItems.isEmpty) {
      return QuranPageData(
        pageNumber: pageNumber,
        juzNumber: 1,
        primarySurahName: 'الفاتحة',
      );
    }

    final firstSurah = rawItems.first['surah']!;
    final firstVerse = rawItems.first['start']!;
    final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
    final primarySurahName = quran.getSurahNameArabic(firstSurah);

    return QuranPageData(
      pageNumber: pageNumber,
      juzNumber: juzNumber,
      primarySurahName: primarySurahName,
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
    text = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
    text = text.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll('ة', 'ه');
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
