import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/azkar_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/zikr_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF9),
        appBar: AppBar(
          title: const Text('المفضلة', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFAECDCB),
            indicatorColor: Color(0xFFFFD700), // Gold indicator line
            indicatorWeight: 3.0,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: 'الأذكار المفضلة', icon: Icon(Icons.favorite)),
              Tab(text: 'الفئات المفضلة', icon: Icon(Icons.folder_special)),
            ],
          ),
        ),
        body: Consumer<AzkarProvider>(
          builder: (context, provider, child) {
            final favoriteItems = provider.getFavoriteZikrItems();
            final favoriteCategories = provider.getFavoriteCategories();

            return TabBarView(
              children: [
                // Tab 1: Favorite Zikr items
                favoriteItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد أذكار مفضلة حتى الآن\nاضغط على رمز القلب داخل أي ذكر لإضافته هنا',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[800], fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: favoriteItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = favoriteItems[index];
                          return ZikrCard(
                            key: ValueKey('fav_zikr_${item.id}'),
                            zikr: item,
                          );
                        },
                      ),

                // Tab 2: Favorite Categories (Arranged in 2-column Grid matching main screen)
                favoriteCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد فئات مفضلة حتى الآن\nاضغط على رمز القلب بجوار أي فئة لإضافتها هنا',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[800], fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: favoriteCategories.length,
                          itemBuilder: (context, index) {
                            return CategoryCard(
                              key: ValueKey(favoriteCategories[index].id),
                              category: favoriteCategories[index],
                            );
                          },
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
