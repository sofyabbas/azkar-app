import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/azkar_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final azkarProvider = Provider.of<AzkarProvider>(context);

    const primaryColor = Color(0xFF1E3A37);
    const accentColor = Color(0xFF4CAF7D);

    final readCategories = azkarProvider.categories.where((category) {
      final stat = statsProvider.categoryStats[category.id];
      return stat != null && (stat.readCount > 0 || stat.itemsReadCount > 0);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            title: const Text(
              'إحصائياتي',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded),
                tooltip: 'إعادة ضبط الإحصائيات',
                onPressed: () => _confirmReset(context, statsProvider),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A37), Color(0xFF2D5A52)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 64.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${statsProvider.totalAzkarCount}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'إجمالي الأذكار المقروءة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Stats Row ──────────────────────────────────────
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.auto_awesome_mosaic_rounded,
                        label: 'أذكار اليوم والليلة',
                        value: '${statsProvider.dailyAzkarCount}',
                        color: accentColor,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'الأربعينات النبوية',
                        value: '${statsProvider.fortyDaysCount}',
                        color: const Color(0xFFE67E22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.touch_app_rounded,
                        label: 'تسبيحات المسبحة',
                        value: '${statsProvider.tasbeehCount}',
                        color: const Color(0xFF9B59B6),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Time Card ────────────────────────────────────────────
                  _TimeCard(
                    duration: StatsProvider.formatDuration(statsProvider.totalTimeSeconds),
                    primaryColor: primaryColor,
                  ),

                  const SizedBox(height: 24),

                  // ── Section Header ───────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.only(right: 4, bottom: 12),
                    child: Text(
                      'تفاصيل قراءة الأذكار',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A37),
                      ),
                    ),
                  ),

                  // ── Categories List ──────────────────────────────────────
                  if (readCategories.isEmpty)
                    const _EmptyStats()
                  else
                    ...readCategories.map((category) {
                      final stat = statsProvider.categoryStats[category.id] ?? CategoryStat();
                      return _CategoryCard(
                        title: category.title,
                        stat: stat,
                        primaryColor: primaryColor,
                        accentColor: accentColor,
                      );
                    }),

                  // ── Tasbeeh Details Section ──────────────────────────────
                  if (statsProvider.tasbeehDhikrStats.entries.any((e) => e.value > 0)) ...[
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(right: 4, bottom: 12),
                      child: Text(
                        'تفاصيل تسبيحات المسبحة',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A37),
                        ),
                      ),
                    ),
                    ...statsProvider.tasbeehDhikrStats.entries.where((e) => e.value > 0).map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B59B6).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.touch_app_rounded,
                                color: Color(0xFF9B59B6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A37),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B59B6).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${entry.value} مرة',
                                style: const TextStyle(
                                  color: Color(0xFF9B59B6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, StatsProvider statsProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد التصفير', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('هل أنت متأكد من إعادة ضبط وتصفير جميع الإحصائيات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              statsProvider.resetStats();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إعادة ضبط الإحصائيات.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('تصفير'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String duration;
  final Color primaryColor;

  const _TimeCard({required this.duration, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [primaryColor, const Color(0xFF2D5A52)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الوقت الكلي في الأذكار',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final CategoryStat stat;
  final Color primaryColor;
  final Color accentColor;

  const _CategoryCard({
    required this.title,
    required this.stat,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isComplete = stat.readCount > 0;
    final Color badgeColor = isComplete ? accentColor : const Color(0xFFE67E22);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isComplete ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: badgeColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(
                  label: 'مرات الإكمال',
                  value: '${stat.readCount}',
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  label: 'أذكار مقروءة',
                  value: '${stat.itemsReadCount}',
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF7F8C8D).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF7F8C8D)),
                    const SizedBox(width: 6),
                    Text(
                      'الوقت المستغرق: ',
                      style: TextStyle(fontSize: 12, color: const Color(0xFF7F8C8D).withValues(alpha: 0.8)),
                    ),
                    Text(
                      StatsProvider.formatDuration(stat.timeSpentSeconds),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7F8C8D),
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
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.auto_graph_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد إحصائيات بعد',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ بقراءة الأذكار\nوستظهر إحصائياتك هنا 📊',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.6),
          ),
        ],
      ),
    );
  }
}