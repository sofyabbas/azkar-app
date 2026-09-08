import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../models/quran_models.dart';
import '../providers/quran_provider.dart';
import '../services/quran_service.dart';
import '../services/quran_audio_service.dart';
import '../widgets/quran_page_widget.dart';
import 'quran_doaa_screen.dart';
import 'quran_waqf_screen.dart';

class QuranReadingScreen extends StatefulWidget {
  final int initialPage;

  const QuranReadingScreen({super.key, required this.initialPage});

  @override
  State<QuranReadingScreen> createState() => _QuranReadingScreenState();
}

class _QuranReadingScreenState extends State<QuranReadingScreen> {
  late PageController _pageController;
  final QuranService _quranService = QuranService();
  final QuranAudioService _audioService = QuranAudioService();

  bool _showControls = true;
  int? _selectedSurah;
  int? _selectedVerse;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _audioService.addListener(_onAudioServiceUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuranProvider>();
      provider.setCurrentPage(widget.initialPage);
    });
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioServiceUpdate);
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onAudioServiceUpdate() {
    if (!mounted) return;
    if (_audioService.isVerseMode && _audioService.currentSurah != null && _audioService.currentVerse != null) {
      final s = _audioService.currentSurah!;
      final v = _audioService.currentVerse!;
      if (_selectedSurah != s || _selectedVerse != v) {
        setState(() {
          _selectedSurah = s;
          _selectedVerse = v;
        });

        // Automatically flip page if the verse moved to a new page
        final versePage = quran.getPageNumber(s, v);
        final provider = context.read<QuranProvider>();
        if (versePage != provider.currentPage && versePage >= 1 && versePage <= 604) {
          _goToPage(versePage, provider);
        }
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    final provider = context.read<QuranProvider>();
    provider.applySystemUiMode(!_showControls);
  }

  void _toggleAudioPlayback() {
    final provider = context.read<QuranProvider>();

    if (_audioService.isPlaying) {
      _audioService.pause();
      return;
    } else if (_audioService.isPaused) {
      _audioService.resume();
      return;
    }

    // If an ayah is selected by the user, recite that selected ayah!
    if (_selectedSurah != null && _selectedVerse != null) {
      _audioService.playVerse(
        surahNumber: _selectedSurah!,
        verseNumber: _selectedVerse!,
        autoAdvance: true,
      );
      final surahName = quran.getSurahNameArabic(_selectedSurah!);
      final reciterName = _audioService.currentReciter?.name ?? 'مشاري راشد العفاسي';
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('بدء تلاوة سورة $surahName (آية $_selectedVerse) بصوت $reciterName 🎧'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // If no ayah is selected, recite starting from the first ayah of the current page!
    final pageSegments = quran.getPageData(provider.currentPage);
    final firstSeg = pageSegments.isNotEmpty ? pageSegments.first : null;
    final surahNum = firstSeg?['surah'] ?? 1;
    final verseNum = firstSeg?['start'] ?? 1;

    _audioService.playVerse(
      surahNumber: surahNum,
      verseNumber: verseNum,
      autoAdvance: true,
    );
    final surahName = quran.getSurahNameArabic(surahNum);
    final reciterName = _audioService.currentReciter?.name ?? 'مشاري راشد العفاسي';
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('بدء تلاوة سورة $surahName (آية $verseNum) بصوت $reciterName 🎧'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _goToPage(int page, QuranProvider provider) {
    if (page >= 1 && page <= 604) {
      _pageController.jumpToPage(page - 1);
      provider.setCurrentPage(page);
    }
  }

  void _onVerseTap(int surah, int verse) {
    setState(() {
      _selectedSurah = surah;
      _selectedVerse = verse;
    });
    _showVerseDetailsModal(surah, verse);
  }

  void _showVerseDetailsModal(int surah, int verse) async {
    final surahName = quran.getSurahNameArabic(surah);
    final verseText = quran.getVerse(surah, verse, verseEndSymbol: false);
    final tafsir = await _quranService.getTafsir(surah, verse);
    final meanings = await _quranService.getWordMeanings(surah, verse);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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

              // Verse Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سورة $surahName • آية $verse',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E3A37),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Content Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Verse Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD9C8A5)),
                      ),
                      child: Text(
                        '﴿ $verseText ﴾',
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A37),
                          height: 1.9,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '﴿ $verseText ﴾ [$surahName: $verse]'));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الآية الكريمة ✨')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('نسخ الآية'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A37),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _audioService.playVerse(
                              surahNumber: surah,
                              verseNumber: verse,
                              autoAdvance: true,
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text('تلاوة الآية $verse'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tafsir Section
                    const Text(
                      'التفسير الميسر',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A37),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FAF9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2EFE9)),
                      ),
                      child: Text(
                        tafsir ?? 'تفسير هذه الآية غير متوفر.',
                        style: const TextStyle(fontSize: 14.5, height: 1.7, color: Color(0xFF2C3236)),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Word Meanings Section (if any)
                    if (meanings.isNotEmpty) ...[
                      const Text(
                        'معاني الكلمات وغريب القرآن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A37),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...meanings.map((m) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                m.meaning,
                                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                              ),
                              Text(
                                m.word,
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFB88E3E),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPageTafsirModal(int pageNumber) async {
    final pageTafsir = await _quranService.getPageTafsir(pageNumber);
    final pageMeanings = await _quranService.getPageWordMeanings(pageNumber);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
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
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      text: 'تفسير صفحة $pageNumber',
                    ),
                    Tab(
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 18),
                      text: 'معاني الكلمات (${pageMeanings.length})',
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Page Tafsir
                      ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pageTafsir.length,
                        itemBuilder: (context, idx) {
                          final item = pageTafsir[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF8F1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFD9C8A5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'آية ${item['verse']}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                    Text(
                                      item['surahName'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A37),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '﴿ ${item['verseText']} ﴾',
                                  textDirection: TextDirection.rtl,
                                  style: GoogleFonts.amiri(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFB88E3E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item['tafsir'] as String,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFF2C3236)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Tab 2: Page Word Meanings
                      pageMeanings.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green[300]),
                                  const SizedBox(height: 12),
                                  const Text('لا توجد كلمات غريبة في هذه الصفحة، ألفاظها واضحة بفضل الله.'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: pageMeanings.length,
                              itemBuilder: (context, idx) {
                                final item = pageMeanings[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['meaning'] as String,
                                          style: const TextStyle(fontSize: 14, color: Color(0xFF2C3236)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBF8F1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFD9C8A5)),
                                        ),
                                        child: Text(
                                          item['word'] as String,
                                          style: GoogleFonts.amiri(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E3A37),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

  void _showReciterSelectionModal() async {
    final reciters = await _quranService.getReciters();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'اختر القارئ المفضل للتلاوة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A37)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: reciters.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final r = reciters[idx];
                    final isSelected = _audioService.currentReciter?.id == r.id;

                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.person_outline_rounded,
                        color: isSelected ? const Color(0xFF1E3A37) : Colors.grey,
                      ),
                      title: Text(
                        r.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFF1E3A37) : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        final currentSurah = _audioService.currentSurah ?? 1;
                        if (_audioService.isVerseMode && _audioService.currentVerse != null) {
                          _audioService.playVerse(
                            surahNumber: currentSurah,
                            verseNumber: _audioService.currentVerse!,
                            reciter: r,
                          );
                        } else {
                          _audioService.playSurah(surahNumber: currentSurah, reciter: r);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFontAndToneModal(BuildContext context, QuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        'إعدادات الخط والمظهر',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E3A37)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Font Size Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('حجم الخط القرآني:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${provider.fontSize.round()} نقطة', style: const TextStyle(color: Color(0xFF1E3A37), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: provider.fontSize,
                    min: 16.0,
                    max: 32.0,
                    divisions: 8,
                    activeColor: const Color(0xFF1E3A37),
                    onChanged: (val) {
                      setModalState(() {});
                      provider.setFontSize(val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tone Filters
                  const Text('وضع إضاءة المصحف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildToneButton('الأصلي', QuranReadingFilter.original, const Color(0xFFFBF8F1), provider),
                      const SizedBox(width: 8),
                      _buildToneButton('الدافئ', QuranReadingFilter.sepia, const Color(0xFFF4E8D1), provider),
                      const SizedBox(width: 8),
                      _buildToneButton('الليلي', QuranReadingFilter.dark, const Color(0xFF121415), provider, isDark: true),
                      const SizedBox(width: 8),
                      _buildToneButton('الهادئ', QuranReadingFilter.mint, const Color(0xFFEFF7F2), provider),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToneButton(String label, QuranReadingFilter filter, Color color, QuranProvider provider, {bool isDark = false}) {
    final isSelected = provider.readingFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => provider.setReadingFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E3A37) : Colors.grey[300]!,
              width: isSelected ? 2.2 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
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
                      SingleChildScrollView(
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
                                filled: true,
                                fillColor: const Color(0xFFF6FAF9),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A37),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                final page = int.tryParse(pageInputController.text.trim());
                                if (page != null && page >= 1 && page <= 604) {
                                  Navigator.pop(ctx);
                                  _goToPage(page, provider);
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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF1E3A37).withValues(alpha: 0.1),
                              child: Text('${s.number}', style: const TextStyle(color: Color(0xFF1E3A37), fontWeight: FontWeight.bold)),
                            ),
                            title: Text(s.nameArabic, style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text('صفحة ${s.startPage} • ${s.versesCount} آية'),
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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFCBB282).withValues(alpha: 0.2),
                              child: Text('${j.number}', style: const TextStyle(color: Color(0xFF8B6F3E), fontWeight: FontWeight.bold)),
                            ),
                            title: Text(j.nameArabic, style: GoogleFonts.amiri(fontSize: 17, fontWeight: FontWeight.bold)),
                            subtitle: Text('صفحة ${j.startPage} • ${j.startSurahName}'),
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

  void _showReaderBurgerMenu(BuildContext context, QuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'خيارات القراءة والمصحف',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A37),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // 1. Duaa Khatm
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF1E3A37)),
                ),
                title: const Text('دعاء ختم القرآن الكريم', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('دعاء ختم القرآن المأثور مكتوباً ومشكولاً'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const QuranDoaaScreen()));
                },
              ),

              // 2. Waqf Marks
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C6B56).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Color(0xFF2C6B56)),
                ),
                title: const Text('علامات الوقف ومصطلحات الضبط', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('دليل علامات الوقف في مصحف المدينة المنورة'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const QuranWaqfScreen()));
                },
              ),

              // 3. Font & Lighting
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBB282).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.format_size_rounded, color: Color(0xFF8B6F3E)),
                ),
                title: const Text('الخط ووضع الإضاءة', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('تغيير حجم الخط القرآني وألوان الصفحة (داكن، دافئ، هادئ)'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFontAndToneModal(context, provider);
                },
              ),

              // 4. Change Reciter
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.record_voice_over_rounded, color: Colors.teal),
                ),
                title: const Text('اختيار القارئ المفضل', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('القارئ الحالي: ${_audioService.currentReciter?.name ?? "مشاري العفاسي"}'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReciterSelectionModal();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final isBookmarked = provider.isPageBookmarked(provider.currentPage);
    final isDarkFilter = provider.readingFilter == QuranReadingFilter.dark;

    final overlayBgColor = isDarkFilter
        ? const Color(0xFF16191B).withValues(alpha: 0.95)
        : const Color(0xFF1E3A37).withValues(alpha: 0.95);

    return Scaffold(
      backgroundColor: isDarkFilter ? const Color(0xFF121415) : const Color(0xFFFBF8F1),
      body: Stack(
        children: [
          // 1. Quran Page Viewer (1 to 604)
          Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 604,
              onPageChanged: (index) {
                final page = index + 1;
                provider.setCurrentPage(page);
                setState(() {
                  _selectedSurah = null;
                  _selectedVerse = null;
                });
              },
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return QuranPageWidget(
                  pageNumber: pageNumber,
                  filter: provider.readingFilter,
                  fit: provider.pageFit,
                  onTap: _toggleControls,
                  onDoubleTap: _toggleAudioPlayback,
                  onVerseTap: _onVerseTap,
                  selectedSurah: _selectedSurah,
                  selectedVerse: _selectedVerse,
                );
              },
            ),
          ),

          // 2. Animated Top Bar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -110,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                bottom: 8,
                left: 8,
                right: 8,
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
                          'المصحف الشريف',
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'صفحة ${provider.currentPage} من 604',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  // Bookmark Button
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? const Color(0xFFCBB282) : Colors.white70,
                    ),
                    tooltip: 'حفظ علامة',
                    onPressed: () async {
                      final added = await provider.toggleBookmark(provider.currentPage);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(added ? 'تم حفظ العلامة المرجعية في صفحة ${provider.currentPage} 🔖' : 'تمت إزالة العلامة المرجعية'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  // Burger Menu Button
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                    tooltip: 'قائمة المصحف',
                    onPressed: () => _showReaderBurgerMenu(context, provider),
                  ),
                ],
              ),
            ),
          ),

          // 3. Animated Bottom Bar Overlay
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Page Tafsir & Meanings
                  InkWell(
                    onTap: () => _showPageTafsirModal(provider.currentPage),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded, color: Color(0xFFCBB282), size: 22),
                          SizedBox(height: 3),
                          Text('تفسير الصفحة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Audio Play / Reciter
                  ListenableBuilder(
                    listenable: _audioService,
                    builder: (context, _) {
                      final isPlaying = _audioService.isPlaying;
                      return InkWell(
                        onTap: _toggleAudioPlayback,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                color: const Color(0xFFCBB282),
                                size: 24,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPlaying ? 'إيقاف مؤقت' : 'تلاوة صوتية',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Reciter Selection
                  InkWell(
                    onTap: _showReciterSelectionModal,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.record_voice_over_rounded, color: Colors.white70, size: 22),
                          SizedBox(height: 3),
                          Text('اختيار القارئ', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                  // Font Size & Lighting
                  InkWell(
                    onTap: () => _showFontAndToneModal(context, provider),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.format_size_rounded, color: Colors.white70, size: 22),
                          SizedBox(height: 3),
                          Text('الخط والمظهر', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                  // Index & Jump
                  InkWell(
                    onTap: () => _showJumpDialog(context, provider),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grid_view_rounded, color: Colors.white70, size: 22),
                          SizedBox(height: 3),
                          Text('الفهرس والقفز', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Recitation Mini-Player
          _buildFloatingAudioPlayer(context, overlayBgColor),
        ],
      ),
    );
  }

  Widget _buildFloatingAudioPlayer(BuildContext context, Color overlayBgColor) {
    return ListenableBuilder(
      listenable: _audioService,
      builder: (context, _) {
        final hasActiveAudio = _audioService.isPlaying ||
            _audioService.isPaused ||
            _audioService.isLoading;

        if (!hasActiveAudio) {
          return const SizedBox.shrink();
        }

        final surahNum = _audioService.currentSurah ?? 1;
        final surahName = quran.getSurahNameArabic(surahNum);
        final verseNum = _audioService.currentVerse;
        final titleText = verseNum != null ? 'سورة $surahName • آية $verseNum' : 'سورة $surahName';
        final reciterName = _audioService.currentReciter?.name ?? 'القارئ';
        final pos = _audioService.position;
        final dur = _audioService.duration;
        final maxDurSeconds = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 1.0;
        final currentSeconds = pos.inSeconds.toDouble().clamp(0.0, maxDurSeconds);

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          bottom: _showControls
              ? (MediaQuery.of(context).padding.bottom + 76)
              : (MediaQuery.of(context).padding.bottom + 16),
          left: 16,
          right: 16,
          child: Material(
            elevation: 12,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF162523),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B3834), Color(0xFF132824)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                border: Border.all(
                  color: const Color(0xFFCBB282).withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Previous Verse Button (In RTL, skip previous is forward in time or left)
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Color(0xFFCBB282), size: 24),
                        tooltip: 'الآية السابقة',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _audioService.previousVerse,
                      ),
                      const SizedBox(width: 4),

                      // Play / Pause / Loading button
                      GestureDetector(
                        onTap: () {
                          if (_audioService.isPlaying) {
                            _audioService.pause();
                          } else {
                            _audioService.resume();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFCBB282),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFCBB282).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _audioService.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Color(0xFF1E3A37),
                                    ),
                                  )
                                : Icon(
                                    _audioService.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 26,
                                    color: const Color(0xFF1E3A37),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Next Verse Button
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFCBB282), size: 24),
                        tooltip: 'الآية التالية',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: _audioService.nextVerse,
                      ),
                      const SizedBox(width: 8),

                      // Surah & Verse & Reciter Details (tap to change reciter)
                      Expanded(
                        child: InkWell(
                          onTap: _showReciterSelectionModal,
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      titleText,
                                      style: GoogleFonts.amiri(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBB282).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'تغيير',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFE4CF9C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                reciterName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Time Display
                      Text(
                        '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Close Audio button
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        tooltip: 'إغلاق التلاوة',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _audioService.stop();
                        },
                      ),
                    ],
                  ),

                  // Progress Slider
                  if (dur.inSeconds > 0) ...[
                    const SizedBox(height: 2),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                        activeTrackColor: const Color(0xFFCBB282),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFFCBB282),
                      ),
                      child: Slider(
                        value: currentSeconds,
                        min: 0.0,
                        max: maxDurSeconds,
                        onChanged: (val) {
                          _audioService.seek(Duration(seconds: val.toInt()));
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
