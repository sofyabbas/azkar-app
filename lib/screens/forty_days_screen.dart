import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forty_days_provider.dart';

class FortyDaysScreen extends StatelessWidget {
  const FortyDaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FortyDaysProvider>(context);
    final theme = Theme.of(context);
    
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = provider.state;
    if (state == null) {
      return const Center(child: Text('Error loading state'));
    }

    final int currentDay = state.currentDayIndex + 1;
    final double progress = currentDay / 40.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشروع 40 يوم', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('اليوم $currentDay من 40', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text('من صلى لله أربعين يوماً في جماعة يدرك التكبيرة الأولى كتبت له براءتان...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Mosque Location Setup
          Card(
            elevation: 1,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('موقع المسجد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          state.mosqueLocation.isNotEmpty ? 'تم حفظ موقع المسجد بنجاح' : 'لم يتم حفظ موقع المسجد بعد',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await provider.saveMosqueLocation();
                      if (provider.errorMessage.isNotEmpty && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage)));
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الموقع بنجاح!')));
                      }
                    },
                    child: Text(state.mosqueLocation.isNotEmpty ? 'تحديث' : 'حفظ'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Prayers List
          Text('صلوات اليوم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
          ...['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((pName) {
            final prayerLog = state.todaysPrayers[pName];
            final isCompleted = prayerLog?.isCompleted ?? false;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isCompleted ? BorderSide(color: theme.colorScheme.primary, width: 1.5) : BorderSide.none),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted ? theme.colorScheme.primary : Colors.grey[300],
                  child: Icon(isCompleted ? Icons.check : Icons.access_time, color: isCompleted ? Colors.white : Colors.grey[600]),
                ),
                title: Text(pName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: isCompleted ? const Text('تمت الصلاة جماعة') : const Text('في انتظار الإثبات'),
                trailing: isCompleted ? null : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary),
                      tooltip: 'إثبات بالـ GPS',
                      onPressed: () async {
                        bool verified = await provider.verifyLocationWithGps();
                        if (verified) {
                          await provider.markPrayerCompleted(pName, byGps: true);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإثبات بنجاح!')));
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage)));
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                      tooltip: 'إثبات يدوي',
                      onPressed: () async {
                        await provider.markPrayerCompleted(pName, byGps: false);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.restart_alt, color: Colors.red),
              label: const Text('إعادة تعيين التحدي', style: TextStyle(color: Colors.red)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('إعادة تعيين'),
                    content: const Text('هل أنت متأكد من رغبتك في تصفير العداد والبدء من جديد؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                      TextButton(
                        onPressed: () {
                          provider.resetChallenge();
                          Navigator.pop(ctx);
                        }, 
                        child: const Text('نعم، ابدأ من جديد', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
