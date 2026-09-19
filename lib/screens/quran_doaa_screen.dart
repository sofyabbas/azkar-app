import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_service.dart';

class QuranDoaaScreen extends StatefulWidget {
  const QuranDoaaScreen({super.key});

  @override
  State<QuranDoaaScreen> createState() => _QuranDoaaScreenState();
}

class _QuranDoaaScreenState extends State<QuranDoaaScreen> {
  final QuranService _quranService = QuranService();
  String _doaaText = '';
  bool _isLoading = true;
  double _fontSize = 20.0;
  static const Color primaryColor = Color(0xFF1E3A37);
  static const Color goldColor = Color(0xFFCBB282);

  @override
  void initState() {
    super.initState();
    _loadDoaa();
  }

  Future<void> _loadDoaa() async {
    final text = await _quranService.getDoaaKhatm();
    if (mounted) {
      setState(() {
        _doaaText = text;
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _doaaText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ دعاء ختم القرآن الكريم إلى الحافظة ✨'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F1),
      appBar: AppBar(
        title: const Text(
          'دعاء ختم القرآن الكريم',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'تكبير الخط',
            onPressed: () {
              if (_fontSize < 32) {
                setState(() => _fontSize += 2);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'تصغير الخط',
            onPressed: () {
              if (_fontSize > 16) {
                setState(() => _fontSize -= 2);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'نسخ الدعاء',
            onPressed: _doaaText.isNotEmpty ? _copyToClipboard : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: goldColor.withValues(alpha: 0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Decorative Header Emblem
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 1,
                          width: 40,
                          color: goldColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.auto_stories_rounded, color: goldColor, size: 28),
                        ),
                        Container(
                          height: 1,
                          width: 40,
                          color: goldColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: _fontSize + 4,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Doaa Text
                    Text(
                      _doaaText,
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: _fontSize,
                        height: 2.1,
                        color: const Color(0xFF2C2523),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Bottom Decorative Line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: goldColor.withValues(alpha: 0.6),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'تقبّل الله منّا ومنكم صالح الأعمال',
                            style: GoogleFonts.amiri(
                              fontSize: 14,
                              color: goldColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: goldColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
