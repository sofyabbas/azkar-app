import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';

class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen> {
  int _counter = 0;
  int _targetCount = 33; // 33, 100, 0 = unlimited
  int _selectedZikrIndex = 0;
  int _totalSessionCount = 0;

  final List<Map<String, String>> _azkarList = [
    {'title': 'سُبْحَانَ اللَّهِ', 'virtue': 'تُغرس لك بها شجرة في الجنة.'},
    {'title': 'الْحَمْدُ لِلَّهِ', 'virtue': 'تَمْلأُ الْمِيزَانَ بالحسنات.'},
    {'title': 'لا إِلَهَ إِلاَّ اللَّهُ', 'virtue': 'أفضل ما قال النبيون والذكر الأعظم.'},
    {'title': 'اللَّهُ أَكْبَرُ', 'virtue': 'تصلح ما بين السماء والأرض.'},
    {'title': 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ', 'virtue': 'تجلب الرزق وتغفر الذنوب وتفرّج الهموم.'},
    {'title': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ', 'virtue': 'من صلى عليّ صلاة صلى الله عليه بها عشراً.'},
    {'title': 'لا حَوْلَ وَلا قُوَّةَ إِلاَّ بِاللَّهِ', 'virtue': 'كنز من كنوز الجنة.'},
  ];

  void _incrementCounter() {
    if (_targetCount > 0 && _counter >= _targetCount) {
      // Vibrate if they attempt to continue after completing target
      HapticFeedback.vibrate();
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _counter++;
      _totalSessionCount++;
    });

    // Record stats in the dedicated tasbeeh tracker
    final currentZikr = _azkarList[_selectedZikrIndex];
    Provider.of<StatsProvider>(context, listen: false).recordTasbeeh(
      zikrTitle: currentZikr['title'],
      count: 1,
    );

    // Check target completion
    if (_targetCount > 0 && _counter == _targetCount) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFFFD700)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'أحسنت! أتممت $_targetCount تسبيحة 🎉 تقبل الله طاعتك',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A37),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _resetCounter() {
    HapticFeedback.mediumImpact();
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);
    final currentZikr = _azkarList[_selectedZikrIndex];
    final double progress = (_targetCount > 0) ? (_counter / _targetCount).clamp(0.0, 1.0) : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text('المسبحة الإلكترونية الذكية', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'إعادة ضبط العداد',
            onPressed: _resetCounter,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 640;
            final double outerRingSize = isCompact ? 190.0 : 225.0;
            final double progressSize = isCompact ? 170.0 : 200.0;
            final double innerCircleSize = isCompact ? 140.0 : 165.0;
            final double counterFontSize = isCompact ? 40.0 : 48.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // ZIKR SELECTION CHIPS (Horizontal Scroll)
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _azkarList.length,
                          itemBuilder: (context, index) {
                            final isSelected = (_selectedZikrIndex == index);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(_azkarList[index]['title']!),
                                selected: isSelected,
                                selectedColor: primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : primaryColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                elevation: isSelected ? 2 : 0,
                                side: BorderSide(
                                  color: isSelected ? primaryColor : Colors.grey[300]!,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedZikrIndex = index;
                                      _counter = 0;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TARGET COUNT SELECTOR CHIPS (33 | 100 | مفتوح)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('الهدف: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                          const SizedBox(width: 8),
                          _buildTargetChip(33, '33 مرة'),
                          const SizedBox(width: 8),
                          _buildTargetChip(100, '100 مرة'),
                          const SizedBox(width: 8),
                          _buildTargetChip(0, 'مفتوح ∞'),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Spacer(),

                      // MAIN INTERACTIVE DIGITAL TASBEEH CIRCLE
                      GestureDetector(
                        onTap: _incrementCounter,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Glow Ring
                            Container(
                              width: outerRingSize,
                              height: outerRingSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.05),
                              ),
                            ),

                            // Circular Progress Indicator
                            SizedBox(
                              width: progressSize,
                              height: progressSize,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),

                            // Inner Tap Button Circle
                            Container(
                              width: innerCircleSize,
                              height: innerCircleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_counter',
                                    style: TextStyle(
                                      fontSize: counterFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_targetCount > 0)
                                    Text(
                                      'من $_targetCount',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'اضغط للتسبيح',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 16),

                      // VIRTUE & HADITH BANNER FOR SELECTED ZIKR
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                currentZikr['title']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '✨ ${currentZikr['virtue']!}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // SESSION SUMMARY BAR
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0, top: 4.0, left: 20, right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'مجموع الجلسة: $_totalSessionCount تسبيحة',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _resetCounter,
                              icon: const Icon(Icons.restart_alt, size: 16),
                              label: const Text('بدء من جديد', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: const BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      ),
    );
  }

  Widget _buildTargetChip(int target, String label) {
    final isSelected = (_targetCount == target);
    const primaryColor = Color(0xFF1E3A37);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey[300]!,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _targetCount = target;
            _counter = 0;
          });
        }
      },
    );
  }
}
