import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zikr_model.dart';
import '../providers/azkar_provider.dart';
import '../screens/category_screen.dart';

class CategoryCard extends StatelessWidget {
  final AzkarCategory category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AzkarProvider>(context);
    final progress = provider.getCategoryProgress(category);
    final bool isCompleted = progress.isCompleted;
    const primaryColor = Color(0xFF1E3A37);
    const completedGreen = Color(0xFF2E7D32);

    final Color cardBgColor = isCompleted
        ? const Color(0xFFEBF7ED) // Soft light green background when completed
        : Colors.white;

    return Card(
      elevation: isCompleted ? 1 : 1.5,
      margin: EdgeInsets.zero,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCompleted
            ? const BorderSide(color: completedGreen, width: 1.5)
            : BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryScreen(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Center(
            child: Text(
              category.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: isCompleted ? const Color(0xFF1B5E20) : primaryColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
