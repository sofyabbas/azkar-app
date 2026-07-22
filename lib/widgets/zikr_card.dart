import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zikr_model.dart';
import '../providers/azkar_provider.dart';

class ZikrCard extends StatefulWidget {
  final ZikrItem zikr;

  const ZikrCard({super.key, required this.zikr});

  @override
  State<ZikrCard> createState() => _ZikrCardState();
}

class _ZikrCardState extends State<ZikrCard> {
  late int currentCount;

  @override
  void initState() {
    super.initState();
    currentCount = widget.zikr.count;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString('zikr_date_${widget.zikr.id}');
    
    if (savedDate == today) {
      final savedCount = prefs.getInt('zikr_${widget.zikr.id}');
      if (savedCount != null && mounted) {
        setState(() {
          currentCount = savedCount;
        });
      }
    }
  }

  Future<void> _saveProgress(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt('zikr_${widget.zikr.id}', count);
    await prefs.setString('zikr_date_${widget.zikr.id}', today);
  }

  void _decrementCount() {
    if (currentCount > 0) {
      setState(() {
        currentCount--;
      });
      _saveProgress(currentCount);
      // Increment total count on every tap
      Provider.of<AzkarProvider>(context, listen: false).incrementTotalAzkarRead();
    }
  }

  void _resetCount() {
    setState(() {
      currentCount = widget.zikr.count;
    });
    _saveProgress(currentCount);
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = currentCount == 0;
    final theme = Theme.of(context);

    return Card(
      elevation: isCompleted ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? theme.colorScheme.surfaceContainerHighest : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCompleted
            ? BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1)
            : BorderSide.none,
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: _decrementCount,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Arabic Text
              Text(
                widget.zikr.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.8,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.grey[700] : Colors.black87,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              // Translation
              Text(
                widget.zikr.translation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isCompleted ? Colors.grey[600] : Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              // Counter and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCompleted)
                    TextButton.icon(
                      onPressed: _resetCount,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.primary,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, color: theme.colorScheme.primary, size: 30)
                          : Text(
                              '$currentCount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
