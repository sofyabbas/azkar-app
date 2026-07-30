import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zikr_model.dart';
import '../widgets/zikr_card.dart';
import '../providers/azkar_provider.dart';
import '../providers/stats_provider.dart';

class CategoryScreen extends StatefulWidget {
  final AzkarCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  final Stopwatch _sessionStopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _sessionStopwatch.start();
    // Log reading time every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _stopwatch.isRunning) {
        final elapsed = _stopwatch.elapsed.inSeconds;
        if (elapsed > 0) {
          _stopwatch.reset();
          Provider.of<StatsProvider>(context, listen: false).recordTimeSpent(
            categoryId: widget.category.id,
            seconds: elapsed,
          );
        }
      }
    });
  }

  void _onExitScreen() async {
    final totalSeconds = _sessionStopwatch.elapsed.inSeconds;
    if (totalSeconds >= 3) {
      final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
      final isCompleted = await azkarProvider.isCategoryCompletedToday(widget.category);
      
      if (!mounted) return;
      if (isCompleted) {
        Provider.of<StatsProvider>(context, listen: false).recordCategoryCompleted(widget.category.id);
      }

      String timeText;
      if (totalSeconds < 60) {
        timeText = '$totalSeconds ثانية';
      } else {
        final mins = totalSeconds ~/ 60;
        final secs = totalSeconds % 60;
        timeText = '$mins دقيقة و $secs ثانية';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.favorite,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isCompleted
                        ? 'تقبل الله طاعتك! 🤲 أتممت ${widget.category.title} في $timeText 🎉'
                        : 'جزاك الله خيراً! 🤲 قضيت $timeText في قراءة ${widget.category.title}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E3A20),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_stopwatch.isRunning) {
      final elapsed = _stopwatch.elapsed.inSeconds;
      if (elapsed > 0) {
        try {
          Provider.of<StatsProvider>(context, listen: false).recordTimeSpent(
            categoryId: widget.category.id,
            seconds: elapsed,
          );
        } catch (_) {}
      }
      _stopwatch.stop();
    }
    _sessionStopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _onExitScreen();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category.title),
          actions: [
            Consumer<AzkarProvider>(
              builder: (context, azkarProvider, child) {
                final isFav = azkarProvider.isFavoriteCategory(widget.category.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null,
                    size: 26,
                  ),
                  onPressed: () {
                    azkarProvider.toggleFavoriteCategory(widget.category.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isFav
                              ? 'تمت إضافة "${widget.category.title}" إلى الفئات المفضلة ❤️'
                              : 'تمت إزالة "${widget.category.title}" من الفئات المفضلة',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: isFav ? 'إزالة الفئة من المفضلة' : 'إضافة الفئة للمفضلة',
                );
              },
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: widget.category.items.length,
          itemBuilder: (context, index) {
            final zikr = widget.category.items[index];
            return ZikrCard(
              zikr: zikr,
              categoryId: widget.category.id,
              index: index + 1,
            );
          },
        ),
      ),
    );
  }
}
