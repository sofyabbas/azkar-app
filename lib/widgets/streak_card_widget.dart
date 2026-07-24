import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/stats_provider.dart';

class StreakCardWidget extends StatelessWidget {
  const StreakCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return Consumer<StatsProvider>(
      builder: (context, statsProvider, child) {
        final streak = statsProvider.currentStreak;
        final longest = statsProvider.longestStreak;
        final badge = statsProvider.streakBadgeName;

        // Calculate current week's 7 days (Saturday to Friday)
        final now = DateTime.now();
        final currentWeekday = now.weekday; // 1 = Monday, ..., 7 = Sunday
        // Align to Saturday = 0, Sunday = 1, Monday = 2, ..., Friday = 6
        final int daysSinceSaturday = (currentWeekday % 7 == 6)
            ? 0
            : (currentWeekday % 7 == 0)
                ? 1
                : currentWeekday + 1;

        final startOfWeek = now.subtract(Duration(days: daysSinceSaturday));

        final weekDays = List.generate(7, (index) {
          return startOfWeek.add(Duration(days: index));
        });

        const dayNames = ['س', 'ح', 'ن', 'ر', 'خ', 'ج', 'ج']; // س، ح، ن، ر، خ، ج، ج

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A37), Color(0xFF2C5651)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Top Row: Fire Icon & Streak Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                streak == 0
                                    ? 'ابدأ مواظبتك اليوم!'
                                    : 'أنت مواظب منذ $streak ${streak == 1 ? 'يوم' : 'أيام'}!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Weekly Progress Dots Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    final day = weekDays[index];
                    final isActive = statsProvider.isDateActive(day);
                    final isToday = DateFormat('yyyy-MM-dd').format(day) ==
                        DateFormat('yyyy-MM-dd').format(now);

                    return Column(
                      children: [
                        Text(
                          dayNames[index],
                          style: TextStyle(
                            color: isToday ? const Color(0xFFFFD700) : Colors.white70,
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFF4CAF50)
                                : isToday
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.08),
                            border: isToday
                                ? Border.all(color: const Color(0xFFFFD700), width: 1.8)
                                : null,
                          ),
                          child: Center(
                            child: isActive
                                ? const Icon(Icons.check, size: 18, color: Colors.white)
                                : Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color: isToday ? Colors.white : Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 14),

                // Longest Streak Info Footer
                if (longest > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'أطول سلسلة مواظبة: $longest ${longest == 1 ? 'يوم' : 'أيام'} متتالية 🏆',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
