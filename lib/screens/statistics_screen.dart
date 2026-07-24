import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/azkar_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = Provider.of<StatsProvider>(context);
    final azkarProvider = Provider.of<AzkarProvider>(context);

    final greenColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'احصائيات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: greenColor),
            tooltip: 'إعادة ضبط الإحصائيات',
            onPressed: () => _confirmReset(context, statsProvider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Overview Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'عدد الأذكار الكلي',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${statsProvider.totalAzkarCount}',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: greenColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Row: Daily Azkar vs Forty Days
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOverviewColumn(
                          context,
                          'أذكار اليوم والليلة',
                          '${statsProvider.dailyAzkarCount}',
                          greenColor,
                        ),
                        _buildOverviewColumn(
                          context,
                          'الأربعينات النبوية',
                          '${statsProvider.fortyDaysCount}',
                          greenColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: theme.dividerColor, height: 1),
                    const SizedBox(height: 16),

                    // Total Time Footer
                    Text(
                      'الوقت الكلي في أذكار التطبيق',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      StatsProvider.formatDuration(statsProvider.totalTimeSeconds),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: greenColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid of Actual Categories
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: azkarProvider.categories.length,
              itemBuilder: (context, index) {
                final category = azkarProvider.categories[index];
                final stat = statsProvider.categoryStats[category.id] ?? CategoryStat();

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          category.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Column(
                          children: [
                            Text(
                              'عدد مرات القراءة',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stat.readCount}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'الأذكار المقروءة',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${stat.itemsReadCount}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          StatsProvider.formatDuration(stat.timeSpentSeconds),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: greenColor,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewColumn(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
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
        title: const Text('تأكيد التصفير', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد من إعادة ضبط وتصفير الإحصائيات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              statsProvider.resetStats();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إعادة ضبط الإحصائيات بنجاح.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تصفير', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
