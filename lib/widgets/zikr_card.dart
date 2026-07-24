import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zikr_model.dart';
import '../providers/azkar_provider.dart';
import '../providers/stats_provider.dart';

class ZikrCard extends StatefulWidget {
  final ZikrItem zikr;
  final String? categoryId;

  const ZikrCard({
    super.key,
    required this.zikr,
    this.categoryId,
  });

  @override
  State<ZikrCard> createState() => _ZikrCardState();
}

class _ZikrCardState extends State<ZikrCard> {
  late int currentCount;
  late int targetCount;

  @override
  void initState() {
    super.initState();
    targetCount = widget.zikr.count;
    currentCount = widget.zikr.count;
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    // Load custom target count if chosen by user
    final savedTarget = prefs.getInt('target_${widget.zikr.id}');
    if (savedTarget != null) {
      targetCount = savedTarget;
    }

    final savedDate = prefs.getString('zikr_date_${widget.zikr.id}');
    if (savedDate == today) {
      final savedCount = prefs.getInt('zikr_${widget.zikr.id}');
      if (savedCount != null) {
        if (mounted) {
          setState(() {
            currentCount = savedCount;
          });
        }
        return;
      }
    }
    
    if (mounted) {
      setState(() {
        currentCount = targetCount;
      });
    }
  }

  Future<void> _saveProgress(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setInt('zikr_${widget.zikr.id}', count);
    await prefs.setString('zikr_date_${widget.zikr.id}', today);
  }

  Future<void> _onTargetChanged(int newTarget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_${widget.zikr.id}', newTarget);
    setState(() {
      targetCount = newTarget;
      currentCount = newTarget;
    });
    await _saveProgress(newTarget);
  }

  void _decrementCount() {
    if (currentCount > 0) {
      setState(() {
        currentCount--;
      });
      _saveProgress(currentCount);
      Provider.of<AzkarProvider>(context, listen: false).incrementTotalAzkarRead();
      Provider.of<StatsProvider>(context, listen: false).recordZikrRead(
        categoryId: widget.categoryId,
        count: 1,
      );
    }
  }

  void _resetCount() {
    setState(() {
      currentCount = targetCount;
    });
    _saveProgress(currentCount);
  }

  String _getVirtueText(int count) {
    switch (count) {
      case 100:
        return '✨ 100 مرة (الأكمل): كأنما أعتقت 10 رقاب، كُتبت لك 100 حسنة، ومُحيت عنك 100 سيئة، وكانت لك حرزاً من الشيطان.';
      case 10:
        return '✨ 10 مرات: كأنما أعتقت أربعة أنفس من ولد إسماعيل عليه السلام.';
      case 1:
        return '✨ مرة واحدة: حرز وحفظ من الشيطان حتى تمسي (أو تصبح).';
      default:
        return 'فضل عظيم وسنة ثابتة عن النبي ﷺ.';
    }
  }

  Widget _buildCountOptionsSelector(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'اختر عدد التكرار المناسب لوقتك:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.zikr.countOptions!.map((opt) {
              final isSelected = targetCount == opt;
              String labelText = '$opt مرة';
              if (opt == 100) labelText = '100 مرة (الأكمل)';
              if (opt == 10) labelText = '10 مرات';
              if (opt == 1) labelText = 'مرة واحدة';

              return ChoiceChip(
                label: Text(labelText),
                selected: isSelected,
                selectedColor: theme.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (selected) {
                    _onTargetChanged(opt);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getVirtueText(targetCount),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = currentCount == 0;
    final theme = Theme.of(context);
    final bool hasOptions = widget.zikr.countOptions != null && widget.zikr.countOptions!.isNotEmpty;

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
              // Header with Favorite Heart button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<AzkarProvider>(
                    builder: (context, azkarProvider, child) {
                      final isFav = azkarProvider.isFavoriteZikr(widget.zikr.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey[400],
                          size: 24,
                        ),
                        onPressed: () {
                          azkarProvider.toggleFavoriteZikr(widget.zikr.id);
                        },
                        tooltip: isFav ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
                      );
                    },
                  ),
                  if (widget.zikr.count > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'التكرار: ${widget.zikr.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Arabic Text
              Consumer<AzkarProvider>(
                builder: (context, azkarProvider, child) {
                  return Text(
                    widget.zikr.arabic,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: azkarProvider.fontSize,
                      height: 1.8,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.grey[700] : const Color(0xFF1E2827),
                    ),
                    textDirection: TextDirection.rtl,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Translation / Hadith note
              if (widget.zikr.translation.isNotEmpty)
                Text(
                  widget.zikr.translation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isCompleted ? Colors.grey[600] : Colors.grey[800],
                    fontStyle: FontStyle.italic,
                  ),
                ),

              // Interactive count options selector if available
              if (hasOptions) _buildCountOptionsSelector(theme),

              const SizedBox(height: 24),
              // Counter and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCompleted)
                    TextButton.icon(
                      onPressed: _resetCount,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة التسبيح'),
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
