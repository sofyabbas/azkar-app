import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/forty_days_provider.dart';
import '../models/forty_days_model.dart';

class FortyDaysScreen extends StatelessWidget {
  const FortyDaysScreen({super.key});

  int getCurrentStreak(List<DailyProgress> history) {
    int streak = 0;
    for (int i = history.length - 1; i >= 0; i--) {
      if (history[i].isSuccess) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int getMaxStreak(List<DailyProgress> history) {
    int maxStreak = 0;
    int current = 0;
    for (var day in history) {
      if (day.isSuccess) {
        current++;
        if (current > maxStreak) {
          maxStreak = current;
        }
      } else {
        current = 0;
      }
    }
    return maxStreak;
  }

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

    final int currentStreak = getCurrentStreak(state.history);
    final int maxStreak = getMaxStreak(state.history);
    final bool isTodayCompleted = state.todaysPrayers.values.every((p) => p.isCompleted);
    final int displayStreak = currentStreak + (isTodayCompleted ? 1 : 0);
    final int displayMaxStreak = math.max(maxStreak, displayStreak);
    final double progress = (displayStreak / 40.0).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مشروع 40 يوم', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              provider.currentUser != null ? Icons.cloud_sync : Icons.cloud_off,
              color: provider.currentUser != null ? Colors.white : Colors.white60,
            ),
            tooltip: provider.currentUser != null ? 'مزامنة سحابية' : 'مزامنة غير مفعلة (سجل الدخول)',
            onPressed: () async {
              if (provider.currentUser == null) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('المزامنة السحابية', textAlign: TextAlign.right),
                    content: const Text(
                      'المزامنة السحابية غير نشطة. يرجى تسجيل الدخول بحساب جوجل من صفحة "الحساب" لتتمكن من مزامنة تقدمك والمساجد المحفوظة عبر أجهزتك المختلفة.',
                      textAlign: TextAlign.right,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري مزامنة بيانات التحدي سحابياً...'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              await provider.syncData();
              if (context.mounted) {
                if (provider.errorMessage.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.errorMessage),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت مزامنة بيانات التحدي والمساجد بنجاح! ☁️'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
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
                  Text('السلسلة الحالية: $displayStreak من 40 يوم', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),

          // GitHub Progress Grid
          _buildProgressGrid(state, theme, currentStreak),
          const SizedBox(height: 16),

          // Achievements/Badges
          _buildBadgesSection(state, theme, displayMaxStreak),
          const SizedBox(height: 16),
          
          // Mosque Locations Setup
          Card(
            elevation: 1.5,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'مساجدي المحفوظة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (state.savedMosques.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'لم تقم بحفظ أي مسجد بعد. احفظ موقع المساجد التي تصلي فيها لتتمكن من إثبات صلاتك بالـ GPS.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.savedMosques.length,
                      itemBuilder: (context, index) {
                        final mosque = state.savedMosques[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  mosque.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  provider.deleteMosque(mosque.name);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddMosqueDialog(context, provider),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('حفظ موقع المسجد الحالي'),
                    ),
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
                subtitle: _buildPrayerSubtitle(prayerLog),
                trailing: isCompleted
                    ? IconButton(
                        icon: const Icon(Icons.undo, color: Colors.redAccent),
                        tooltip: 'إلغاء الإثبات',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('إلغاء الإثبات', textAlign: TextAlign.right),
                              content: Text('هل تريد إلغاء إثبات صلاة $pName؟', textAlign: TextAlign.right),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                TextButton(
                                  onPressed: () {
                                    provider.unmarkPrayerCompleted(pName);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('نعم، الغِ الإثبات', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.location_on_outlined, color: theme.colorScheme.secondary),
                            tooltip: 'إثبات بالـ GPS',
                            onPressed: () async {
                              final matchedMosque = await provider.verifyLocationWithGps();
                              if (matchedMosque != null) {
                                await provider.markPrayerCompleted(pName, byGps: true, mosqueName: matchedMosque.name);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم الإثبات بنجاح في "${matchedMosque.name}"!')),
                                  );
                                }
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage)));
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                            tooltip: 'إثبات يدوي',
                            onPressed: () async {
                              final closeMosque = await provider.verifyLocationGpsSilently();
                              await provider.markPrayerCompleted(
                                pName,
                                byGps: false,
                                mosqueName: closeMosque?.name,
                              );
                              if (context.mounted) {
                                if (closeMosque != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('تم الإثبات يدوياً وتحديد المسجد: "${closeMosque.name}" تلقائياً! 🕌')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم الإثبات يدوياً بنجاح!')),
                                  );
                                }
                              }
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

  Widget _buildProgressGrid(FortyDaysState state, ThemeData theme, int currentStreak) {
    final history = state.history;
    final int totalGridItems = history.length + (40 - currentStreak).clamp(1, 40);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مسار الأربعين يوماً',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: totalGridItems,
              itemBuilder: (context, index) {
                Color cellColor;
                Color textColor = Colors.white;
                VoidCallback? onTap;

                if (index < history.length) {
                  final dayProgress = history[index];
                  if (dayProgress.isSuccess) {
                    cellColor = const Color(0xFF2E7D32);
                  } else {
                    cellColor = const Color(0xFFFFB300);
                  }
                  onTap = () {
                    _showDayDetailsBottomSheet(
                      context: context,
                      date: dayProgress.date,
                      prayers: dayProgress.prayers,
                      isSuccess: dayProgress.isSuccess,
                      dayIndex: index + 1,
                      isToday: false,
                    );
                  };
                } else if (index == history.length) {
                  final completedCount = state.todaysPrayers.values.where((p) => p.isCompleted).length;
                  if (completedCount == 5) {
                    cellColor = const Color(0xFF2E7D32);
                  } else if (completedCount > 0) {
                    cellColor = const Color(0xFFFF9800);
                  } else {
                    cellColor = Colors.grey[350]!;
                    textColor = Colors.black87;
                  }
                  onTap = () {
                    _showDayDetailsBottomSheet(
                      context: context,
                      date: DateTime.now(),
                      prayers: state.todaysPrayers,
                      isSuccess: completedCount == 5,
                      dayIndex: index + 1,
                      isToday: true,
                    );
                  };
                } else {
                  cellColor = Colors.grey[200]!;
                  textColor = Colors.black54;
                  onTap = null;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(8),
                        border: index == history.length
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
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

  Widget _buildBadgesSection(FortyDaysState state, ThemeData theme, int displayMaxStreak) {
    final bool isBadge1Unlocked = displayMaxStreak >= 3;
    final bool isBadge2Unlocked = displayMaxStreak >= 10;
    final bool isBadge3Unlocked = displayMaxStreak >= 25;
    final bool isBadge4Unlocked = displayMaxStreak >= 40;

    final badges = [
      {
        'emoji': '🎖️',
        'title': 'بداية الهمة (3 أيام)',
        'desc': 'المحافظة على الجماعة لـ 3 أيام متتالية',
        'unlocked': isBadge1Unlocked,
      },
      {
        'emoji': '⚡',
        'title': 'المواظب (10 أيام)',
        'desc': 'المحافظة على الجماعة لـ 10 أيام متتالية',
        'unlocked': isBadge2Unlocked,
      },
      {
        'emoji': '🕌',
        'title': 'نور المساجد (25 يوماً)',
        'desc': 'المحافظة على الجماعة لـ 25 يوماً متتالية',
        'unlocked': isBadge3Unlocked,
      },
      {
        'emoji': '👑',
        'title': 'الفائز بالبراءتين (40 يوماً)',
        'desc': 'أتممت 40 يوماً يدرك التكبيرة الأولى بنجاح!',
        'unlocked': isBadge4Unlocked,
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أوسمة التحدي وإنجازاتك',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(height: 24),
            ...badges.map((badge) {
              final bool unlocked = badge['unlocked'] as bool;
              return Opacity(
                opacity: unlocked ? 1.0 : 0.45,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: unlocked ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge['emoji'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                       ),
                       const SizedBox(width: 14),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               badge['title'] as String,
                               style: TextStyle(
                                 fontWeight: FontWeight.bold,
                                 fontSize: 14,
                                 color: unlocked ? theme.colorScheme.primary : Colors.black87,
                               ),
                             ),
                             const SizedBox(height: 2),
                             Text(
                               badge['desc'] as String,
                               style: TextStyle(color: Colors.grey[600], fontSize: 12),
                             ),
                           ],
                         ),
                       ),
                       if (unlocked)
                         const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 22)
                       else
                         const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                     ],
                   ),
                 ),
               );
             }),
           ],
         ),
       ),
     );
   }

  Widget _buildPrayerSubtitle(PrayerLog? prayerLog) {
    if (prayerLog == null || !prayerLog.isCompleted) {
      return const Text('في انتظار الإثبات');
    }
    final timeStr = prayerLog.completedAt != null
        ? intl.DateFormat.jm('ar').format(prayerLog.completedAt!)
        : '';
    
    if (prayerLog.verifiedByGps == true) {
      if (prayerLog.mosqueName != null && prayerLog.mosqueName!.isNotEmpty) {
        return Text('تم الإثبات بالـ GPS في "${prayerLog.mosqueName}" الساعة $timeStr');
      }
      return Text('تم الإثبات بالـ GPS الساعة $timeStr');
    }
    return Text('تم الإثبات يدوياً الساعة $timeStr');
  }

  void _showAddMosqueDialog(BuildContext context, FortyDaysProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حفظ موقع المسجد الحالي', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'أدخل اسماً للمسجد ليتم حفظ موقعك الجغرافي الحالي به (مثال: مسجد البيت، مسجد الشغل، مسجد المحطة):',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'اسم المسجد',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري تحديد موقعك وحفظ المسجد...'), duration: Duration(seconds: 2)),
                );
                await provider.saveMosqueLocation(name);
                if (provider.errorMessage.isNotEmpty && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage)));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ موقع "$name" بنجاح!')));
                }
              }
            },
            child: const Text('حفظ الموقع'),
          ),
        ],
      ),
    );
  }

  void _showDayDetailsBottomSheet({
    required BuildContext context,
    required DateTime date,
    required Map<String, PrayerLog> prayers,
    required bool isSuccess,
    required int dayIndex,
    bool isToday = false,
  }) {
    final formattedDate = intl.DateFormat('EEEE، d MMMM yyyy', 'ar').format(date);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تفاصيل اليوم $dayIndex',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isSuccess ? 'مكتمل بنجاح 🎉' : (isToday ? 'جاري التحدي ⚡' : 'غير مكتمل ⚠️'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSuccess ? const Color(0xFF2E7D32) : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'الصلوات الخمس في الجماعة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((pName) {
                    final log = prayers[pName];
                    final completed = log?.isCompleted ?? false;
                    final completedAtStr = log?.completedAt != null
                        ? intl.DateFormat.jm('ar').format(log!.completedAt!)
                        : '';
                    
                    String detailText = 'لم تؤدَّ في المسجد';
                    IconData icon = Icons.cancel_outlined;
                    Color iconColor = Colors.redAccent;
                    
                    if (completed) {
                      icon = Icons.check_circle;
                      iconColor = const Color(0xFF2E7D32);
                      if (log?.verifiedByGps == true) {
                        detailText = 'أديت في جماعة (بالـ GPS) في "${log?.mosqueName ?? 'مسجد محفوظ'}" الساعة $completedAtStr';
                      } else {
                        detailText = 'أديت في جماعة (يدوي)${log?.mosqueName != null ? ' في "${log!.mosqueName}"' : ''} الساعة $completedAtStr';
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: completed
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: iconColor, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detailText,
                                  style: TextStyle(
                                    color: completed ? Colors.grey[800] : Colors.grey[500],
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
