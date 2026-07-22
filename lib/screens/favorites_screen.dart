import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/azkar_provider.dart';
import '../widgets/category_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفئات المفضلة', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AzkarProvider>(
        builder: (context, provider, child) {
          final favorites = provider.getFavoriteCategories();

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فئات مفضلة حتى الآن\nاضغط على رمز القلب بجوار أي فئة لإضافتها هنا',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return CategoryCard(
                key: ValueKey(favorites[index].id),
                category: favorites[index],
              );
            },
          );
        },
      ),
    );
  }
}
