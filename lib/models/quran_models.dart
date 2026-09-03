enum QuranReadingFilter {
  original, // أصل ورقة المصحف الشريف
  sepia,    // الوضع الدافئ المريح للعين
  dark,     // الوضع الليلي المعكوس للقراءة في الظلام
  mint,     // الوضع الهادئ المخفف لإجهاد العين
}

enum QuranPageFit {
  contain,      // ملاءمة واحتواء الصفحة
  stretchWidth, // فرد كامل على عرض وارتفاع الشاشة
}

class QuranPageData {
  final int pageNumber;
  final int juzNumber;
  final String primarySurahName;

  const QuranPageData({
    required this.pageNumber,
    required this.juzNumber,
    required this.primarySurahName,
  });
}

class QuranSurah {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int versesCount;
  final String revelationPlace;
  final int startPage;

  const QuranSurah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.versesCount,
    required this.revelationPlace,
    required this.startPage,
  });

  bool get isMeccan => revelationPlace.toLowerCase() == 'makkah';
}

class QuranJuz {
  final int number;
  final String nameArabic;
  final int startSurah;
  final String startSurahName;
  final int startVerse;
  final int startPage;

  const QuranJuz({
    required this.number,
    required this.nameArabic,
    required this.startSurah,
    required this.startSurahName,
    required this.startVerse,
    required this.startPage,
  });
}

class QuranBookmark {
  final int pageNumber;
  final String surahName;
  final int juzNumber;
  final DateTime createdAt;

  const QuranBookmark({
    required this.pageNumber,
    required this.surahName,
    required this.juzNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'surahName': surahName,
        'juzNumber': juzNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory QuranBookmark.fromJson(Map<String, dynamic> json) => QuranBookmark(
        pageNumber: json['pageNumber'] as int,
        surahName: json['surahName'] as String,
        juzNumber: json['juzNumber'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class QuranSearchResult {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String text;
  final int pageNumber;
  final int juzNumber;

  const QuranSearchResult({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.text,
    required this.pageNumber,
    required this.juzNumber,
  });
}

