import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zikr_model.dart';
import '../providers/azkar_provider.dart';
import '../providers/stats_provider.dart';

class ZikrCard extends StatefulWidget {
  final ZikrItem zikr;
  final String? categoryId;
  final int? index;

  const ZikrCard({
    super.key,
    required this.zikr,
    this.categoryId,
    this.index,
  });

  @override
  State<ZikrCard> createState() => _ZikrCardState();
}

class _ZikrCardState extends State<ZikrCard> {
  late int currentCount;
  late int targetCount;
  DateTime? _lastTapTime;
  bool _isOptionsExpanded = false;

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
          final completedReps = (targetCount - savedCount).clamp(0, targetCount);
          Provider.of<AzkarProvider>(context, listen: false).updateZikrProgress(widget.zikr.id, completedReps, savedCount == 0);
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
    if (mounted) {
      Provider.of<AzkarProvider>(context, listen: false).updateZikrProgress(widget.zikr.id, 0, false);
    }
  }

  void _decrementCount() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 400) {
      return; // Throttling: ignore rapid taps
    }
    _lastTapTime = now;

    if (currentCount > 0) {
      final newCount = currentCount - 1;
      setState(() {
        currentCount = newCount;
      });
      _saveProgress(newCount);
      final azkarProvider = Provider.of<AzkarProvider>(context, listen: false);
      azkarProvider.incrementTotalAzkarRead();
      final completedReps = (targetCount - newCount).clamp(0, targetCount);
      azkarProvider.updateZikrProgress(widget.zikr.id, completedReps, newCount == 0);

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
    Provider.of<AzkarProvider>(context, listen: false).updateZikrProgress(widget.zikr.id, 0, false);
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
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isOptionsExpanded
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The Toggle Button
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                _isOptionsExpanded = !_isOptionsExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'خيارات التكرار: $targetCount ${targetCount == 1 ? 'مرة' : 'مرات'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isOptionsExpanded ? 'إخفاء' : 'تغيير',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isOptionsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isOptionsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 12),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
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
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
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
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getVirtueText(targetCount),
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
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
              // Header with Zikr Index Badge (if available)
              if (widget.index != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'الذكر #${widget.index}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),

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

              // Interactive count options selector (hidden under button by default)
              if (hasOptions) _buildCountOptionsSelector(theme),

              const SizedBox(height: 24),
              // Counter and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isCompleted)
                    Flexible(
                      child: TextButton.icon(
                        onPressed: _resetCount,
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'إعادة التسبيح',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Text(
                                  '$currentCount',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
