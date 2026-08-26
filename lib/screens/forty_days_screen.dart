import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:adhan/adhan.dart';
import '../providers/forty_days_provider.dart';
import '../providers/prayer_provider.dart';
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

  DateTime? _getPrayerTime(PrayerTimes? prayerTimes, String prayerName) {
    if (prayerTimes == null) return null;
    switch (prayerName) {
      case 'الفجر':
        return prayerTimes.fajr;
      case 'الظهر':
        return prayerTimes.dhuhr;
      case 'العصر':
        return prayerTimes.asr;
      case 'المغرب':
        return prayerTimes.maghrib;
      case 'العشاء':
        return prayerTimes.isha;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FortyDaysProvider>(context);
    final prayerProvider = Provider.of<PrayerProvider>(context);
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
          
          // Collapsible Saved Mosques Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                ),
              ),
              onPressed: () => _showSavedMosquesBottomSheet(context, provider, state, theme),
              icon: const Icon(Icons.mosque, size: 22),
              label: const Text(
                'المساجد المحفوظة وإحصائياتها 🕌',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Mosque Period Report Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.secondary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.15)),
                ),
              ),
              onPressed: () => _showMosquePeriodReportSheet(context, state, theme),
              icon: const Icon(Icons.analytics_outlined, size: 22),
              label: const Text(
                'تقرير صلوات المساجد بالفترة 📊',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                              final prayerTimes = prayerProvider.prayerTimes;
                              if (prayerTimes == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الرجاء الانتظار حتى تحميل مواقيت الصلاة للتحقق من دخول الوقت.')),
                                  );
                                }
                                return;
                              }
                              final pTime = _getPrayerTime(prayerTimes, pName);
                              if (pTime != null && DateTime.now().isBefore(pTime)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('لم يحن وقت صلاة $pName بعد. لا يمكن الإثبات قبل دخول الوقت.')),
                                  );
                                }
                                return;
                              }

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
                              final prayerTimes = prayerProvider.prayerTimes;
                              if (prayerTimes == null) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('الرجاء الانتظار حتى تحميل مواقيت الصلاة للتحقق من دخول الوقت.')),
                                  );
                                }
                                return;
                              }
                              final pTime = _getPrayerTime(prayerTimes, pName);
                              if (pTime != null && DateTime.now().isBefore(pTime)) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('لم يحن وقت صلاة $pName بعد. لا يمكن الإثبات قبل دخول الوقت.')),
                                  );
                                }
                                return;
                              }

                              _showManualCheckInSheet(context, provider, pName, theme);
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
    if (prayerLog.mosqueName != null && prayerLog.mosqueName!.isNotEmpty) {
      return Text('تم الإثبات يدوياً في "${prayerLog.mosqueName}" الساعة $timeStr');
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
    required int dayIndex,
    required bool isToday,
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
        return Consumer<FortyDaysProvider>(
          builder: (context, provider, _) {
            final currentState = provider.state!;
            
            // Extract prayers & completion status dynamically from provider state
            Map<String, PrayerLog> prayers = {};
            bool isSuccess = false;
            if (isToday) {
              prayers = currentState.todaysPrayers;
              isSuccess = prayers.values.every((p) => p.isCompleted);
            } else {
              final historyIndex = dayIndex - 1;
              if (historyIndex >= 0 && historyIndex < currentState.history.length) {
                final progress = currentState.history[historyIndex];
                prayers = progress.prayers;
                isSuccess = progress.isSuccess;
              }
            }

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
                              if (completed) ...[
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                                  tooltip: 'تعديل اسم المسجد لهذه الصلاة',
                                  onPressed: () {
                                    _showEditPrayerMosqueDialog(
                                      context: context,
                                      provider: provider,
                                      prayerName: pName,
                                      currentMosqueName: log?.mosqueName,
                                      historyDayIndex: isToday ? null : dayIndex - 1,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.undo, color: Colors.redAccent, size: 20),
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
                                            onPressed: () async {
                                              if (isToday) {
                                                await provider.unmarkPrayerCompleted(pName);
                                              } else {
                                                await provider.setPastDayPrayerStatus(dayIndex - 1, pName, false);
                                              }
                                              if (ctx.mounted) Navigator.pop(ctx);
                                            },
                                            child: const Text('نعم، الغِ الإثبات', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ] else ...[
                                IconButton(
                                  icon: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 20),
                                  tooltip: 'إثبات الصلاة يدوياً في المسجد',
                                  onPressed: () {
                                    _showManualCheckInSheet(
                                      context,
                                      provider,
                                      pName,
                                      theme,
                                      historyIndex: isToday ? null : dayIndex - 1,
                                    );
                                  },
                                ),
                              ]
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
      },
    );
  }

  Map<String, int> _getMosqueStats(FortyDaysState state, String mosqueName) {
    int total = 0;
    final Map<String, int> breakdown = {
      'الفجر': 0,
      'الظهر': 0,
      'العصر': 0,
      'المغرب': 0,
      'العشاء': 0,
    };

    // Check today's logged prayers
    state.todaysPrayers.forEach((pName, log) {
      if (log.isCompleted && log.mosqueName == mosqueName) {
        total++;
        breakdown[pName] = (breakdown[pName] ?? 0) + 1;
      }
    });

    // Check history
    for (var progress in state.history) {
      progress.prayers.forEach((pName, log) {
        if (log.isCompleted && log.mosqueName == mosqueName) {
          total++;
          breakdown[pName] = (breakdown[pName] ?? 0) + 1;
        }
      });
    }

    return {
      'total': total,
      'الفجر': breakdown['الفجر'] ?? 0,
      'الظهر': breakdown['الظهر'] ?? 0,
      'العصر': breakdown['العصر'] ?? 0,
      'المغرب': breakdown['المغرب'] ?? 0,
      'العشاء': breakdown['العشاء'] ?? 0,
    };
  }

  void _showMosqueStatsDialog(
    BuildContext context,
    FortyDaysState state,
    SavedMosque mosque,
    ThemeData theme,
  ) {
    final stats = _getMosqueStats(state, mosque.name);
    final total = stats['total'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.mosque, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mosque.name,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location Details Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الموقع الجغرافي:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'خط العرض: ${mosque.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                      ),
                      Text(
                        'خط الطول: ${mosque.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Total Prayers Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إجمالي الصلوات المؤداة فيه:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$total صلاة',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Breakdown list
                const Text(
                  'تفاصيل الصلوات:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                ...['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((pName) {
                  final count = stats[pName] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '$count فرض',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: count > 0 ? theme.colorScheme.primary : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showSavedMosquesBottomSheet(
    BuildContext context,
    FortyDaysProvider provider,
    FortyDaysState state,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return AnimatedBuilder(
              animation: provider,
              builder: (context, _) {
                final currentState = provider.state!;
                
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'المساجد المحفوظة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط على اسم المسجد لعرض إحصائياته وموقعه الجغرافي.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 24),
                      
                      Expanded(
                        child: currentState.savedMosques.isEmpty
                            ? Center(
                                child: Text(
                                  'لم تقم بحفظ أي مسجد بعد. احفظ موقع المساجد الحالية للتحقق التلقائي.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: currentState.savedMosques.length,
                                itemBuilder: (context, index) {
                                  final mosque = currentState.savedMosques[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        child: Icon(Icons.mosque, color: theme.colorScheme.primary, size: 20),
                                      ),
                                      title: Text(
                                        mosque.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: const Text(
                                        'اضغط للتفاصيل والإحصائيات 📊',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        _showMosqueStatsDialog(context, currentState, mosque, theme);
                                      },
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                                            onPressed: () {
                                              _showRenameMosqueDialog(context, provider, mosque);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (dialogCtx) => AlertDialog(
                                                  title: const Text('حذف المسجد', textAlign: TextAlign.right),
                                                  content: Text('هل تريد بالتأكيد حذف مسجد "${mosque.name}" من المساجد المحفوظة؟', textAlign: TextAlign.right),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(dialogCtx),
                                                      child: const Text('إلغاء'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        provider.deleteMosque(mosque.name);
                                                        Navigator.pop(dialogCtx);
                                                      },
                                                      child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            _showAddMosqueDialog(context, provider);
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            'حفظ موقع المسجد الحالي',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showRenameMosqueDialog(BuildContext context, FortyDaysProvider provider, SavedMosque mosque) {
    final controller = TextEditingController(text: mosque.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم المسجد', textAlign: TextAlign.right),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'اسم المسجد الجديد',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != mosque.name) {
                await provider.renameSavedMosque(mosque.name, newName);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعديل اسم المسجد وتحديث السجل بنجاح!')),
                  );
                }
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showEditPrayerMosqueDialog({
    required BuildContext context,
    required FortyDaysProvider provider,
    required String prayerName,
    required String? currentMosqueName,
    required int? historyDayIndex,
  }) {
    final controller = TextEditingController(text: currentMosqueName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل مسجد صلاة $prayerName', textAlign: TextAlign.right),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'اسم المسجد (أو اتركه فارغاً لإلغاء التحديد)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              await provider.updatePrayerMosqueName(
                prayerName,
                newName.isEmpty ? null : newName,
                historyDayIndex: historyDayIndex,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث مسجد الصلاة بنجاح!')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showManualCheckInSheet(
    BuildContext context,
    FortyDaysProvider provider,
    String prayerName,
    ThemeData theme, {
    int? historyIndex,
  }) async {
    final searchController = TextEditingController();
    
    // We can also silently check for close mosque as suggestion
    SavedMosque? recommendedMosque;
    try {
      recommendedMosque = await provider.verifyLocationGpsSilently();
    } catch (_) {}
    final recommended = recommendedMosque;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final query = searchController.text.trim();
            final savedMosques = provider.state?.savedMosques ?? [];
            final filteredMosques = savedMosques.where((m) {
              return m.name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            historyIndex == null ? 'إثبات صلاة $prayerName يدوياً' : 'تعديل صلاة $prayerName لليوم السابق',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اختر مسجداً من قائمتك أو اكتب اسماً جديداً للبحث والإثبات.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 24),
                      
                      // Search Input
                      TextField(
                        controller: searchController,
                        textAlign: TextAlign.right,
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: 'البحث عن مسجد أو كتابة اسم جديد...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recommended Mosque (GPS suggestion)
                      if (historyIndex == null && recommended != null && query.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await provider.markPrayerCompleted(
                                prayerName,
                                byGps: false,
                                mosqueName: recommended.name,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم الإثبات يدوياً في مسجد: "${recommended.name}"! 🕌')),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Icon(Icons.stars, color: theme.colorScheme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'مسجد مقترح بالقرب منك (بالـ GPS):',
                                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        recommended.name,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Mosque Options List
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            // 1. Without Mosque
                            Card(
                              elevation: 0,
                              color: Colors.grey[100],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const Icon(Icons.location_off, color: Colors.grey),
                                title: const Text('إثبات بدون تحديد مسجد', style: TextStyle(fontWeight: FontWeight.bold)),
                                onTap: () async {
                                  if (historyIndex == null) {
                                    await provider.markPrayerCompleted(prayerName, byGps: false, mosqueName: null);
                                  } else {
                                    await provider.setPastDayPrayerStatus(historyIndex, prayerName, true, mosqueName: null);
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم الإثبات يدوياً بنجاح!')),
                                    );
                                  }
                                },
                              ),
                            ),
                            
                            // 2. Custom typed name if query not empty
                            if (query.isNotEmpty) ...[
                              Card(
                                elevation: 0,
                                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.2)),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.add_location_alt, color: theme.colorScheme.secondary),
                                  title: Text('إثبات في مسجد جديد باسم: "$query"', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  onTap: () async {
                                    if (historyIndex == null) {
                                      await provider.markPrayerCompleted(prayerName, byGps: false, mosqueName: query);
                                    } else {
                                      await provider.setPastDayPrayerStatus(historyIndex, prayerName, true, mosqueName: query);
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('تم الإثبات يدوياً في مسجد: "$query"!')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            if (filteredMosques.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                child: Text(
                                  'المساجد المحفوظة المطابقة:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                                ),
                              ),
                              ...filteredMosques.map((m) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                      child: Icon(Icons.mosque, color: theme.colorScheme.primary, size: 18),
                                    ),
                                    title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    onTap: () async {
                                      if (historyIndex == null) {
                                        await provider.markPrayerCompleted(prayerName, byGps: false, mosqueName: m.name);
                                      } else {
                                        await provider.setPastDayPrayerStatus(historyIndex, prayerName, true, mosqueName: m.name);
                                      }
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('تم الإثبات يدوياً في مسجد: "${m.name}"! 🕌')),
                                        );
                                      }
                                    },
                                  ),
                                );
                              }),
                            ] else if (query.isEmpty) ...[
                              const SizedBox(height: 24),
                              const Center(
                                child: Text(
                                  'لا يوجد مساجد محفوظة. اكتب اسماً في خانة البحث لتسجيله.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 24),
                              const Center(
                                child: Text(
                                  'لا توجد مساجد محفوظة مطابقة لبحثك. يمكنك استخدام الخيار أعلاه للإثبات بالاسم المكتوب.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showMosquePeriodReportSheet(
    BuildContext context,
    FortyDaysState state,
    ThemeData theme,
  ) {
    // Initial date range: from challenge start date to today
    DateTime reportStart = state.startDate;
    DateTime reportEnd = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final stats = _calculatePeriodStats(
              state: state,
              startDate: reportStart,
              endDate: reportEnd,
            );

            final totalPeriodPrayers = stats.fold<int>(0, (sum, item) => sum + item.totalCount);
            final startStr = intl.DateFormat('yyyy/MM/dd').format(reportStart);
            final endStr = intl.DateFormat('yyyy/MM/dd').format(reportEnd);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: theme.colorScheme.secondary, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'تقرير صلوات المساجد بالفترة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'عرض إحصائيات الصلوات في المساجد مجمعة وموحدة خلال فترة محددة.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Divider(height: 20),

                      // Date Range Picker Button
                      InkWell(
                        onTap: () async {
                          final pickedRange = await showDateRangePicker(
                            context: context,
                            initialDateRange: DateTimeRange(start: reportStart, end: reportEnd),
                            firstDate: state.startDate.subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('ar'),
                          );
                          if (pickedRange != null) {
                            setState(() {
                              reportStart = pickedRange.start;
                              reportEnd = pickedRange.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الفترة المحددة:',
                                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'من $startStr إلى $endStr',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Icon(Icons.date_range, color: theme.colorScheme.secondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Period Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إجمالي صلوات المساجد بالفترة:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '$totalPeriodPrayers صلاة',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Mosque list grouped by normalized name
                      Expanded(
                        child: stats.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد صلوات مسجلة في مساجد خلال هذه الفترة.',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: stats.length,
                                itemBuilder: (context, index) {
                                  final item = stats[index];
                                  final percent = totalPeriodPrayers > 0
                                      ? item.totalCount / totalPeriodPrayers
                                      : 0.0;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey[200]!),
                                    ),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                                        child: Icon(Icons.mosque, color: theme.colorScheme.secondary, size: 20),
                                      ),
                                      title: Text(
                                        item.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: percent,
                                              minHeight: 6,
                                              backgroundColor: Colors.grey[200],
                                              color: theme.colorScheme.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'عدد الصلوات: ${item.totalCount} (${(percent * 100).toStringAsFixed(0)}%)',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                          child: Column(
                                            children: ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'].map((pName) {
                                              final count = item.breakdown[pName] ?? 0;
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(pName, style: const TextStyle(fontSize: 13)),
                                                    Text(
                                                      '$count فرض',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: count > 0 ? theme.colorScheme.primary : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<MosquePeriodStat> _calculatePeriodStats({
    required FortyDaysState state,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Map from normalized name to stats
    final Map<String, Map<String, dynamic>> grouped = {};

    // Helper to process a day
    void processDay(DateTime date, Map<String, PrayerLog> prayers) {
      final cleanDate = DateTime(date.year, date.month, date.day);
      final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);
      final cleanEnd = DateTime(endDate.year, endDate.month, endDate.day);

      if (cleanDate.isBefore(cleanStart) || cleanDate.isAfter(cleanEnd)) return;

      prayers.forEach((pName, log) {
        if (log.isCompleted &&
            log.mosqueName != null &&
            log.mosqueName!.trim().isNotEmpty &&
            log.mosqueName!.trim() != 'تعديل يدوي') {
          final origName = log.mosqueName!;
          final norm = FortyDaysProvider.normalizeMosqueName(origName);
          if (norm.isEmpty) return;

          if (!grouped.containsKey(norm)) {
            grouped[norm] = {
              'normalizedName': norm,
              'displayName': origName,
              'totalCount': 0,
              'names': <String, int>{},
              'breakdown': <String, int>{
                'الفجر': 0,
                'الظهر': 0,
                'العصر': 0,
                'المغرب': 0,
                'العشاء': 0,
              },
            };
          }

          final data = grouped[norm]!;
          data['totalCount'] = (data['totalCount'] as int) + 1;
          
          final namesMap = data['names'] as Map<String, int>;
          namesMap[origName] = (namesMap[origName] ?? 0) + 1;

          final bd = data['breakdown'] as Map<String, int>;
          bd[pName] = (bd[pName] ?? 0) + 1;
        }
      });
    }

    // 1. Process today
    processDay(DateTime.now(), state.todaysPrayers);

    // 2. Process history
    for (var progress in state.history) {
      processDay(progress.date, progress.prayers);
    }

    final result = grouped.values.map((data) {
      final namesMap = data['names'] as Map<String, int>;
      String bestDisplayName = data['displayName'] as String;
      int maxCount = 0;
      namesMap.forEach((name, count) {
        if (count > maxCount) {
          maxCount = count;
          bestDisplayName = name;
        }
      });

      return MosquePeriodStat(
        normalizedName: data['normalizedName'] as String,
        displayName: bestDisplayName,
        totalCount: data['totalCount'] as int,
        breakdown: Map<String, int>.from(data['breakdown'] as Map),
      );
    }).toList();

    result.sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return result;
  }
}

class MosquePeriodStat {
  final String normalizedName;
  final String displayName;
  final int totalCount;
  final Map<String, int> breakdown;

  MosquePeriodStat({
    required this.normalizedName,
    required this.displayName,
    required this.totalCount,
    required this.breakdown,
  });
}
