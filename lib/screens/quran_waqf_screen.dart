import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranWaqfScreen extends StatelessWidget {
  const QuranWaqfScreen({super.key});

  static const Color primaryColor = Color(0xFF1E3A37);
  static const Color goldColor = Color(0xFFCBB282);

  static final List<Map<String, String>> waqfMarks = [
    {
      'symbol': 'مـ',
      'title': 'لُزوم الوقف',
      'desc': 'تعني وجوب الوقف، لأن وصلها يوهم معنى غير مراد.',
      'example': '﴿إِنَّمَا يَسْتَجِيبُ الَّذِينَ يَسْمَعُونَ ۘ وَالْمَوْتَى يَبْعَثُهُمُ اللَّهُ﴾',
    },
    {
      'symbol': 'لا',
      'title': 'الوقف الممنوع',
      'desc': 'تعني النهي عن الوقف، لأن المعنى لا يتم إلا بما بعده.',
      'example': '﴿الَّذِينَ تَتَوَفَّاهُمُ الْمَلائِكَةُ طَيِّبِينَ ۙ يَقُولُونَ سَلامٌ عَلَيْكُمُ﴾',
    },
    {
      'symbol': 'ج',
      'title': 'جواز الوقف والوصل',
      'desc': 'يجوز للقارئ الوقف والوصل بالتساوي دون ترجيح.',
      'example': '﴿نَحْنُ نَقُصُّ عَلَيْكَ نَبَأَهُمْ بِالْحَقِّ ۚ إِنَّهُمْ فِتْيَةٌ آمَنُوا بِرَبِّهِمْ﴾',
    },
    {
      'symbol': 'صلى',
      'title': 'الوصل أولى مع جواز الوقف',
      'desc': 'يجوز الوقف، ولكن الوصل أفضل لإتمام المعنى وتناسقه.',
      'example': '﴿وَإِنْ يَمْسَسْكَ اللَّهُ بِضُرٍّ فَلا كَاشِفَ لَهُ إِلا هُوَ ۖ وَإِنْ يَمْسَسْكَ بِخَيْرٍ﴾',
    },
    {
      'symbol': 'قلى',
      'title': 'الوقف أولى مع جواز الوصل',
      'desc': 'يجوز الوصل، ولكن الوقف أفضل وأولى للبيان.',
      'example': '﴿قُلْ رَبِّي أَعْلَمُ بِعِدَّتِهِمْ مَا يَعْلَمُهُمْ إِلا قَلِيلٌ ۗ فَلا تُمَارِ فِيهِمْ﴾',
    },
    {
      'symbol': '∴  ∴',
      'title': 'وقف التعانق (المراقبة)',
      'desc': 'نقطتان ثلاثيتان: إذا وقف القارئ على إحداهما وجب وصل الأخرى ولا يقف عليها.',
      'example': '﴿ذَلِكَ الْكِتَابُ لا رَيْبَ ۛ فِيهِ ۛ هُدًى لِلْمُتَّقِينَ﴾',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text(
          'علامات الوقف وضبط المصحف',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: goldColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'دليل علامات الوقف في المصحف الشريف',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'وضع العلماء رموز الوقف لمساعدة القارئ على إدراك المعنى الصحيح وتجنب الوقف الموهم.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Waqf Marks Cards
          ...waqfMarks.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF8F1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: goldColor),
                        ),
                        child: Text(
                          item['symbol']!,
                          style: GoogleFonts.amiri(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['desc']!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2EFE9)),
                    ),
                    child: Text(
                      item['example']!,
                      style: GoogleFonts.amiri(fontSize: 15, color: primaryColor, height: 1.6),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
