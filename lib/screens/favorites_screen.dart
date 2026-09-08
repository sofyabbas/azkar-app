import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/azkar_provider.dart';
import '../widgets/category_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text('الفئات المفضلة', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AzkarProvider>(
        builder: (context, provider, child) {
          final favoriteCategories = provider.getFavoriteCategories();

          if (favoriteCategories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.folder_special_outlined, size: 64, color: primaryColor),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'لا توجد فئات مفضلة حتى الآن',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اضغط على رمز القلب في شريط عنوان أي فئة أذكار لإضافتها إلى قائمة مفضلتك والوصول إليها بسرعة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.85,
              ),
              itemCount: favoriteCategories.length,
              itemBuilder: (context, index) {
                return CategoryCard(
                  key: ValueKey(favoriteCategories[index].id),
                  category: favoriteCategories[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
