import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/quran_provider.dart';
import '../services/quran_service.dart';
import '../widgets/quran_page_widget.dart';

class QuranReadingScreen extends StatefulWidget {
  final int initialPage;

  const QuranReadingScreen({super.key, required this.initialPage});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  late PageController _pageController;
  final QuranService _quranService = QuranService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuranProvider>();
      provider.setCurrentPage(widget.initialPage);
      provider.setFullScreen(false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showJumpDialog(BuildContext context, QuranProvider provider) {
    final pageController = TextEditingController();
    final surahs = _quranService.getAllSurahs();
    final juzs = _quranService.getAllJuzs();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DefaultTabController(
          length: 3,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  labelColor: Color(0xFF1E3A37),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF1E3A37),
                  tabs: [
                    Tab(text: 'رقم الصفحة'),
                    Tab(text: 'السور'),
                    Tab(text: 'الأجزاء'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Direct Page Jump
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextField(
                              controller: pageController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'أدخل رقم الصفحة (1 - 604)',
                                hintStyle: const TextStyle(fontSize: 15),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF1E3A37), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A37),
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                final page = int.tryParse(pageController.text.trim());
                                if (page != null && page >= 1 && page <= 604) {
                                  Navigator.pop(ctx);
                                  _goToPage(page, provider);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الرجاء إدخال رقم صفحة صحيح بين 1 و 604')),
                                  );
                                }
                              },
                              child: const Text('انتقال إلى الصفحة', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Surah List
                      ListView.builder(
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final s = surahs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E3A37).withValues(alpha: 0.1),
                              child: Text('${s.number}', style: const TextStyle(color: Color(0xFF1E3A37))),
                            ),
                            title: Text(s.nameArabic, style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text('صفحة ${s.startPage} — ${s.versesCount} آية'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.pop(ctx);
                              _goToPage(s.startPage, provider);
                            },
                          );
                        },
                      ),

                      // Tab 3: Juz List
                      ListView.builder(
                        itemCount: juzs.length,
                        itemBuilder: (context, index) {
                          final j = juzs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E3A37).withValues(alpha: 0.1),
                              child: Text('${j.number}', style: const TextStyle(color: Color(0xFF1E3A37))),
                            ),
                            title: Text(j.nameArabic, style: GoogleFonts.amiri(fontSize: 17, fontWeight: FontWeight.bold)),
                            subtitle: Text('سورة ${j.startSurahName} — صفحة ${j.startPage}'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.pop(ctx);
                              _goToPage(j.startPage, provider);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToPage(int page, QuranProvider provider) {
    if (page >= 1 && page <= 604) {
      _pageController.jumpToPage(page - 1);
      provider.setCurrentPage(page);
    }
  }

  void _showSettingsModal(BuildContext context, QuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'خيارات القراءة والمظهر',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A37)),
                  ),
                  const SizedBox(height: 20),

                  // Font Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('حجم الخط:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${provider.fontSize.toInt()} نقطة', style: const TextStyle(color: Color(0xFF1E3A37), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: provider.fontSize,
                    min: 18.0,
                    max: 38.0,
                    divisions: 10,
                    activeColor: const Color(0xFF1E3A37),
                    inactiveColor: const Color(0xFF1E3A37).withValues(alpha: 0.2),
                    onChanged: (val) {
                      provider.setFontSize(val);
                      setModalState(() {});
                    },
                  ),

                  const SizedBox(height: 12),
                  const Text('مظهر الصفحة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildThemeOption(
                        title: 'الورق البيج',
                        type: QuranThemeType.cream,
                        bgSample: const Color(0xFFFAF6EE),
                        isSelected: provider.themeType == QuranThemeType.cream,
                        provider: provider,
                        setModalState: setModalState,
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOption(
                        title: 'العتيق',
                        type: QuranThemeType.sepia,
                        bgSample: const Color(0xFFF0E4CE),
                        isSelected: provider.themeType == QuranThemeType.sepia,
                        provider: provider,
                        setModalState: setModalState,
                      ),
                      const SizedBox(width: 8),
                      _buildThemeOption(
                        title: 'الليلي',
                        type: QuranThemeType.dark,
                        bgSample: const Color(0xFF101414),
                        isSelected: provider.themeType == QuranThemeType.dark,
                        provider: provider,
                        setModalState: setModalState,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String title,
    required QuranThemeType type,
    required Color bgSample,
    required bool isSelected,
    required QuranProvider provider,
    required StateSetter setModalState,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          provider.setThemeType(type);
          setModalState(() {});
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bgSample,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A37) : Colors.grey[300]!,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: type == QuranThemeType.dark ? Colors.white : const Color(0xFF1E3A37),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, child) {
        final currentPage = provider.currentPage;
        final pageData = _quranService.getPageDataSync(currentPage);
        final isBookmarked = provider.isPageBookmarked(currentPage);
        final isFullScreen = provider.isFullScreen;

        // Background based on theme
        final Color screenBg = provider.themeType == QuranThemeType.dark
            ? const Color(0xFF0C0E0E)
            : const Color(0xFFF3ECE0);

        return Scaffold(
          backgroundColor: screenBg,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: provider.themeType == QuranThemeType.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Stack(
              children: [
                // Main Mushaf PageView
                GestureDetector(
                  onTap: () {
                    provider.toggleFullScreen();
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 604,
                    onPageChanged: (index) {
                      provider.setCurrentPage(index + 1);
                    },
                    itemBuilder: (context, index) {
                      final pNum = index + 1;
                      final data = _quranService.getPageDataSync(pNum);

                      return QuranPageWidget(
                        pageData: data,
                        fontSize: provider.fontSize,
                        themeType: provider.themeType,
                      );
                    },
                  ),
                ),

                // Top Animated Header Bar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  top: isFullScreen ? -110 : 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 4,
                      bottom: 8,
                      left: 12,
                      right: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A37).withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سورة ${pageData.primarySurahName}',
                                  style: GoogleFonts.amiri(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'الجزء ${pageData.juzNumber} — صفحة $currentPage',
                                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                color: isBookmarked ? const Color(0xFFFFD700) : Colors.white,
                              ),
                              tooltip: 'العلامة المرجعية',
                              onPressed: () async {
                                final added = await provider.toggleBookmark(currentPage);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        added
                                            ? 'تم حفظ الصفحة $currentPage كعلامة مرجعية! 🔖'
                                            : 'تمت إزالة العلامة المرجعية',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.explore_outlined, color: Colors.white),
                              tooltip: 'انتقال سريع',
                              onPressed: () => _showJumpDialog(context, provider),
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune, color: Colors.white),
                              tooltip: 'إعدادات القراءة',
                              onPressed: () => _showSettingsModal(context, provider),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Animated Controls Bar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  bottom: isFullScreen ? -110 : 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A37).withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Page Scrubber Slider
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, color: Colors.white),
                              onPressed: currentPage > 1
                                  ? () => _goToPage(currentPage - 1, provider)
                                  : null,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFCBB282),
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: const Color(0xFFCBB282),
                                  overlayColor: const Color(0xFFCBB282).withValues(alpha: 0.2),
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: currentPage.toDouble(),
                                  min: 1.0,
                                  max: 604.0,
                                  onChanged: (val) {
                                    _goToPage(val.toInt(), provider);
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white),
                              onPressed: currentPage < 604
                                  ? () => _goToPage(currentPage + 1, provider)
                                  : null,
                            ),
                          ],
                        ),

                        // Quick action indicators
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الحزب ${((pageData.juzNumber - 1) * 2) + 1}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBB282).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBB282), width: 0.8),
                                ),
                                child: Text(
                                  'صفحة $currentPage من 604',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => provider.toggleFullScreen(),
                                child: const Row(
                                  children: [
                                    Icon(Icons.fullscreen, color: Colors.white70, size: 16),
                                    SizedBox(width: 4),
                                    Text('قراءة غامرة', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
