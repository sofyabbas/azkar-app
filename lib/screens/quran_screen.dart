import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quran_models.dart';
import '../providers/quran_provider.dart';
import '../services/quran_service.dart';
import 'quran_reading_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF1E3A37);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pageJumpController = TextEditingController();
  final QuranService _quranService = QuranService();

  String _searchQuery = '';
  List<QuranSurah> _allSurahs = [];
  List<QuranJuz> _allJuzs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allSurahs = _quranService.getAllSurahs();
    _allJuzs = _quranService.getAllJuzs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _pageJumpController.dispose();
    super.dispose();
  }

  void _openReadingScreen(BuildContext context, int page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranReadingScreen(initialPage: page),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text(
          'المصحف الشريف',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            tooltip: 'عن المصحف والمصدر',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'مصدر بيانات المصحف',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Color(0xFFCBB282), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'النص القرآني المعتمد في هذا التطبيق مستخرج ومطابق بنسبة 100% لمشروع تنزيل العالمي (Tanzil.net).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '• الرواية: حفص عن عاصم\n• الرسم: الرسم العثماني (مصحف المدينة المنورة)\n• عدد الصفحات: 604 صفحة\n• المصدر: Tanzil Quran Project (Tanzil.net)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.7),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إغلاق', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: TextField(
                  controller: _searchController,
                  textAlign: TextAlign.right,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                    if (val.trim().length >= 2) {
                      provider.search(val.trim());
                    } else if (val.trim().isEmpty) {
                      provider.clearSearch();
                    }
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن سورة أو نص آية...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                              provider.clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                ),
              ),

              // 3-Tabs Header
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFCBB282),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  const Tab(text: 'فهرس السور', icon: Icon(Icons.format_list_bulleted, size: 18)),
                  const Tab(text: 'الأجزاء والأرباع', icon: Icon(Icons.auto_stories, size: 18)),
                  Tab(
                    text: 'العلامات المرجعية',
                    icon: Badge(
                      isLabelVisible: provider.bookmarks.isNotEmpty,
                      label: Text('${provider.bookmarks.length}'),
                      backgroundColor: const Color(0xFFCBB282),
                      child: const Icon(Icons.bookmark_added, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _searchQuery.isNotEmpty
          ? _buildSearchResultsView(provider)
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Surahs
                _buildSurahsTab(provider),

                // Tab 2: Juzs
                _buildJuzsTab(provider),

                // Tab 3: Bookmarks
                _buildBookmarksTab(provider),
              ],
            ),
    );
  }

  Widget _buildLastReadCard(QuranProvider provider) {
    final lastPage = provider.lastReadPage ?? 1;
    final pageData = _quranService.getPageDataSync(lastPage);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A37), Color(0xFF2B4E4A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCBB282).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBB282), width: 1.2),
            ),
            child: const Icon(Icons.menu_book, color: Color(0xFFEADBBE), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'آخر صفحة مقروءة',
                  style: TextStyle(color: Color(0xFFEADBBE), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'سورة ${pageData.primarySurahName}',
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'صفحة $lastPage — الجزء ${pageData.juzNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCBB282),
              foregroundColor: const Color(0xFF1E3A37),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => _openReadingScreen(context, lastPage),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('متابعة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahsTab(QuranProvider provider) {
    return Column(
      children: [
        _buildLastReadCard(provider),
        _buildQuickJumpBar(provider),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: _allSurahs.length,
            itemBuilder: (context, index) {
              final surah = _allSurahs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0.8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                color: Colors.white,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openReadingScreen(context, surah.startPage),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    child: Row(
                      children: [
                        // Surah Number
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
                          ),
                          child: Center(
                            child: Text(
                              '${surah.number}',
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Surah English Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surah.nameEnglish,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    surah.isMeccan ? Icons.wb_sunny_outlined : Icons.mosque_outlined,
                                    size: 13,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    surah.isMeccan ? 'مكية' : 'مدنية',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.format_list_numbered, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${surah.versesCount} آية',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Surah Arabic Name and Start Page
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              surah.nameArabic,
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              'بداية صفحة ${surah.startPage}',
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
    );
  }

  Widget _buildJuzsTab(QuranProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _allJuzs.length,
      itemBuilder: (context, index) {
        final juz = _allJuzs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFCBB282).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBB282), width: 1.0),
              ),
              child: Center(
                child: Text(
                  '${juz.number}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 15),
                ),
              ),
            ),
            title: Text(
              juz.nameArabic,
              style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            subtitle: Text(
              'يبدأ من سورة ${juz.startSurahName} (آية ${juz.startVerse}) — صفحة ${juz.startPage}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
            onTap: () => _openReadingScreen(context, juz.startPage),
          ),
        );
      },
    );
  }

  Widget _buildBookmarksTab(QuranProvider provider) {
    final bookmarks = provider.bookmarks;

    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'لا توجد علامات مرجعية محفوظة',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'أثناء قراءة أي صفحة في المصحف، اضغط على أيقونة العلامة المرجعية 🔖 لحفظها هنا',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF3ECE0),
              child: Icon(Icons.bookmark, color: Color(0xFFCBB282)),
            ),
            title: Text(
              'سورة ${b.surahName} — صفحة ${b.pageNumber}',
              style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            subtitle: Text(
              'الجزء ${b.juzNumber} — أُضيفت بتاريخ ${b.createdAt.year}/${b.createdAt.month}/${b.createdAt.day}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'حذف العلامة',
              onPressed: () {
                provider.removeBookmark(b.pageNumber);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العلامة المرجعية')),
                );
              },
            ),
            onTap: () => _openReadingScreen(context, b.pageNumber),
          ),
        );
      },
    );
  }

  Widget _buildQuickJumpBar(QuranProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                  _openReadingScreen(context, page);
                }
              },
              decoration: InputDecoration(
                hintText: 'انتقال سريع لرقم صفحة (1 - 604)...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(Icons.find_in_page_outlined, color: primaryColor),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: primaryColor),
                  onPressed: () {
                    final page = int.tryParse(_pageJumpController.text);
                    if (page != null && page >= 1 && page <= 604) {
                      _pageJumpController.clear();
                      _openReadingScreen(context, page);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء إدخال رقم صفحة صحيح بين 1 و 604')),
                      );
                    }
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(QuranProvider provider) {
    // Filter surahs matching search
    final cleanQuery = _quranService.normalizeArabic(_searchQuery);
    final matchingSurahs = _allSurahs.where((s) {
      final nameNorm = _quranService.normalizeArabic(s.nameArabic);
      final nameEn = s.nameEnglish.toLowerCase();
      return nameNorm.contains(cleanQuery) || nameEn.contains(_searchQuery.toLowerCase());
    }).toList();

    final verseResults = provider.searchResults;

    if (matchingSurahs.isEmpty && verseResults.isEmpty && !provider.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على نتائج لـ "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (matchingSurahs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('السور المطابقة:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...matchingSurahs.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(s.nameArabic, style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text('${s.nameEnglish} — صفحة ${s.startPage}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _openReadingScreen(context, s.startPage),
                ),
              )),
          const SizedBox(height: 12),
        ],
        if (provider.isSearching) ...[
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
        ] else if (verseResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('الآيات المطابقة (${verseResults.length}):', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...verseResults.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    r.text,
                    style: GoogleFonts.amiri(fontSize: 16, height: 1.8),
                    textAlign: TextAlign.right,
                  ),
                  subtitle: Text(
                    'سورة ${r.surahName} (آية ${r.verseNumber}) — صفحة ${r.pageNumber}',
                    style: const TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _openReadingScreen(context, r.pageNumber),
                ),
              )),
        ],
      ],
    );
  }
}