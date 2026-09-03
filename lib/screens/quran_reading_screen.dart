import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/quran_models.dart';
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
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // 0-indexed PageController for pages 1 to 604
    _pageController = PageController(initialPage: widget.initialPage - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuranProvider>();
      provider.setCurrentPage(widget.initialPage);
      provider.precacheAdjacentImages(context, widget.initialPage);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    final provider = context.read<QuranProvider>();
    provider.applySystemUiMode(!_showControls);
  }

  void _goToPage(int page, QuranProvider provider) {
    if (page >= 1 && page <= 604) {
      _pageController.jumpToPage(page - 1);
      provider.setCurrentPage(page);
      provider.precacheAdjacentImages(context, page);
    }
  }

  void _showJumpDialog(BuildContext context, QuranProvider provider) {
    final pageInputController = TextEditingController();
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
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  labelColor: const Color(0xFF1E3A37),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF1E3A37),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: const [
                    Tab(icon: Icon(Icons.pin, size: 18), text: 'رقم الصفحة'),
                    Tab(icon: Icon(Icons.menu_book, size: 18), text: 'السور'),
                    Tab(icon: Icon(Icons.format_list_numbered, size: 18), text: 'الأجزاء'),
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
                            Text(
                              'الصفحة الحالية: ${provider.currentPage}',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: pageInputController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              autofocus: true,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: 'أدخل رقم الصفحة (1 - 604)',
                                hintStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                                filled: true,
                                fillColor: const Color(0xFFF6FAF9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF1E3A37), width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A37),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () {
                                final page = int.tryParse(pageInputController.text.trim());
                                if (page != null && page >= 1 && page <= 604) {
                                  Navigator.pop(ctx);
                                  _goToPage(page, provider);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الرجاء إدخال رقم صفحة صحيح بين 1 و 604')),
                                  );
                                }
                              },
                              child: const Text('انتقال إلى الصفحة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Surah List
                      ListView.separated(
                        itemCount: surahs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
                        itemBuilder: (context, index) {
                          final s = surahs[index];
                          final isCurrent = provider.currentPage >= s.startPage &&
                              (index == surahs.length - 1 || provider.currentPage < surahs[index + 1].startPage);

                          return ListTile(
                            selected: isCurrent,
                            selectedTileColor: const Color(0xFF1E3A37).withValues(alpha: 0.06),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFF1E3A37) : const Color(0xFF1E3A37).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${s.number}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : const Color(0xFF1E3A37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              s.nameArabic,
                              style: GoogleFonts.amiri(fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'صفحة ${s.startPage} • ${s.versesCount} آية • ${s.isMeccan ? 'مكية' : 'مدنية'}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(ctx);
                              _goToPage(s.startPage, provider);
                            },
                          );
                        },
                      ),

                      // Tab 3: Juz List
                      ListView.separated(
                        itemCount: juzs.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
                        itemBuilder: (context, index) {
                          final j = juzs[index];
                          final isCurrent = provider.currentPage >= j.startPage &&
                              (index == juzs.length - 1 || provider.currentPage < juzs[index + 1].startPage);

                          return ListTile(
                            selected: isCurrent,
                            selectedTileColor: const Color(0xFF1E3A37).withValues(alpha: 0.06),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isCurrent ? const Color(0xFFCBB282) : const Color(0xFFCBB282).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${j.number}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : const Color(0xFF7A5C22),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              j.nameArabic,
                              style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'صفحة ${j.startPage} • ${j.startSurahName}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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

  void _showFitSettingsModal(BuildContext context, QuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'تنسيق ملاءمة الصفحة والشاشة',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A37)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: provider.pageFit == QuranPageFit.stretchWidth
                            ? const Color(0xFF1E3A37).withValues(alpha: 0.1)
                            : Colors.transparent,
                        side: BorderSide(
                          color: provider.pageFit == QuranPageFit.stretchWidth ? const Color(0xFF1E3A37) : Colors.grey[300]!,
                          width: provider.pageFit == QuranPageFit.stretchWidth ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        provider.setPageFit(QuranPageFit.stretchWidth);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.fullscreen, color: Color(0xFF1E3A37)),
                      label: const Text('فرد كامل للشاشة', style: TextStyle(color: Color(0xFF1E3A37), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: provider.pageFit == QuranPageFit.contain
                            ? const Color(0xFF1E3A37).withValues(alpha: 0.1)
                            : Colors.transparent,
                        side: BorderSide(
                          color: provider.pageFit == QuranPageFit.contain ? const Color(0xFF1E3A37) : Colors.grey[300]!,
                          width: provider.pageFit == QuranPageFit.contain ? 2 : 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        provider.setPageFit(QuranPageFit.contain);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.fit_screen, color: Color(0xFF1E3A37)),
                      label: const Text('احتواء تناسبي', style: TextStyle(color: Color(0xFF1E3A37), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFilterModal(BuildContext context, QuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'أوضاع إضاءة وصفحة المصحف',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A37)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildFilterOption(
                    title: 'الأصلي',
                    subtitle: 'ورق المصحف',
                    filter: QuranReadingFilter.original,
                    bgColor: const Color(0xFFFBF8F1),
                    borderColor: const Color(0xFFD4C29A),
                    textColor: Colors.black87,
                    provider: provider,
                  ),
                  const SizedBox(width: 10),
                  _buildFilterOption(
                    title: 'الدافئ',
                    subtitle: 'مريح للعين',
                    filter: QuranReadingFilter.sepia,
                    bgColor: const Color(0xFFF4E8D1),
                    borderColor: const Color(0xFFC7AF80),
                    textColor: const Color(0xFF3F2F1C),
                    provider: provider,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildFilterOption(
                    title: 'الليلي',
                    subtitle: 'داكن عالي التباين',
                    filter: QuranReadingFilter.dark,
                    bgColor: const Color(0xFF181A1B),
                    borderColor: const Color(0xFF4A4E50),
                    textColor: Colors.white,
                    provider: provider,
                  ),
                  const SizedBox(width: 10),
                  _buildFilterOption(
                    title: 'الهادئ',
                    subtitle: 'أخضر زمردي',
                    filter: QuranReadingFilter.mint,
                    bgColor: const Color(0xFFEFF7F2),
                    borderColor: const Color(0xFFABC5B6),
                    textColor: const Color(0xFF1E3A37),
                    provider: provider,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required String subtitle,
    required QuranReadingFilter filter,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required QuranProvider provider,
  }) {
    final isSelected = provider.readingFilter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          provider.setReadingFilter(filter);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A37) : borderColor,
              width: isSelected ? 2.2 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E3A37).withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF1E3A37))
                  else
                    const SizedBox(width: 4),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final currentPageData = _quranService.getPageDataSync(provider.currentPage);
    final isBookmarked = provider.isPageBookmarked(provider.currentPage);

    // Filter-based top/bottom bar themes
    final isDarkFilter = provider.readingFilter == QuranReadingFilter.dark;
    final overlayBgColor = isDarkFilter
        ? const Color(0xFF16191B).withValues(alpha: 0.95)
        : const Color(0xFF1E3A37).withValues(alpha: 0.95);

    return Scaffold(
      backgroundColor: isDarkFilter ? const Color(0xFF121415) : const Color(0xFFFBF8F1),
      body: Stack(
        children: [
          // Quran Page Viewer (1 to 604)
          // Directionality set to RTL for authentic Arabic Quran page flipping flow
          Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 604,
              onPageChanged: (index) {
                final page = index + 1;
                provider.setCurrentPage(page);
                provider.precacheAdjacentImages(context, page);
              },
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return QuranPageWidget(
                  pageNumber: pageNumber,
                  filter: provider.readingFilter,
                  fit: provider.pageFit,
                  onTap: _toggleControls,
                );
              },
            ),
          ),

          // Animated Top App Bar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 6,
                bottom: 10,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: overlayBgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    tooltip: 'رجوع',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentPageData.primarySurahName,
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'الجزء ${currentPageData.juzNumber} • صفحة ${provider.currentPage}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Fullscreen Toggle Button
                  IconButton(
                    icon: Icon(
                      _showControls ? Icons.fullscreen : Icons.fullscreen_exit,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'ملء الشاشة',
                    onPressed: _toggleControls,
                  ),

                  // Page Fit Settings Button
                  IconButton(
                    icon: Icon(
                      provider.pageFit == QuranPageFit.stretchWidth
                          ? Icons.fullscreen
                          : Icons.fit_screen_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'ملاءمة الصفحة للشاشة',
                    onPressed: () => _showFitSettingsModal(context, provider),
                  ),

                  // Reading Tone Filter Button
                  IconButton(
                    icon: const Icon(Icons.palette_outlined, color: Colors.white, size: 22),
                    tooltip: 'أوضاع إضاءة الصفحة',
                    onPressed: () => _showFilterModal(context, provider),
                  ),

                  // Bookmark Button
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? const Color(0xFFE5C07B) : Colors.white,
                      size: 24,
                    ),
                    tooltip: isBookmarked ? 'إزالة الفاصل' : 'حفظ فاصل',
                    onPressed: () async {
                      final added = await provider.toggleBookmark(provider.currentPage);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'تم حفظ فاصل في صفحة ${provider.currentPage} (${currentPageData.primarySurahName})'
                                  : 'تمت إزالة الفاصل',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Animated Bottom Bar Controls Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -140,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                color: overlayBgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page Slider and Indicators
                  Row(
                    children: [
                      Text(
                        '1',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFCBB282),
                            inactiveTrackColor: Colors.white24,
                            thumbColor: const Color(0xFFCBB282),
                            overlayColor: const Color(0xFFCBB282).withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: provider.currentPage.toDouble(),
                            min: 1.0,
                            max: 604.0,
                            divisions: 603,
                            onChanged: (val) {
                              _goToPage(val.round(), provider);
                            },
                          ),
                        ),
                      ),
                      Text(
                        '604',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ],
                  ),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Previous Page Button
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: provider.currentPage > 1
                            ? () => _goToPage(provider.currentPage - 1, provider)
                            : null,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('السابقة', style: TextStyle(fontSize: 13)),
                      ),

                      // Jump / Index Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCBB282),
                          foregroundColor: const Color(0xFF1E3A37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () => _showJumpDialog(context, provider),
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: Text(
                          'صفحة ${provider.currentPage}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),

                      // Next Page Button
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: provider.currentPage < 604
                            ? () => _goToPage(provider.currentPage + 1, provider)
                            : null,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('التالية', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
