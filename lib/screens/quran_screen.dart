import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageJumpController = TextEditingController();
  String _searchQuery = '';
  int? _bookmarkedPage;

  @override
  void initState() {
    super.initState();
    _loadBookmark();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarkedPage = prefs.getInt('quran_bookmark_page');
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    // Filter surahs based on search query (Arabic or English name)
    final filteredSurahIndices = List<int>.generate(114, (i) => i + 1).where((index) {
      final nameAr = quran.getSurahNameArabic(index);
      final nameEn = quran.getSurahName(index);
      final query = _searchQuery.toLowerCase();
      return nameAr.contains(query) || nameEn.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text(
          'المصحف الشريف',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar container styled with Islamic primary color
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة بالاسم العربي أو الإنجليزي...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          
          // Bookmark Section if bookmark exists
          if (_bookmarkedPage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                color: primaryColor.withValues(alpha: 0.06),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: ListTile(
                  leading: const Icon(Icons.bookmark, color: primaryColor),
                  title: const Text(
                    'الذهاب إلى علامة الحفظ الأخيرة',
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14),
                  ),
                  subtitle: Text(
                    'الصفحة $_bookmarkedPage — الجزء ${quran.getJuzNumber(quran.getPageData(_bookmarkedPage!).first['surah']!, quran.getPageData(_bookmarkedPage!).first['start']!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranReadingScreen(initialPage: _bookmarkedPage!),
                      ),
                    ).then((_) => _loadBookmark());
                  },
                ),
              ),
            ),
          ],

          // Quick Page Jump input field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pageJumpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    onSubmitted: (val) {
                      final page = int.tryParse(val);
                      if (page != null && page >= 1 && page <= 604) {
                        _pageJumpController.clear();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuranReadingScreen(initialPage: page),
                          ),
                        ).then((_) => _loadBookmark());
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرجاء إدخال رقم صفحة صحيح بين 1 و 604')),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'انتقال سريع لرقم صفحة (1 - 604)...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                      prefixIcon: const Icon(Icons.find_in_page_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          final page = int.tryParse(_pageJumpController.text);
                          if (page != null && page >= 1 && page <= 604) {
                            _pageJumpController.clear();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranReadingScreen(initialPage: page),
                              ),
                            ).then((_) => _loadBookmark());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('الرجاء إدخال رقم صفحة صحيح بين 1 و 604')),
                            );
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Surah List title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'سور القرآن الكريم:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Surah List
          Expanded(
            child: filteredSurahIndices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'لم يتم العثور على نتائج لبحثك',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredSurahIndices.length,
                    itemBuilder: (context, index) {
                      final surahIndex = filteredSurahIndices[index];
                      final nameAr = quran.getSurahNameArabic(surahIndex);
                      final nameEn = quran.getSurahName(surahIndex);
                      final revelation = quran.getPlaceOfRevelation(surahIndex);
                      final verses = quran.getVerseCount(surahIndex);
                      final startPage = quran.getPageNumber(surahIndex, 1);
                      final isMeccan = revelation.toLowerCase() == 'makkah';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        color: Colors.white,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuranReadingScreen(initialPage: startPage),
                              ),
                            ).then((_) => _loadBookmark());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            child: Row(
                              children: [
                                // Surah Number Badge decorated
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$surahIndex',
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                
                                // English Name and details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameEn,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            isMeccan ? Icons.wb_sunny_outlined : Icons.mosque_outlined,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isMeccan ? 'مكية' : 'مدنية',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.format_list_numbered, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$verses آية',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Arabic Name & Starting Page (aligned to right)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      nameAr,
                                      style: GoogleFonts.amiri(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'بداية صفحة $startPage',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class QuranReadingScreen extends StatefulWidget {
  final int initialPage;
  const QuranReadingScreen({super.key, required this.initialPage});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  late PageController _pageController;
  late int _currentPage;
  double _fontSize = 22.0;
  int? _bookmarkedPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadBookmark();
    _loadFontSize();
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarkedPage = prefs.getInt('quran_bookmark_page');
    });
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('quran_font_size') ?? 22.0;
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_font_size', size);
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bookmarkedPage == _currentPage) {
      await prefs.remove('quran_bookmark_page');
      setState(() {
        _bookmarkedPage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إزالة العلامة المرجعية')),
        );
      }
    } else {
      await prefs.setInt('quran_bookmark_page', _currentPage);
      setState(() {
        _bookmarkedPage = _currentPage;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ الصفحة $_currentPage كعلامة مرجعية! 🔖')),
        );
      }
    }
  }

  void _showJumpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('انتقال إلى صفحة', textAlign: TextAlign.right),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            hintText: 'أدخل رقم الصفحة (1 - 604)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1 && val <= 604) {
                _pageController.jumpToPage(val - 1);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('رقم الصفحة غير صحيح')),
                );
              }
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    final pageData = quran.getPageData(_currentPage);
    final firstSurah = pageData.isNotEmpty ? pageData.first['surah']! : 1;
    final firstVerse = pageData.isNotEmpty ? pageData.first['start']! : 1;

    final surahName = quran.getSurahNameArabic(firstSurah);
    final juzNumber = quran.getJuzNumber(firstSurah, firstVerse);
    final isBookmarked = _bookmarkedPage == _currentPage;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EDE2),
      appBar: AppBar(
        title: Text(
          'سورة $surahName — جزء $juzNumber',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? const Color(0xFFFFD700) : null,
            ),
            tooltip: 'حفظ الصفحة كعلامة مرجعية',
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.find_in_page_outlined),
            tooltip: 'انتقال إلى صفحة معينة',
            onPressed: _showJumpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'تصغير الخط',
            onPressed: () {
              if (_fontSize > 16) {
                setState(() => _fontSize -= 2.0);
                _saveFontSize(_fontSize);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'تكبير الخط',
            onPressed: () {
              if (_fontSize < 40) {
                setState(() => _fontSize += 2.0);
                _saveFontSize(_fontSize);
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: 604,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index + 1;
          });
        },
        itemBuilder: (context, index) {
          final pNum = index + 1;
          final currentItems = quran.getPageData(pNum);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFE6DFD3),
                  width: 1.0,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFF3EDE2),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(currentItems.length, (sIdx) {
                            final item = Map<String, int>.from(currentItems[sIdx]);
                            final sNum = item['surah']!;
                            final start = item['start']!;
                            final end = item['end']!;

                            final bool showBasmala = sNum != 1 && sNum != 9 && start == 1;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Surah title
                                if (start == 1) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'سُورَةُ ${quran.getSurahNameArabic(sNum)}',
                                        style: GoogleFonts.amiri(
                                          fontSize: _fontSize + 2,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // Basmala
                                if (showBasmala) ...[
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        quran.basmala,
                                        style: GoogleFonts.amiri(
                                          fontSize: _fontSize + 2,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                                // Verses
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: RichText(
                                    textAlign: TextAlign.justify,
                                    text: TextSpan(
                                      children: List.generate(end - start + 1, (i) {
                                        final verseNumber = start + i;
                                        String verseText = quran.getVerse(sNum, verseNumber, verseEndSymbol: true);

                                        if (showBasmala && verseNumber == 1) {
                                          const cleanBasmala = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';
                                          if (verseText.startsWith(cleanBasmala)) {
                                            verseText = verseText.substring(cleanBasmala.length).trim();
                                          }
                                        }

                                        return TextSpan(
                                          text: '$verseText ',
                                          style: GoogleFonts.amiri(
                                            fontSize: _fontSize,
                                            height: 2.1,
                                            color: Colors.black87,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                                if (sIdx < currentItems.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    // Page Number Footer
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '— الصفحة $pNum —',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}