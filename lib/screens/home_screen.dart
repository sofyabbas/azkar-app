import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zikr_model.dart';
import '../providers/azkar_provider.dart';
import '../widgets/category_card.dart';
import '../widgets/streak_card_widget.dart';
import 'other_azkar_screen.dart';
import 'settings_screen.dart';
import 'forty_days_screen.dart';
import 'favorites_screen.dart';
import 'qibla_screen.dart';
import 'tasbeeh_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        title: const Text('أذكار المسلم', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AzkarProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (provider.categories.isEmpty) {
            return const Center(child: Text('لم يتم العثور على أذكار.'));
          }

          const int mainDisplayCount = 7;
          final bool hasMore = provider.categories.length > mainDisplayCount;
          final mainCategories = hasMore
              ? provider.categories.sublist(0, mainDisplayCount)
              : provider.categories;
          final remainingCategories = hasMore
              ? provider.categories.sublist(mainDisplayCount)
              : <AzkarCategory>[];

          final int gridItemCount = mainCategories.length + (hasMore ? 1 : 0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildQuickActions(context),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.9,
                  ),
                  itemCount: gridItemCount,
                  itemBuilder: (context, index) {
                    if (hasMore && index == mainCategories.length) {
                      return _buildOtherCategoriesCard(context, remainingCategories);
                    }
                    final category = mainCategories[index];
                    return CategoryCard(category: category);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtherCategoriesCard(BuildContext context, List<AzkarCategory> remainingCategories) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherAzkarScreen(otherCategories: remainingCategories),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'أخرى',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E3A37),
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF1E3A37)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        // STREAK & HABIT TRACKER CARD (🔥)
        const StreakCardWidget(),
        const SizedBox(height: 16),

        _buildFortyDaysCard(context),
        const SizedBox(height: 12),

        // Action Cards Row (المسبحة الذكية | القبلة | المفضلة)
        Row(
          children: [
            Expanded(child: _buildActionCard(context, 'المسبحة الذكية', Icons.touch_app_rounded, const TasbeehScreen())),
            const SizedBox(width: 10),
            Expanded(child: _buildActionCard(context, 'القبلة', Icons.explore_outlined, const QiblaScreen())),
            const SizedBox(width: 10),
            Expanded(child: _buildActionCard(context, 'المفضلة', Icons.favorite_border_rounded, const FavoritesScreen())),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Widget screen) {
    const primaryColor = Color(0xFF1E3A37);

    return Card(
      elevation: 1.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Icon(icon, size: 26, color: primaryColor),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFortyDaysCard(BuildContext context) {
    const primaryColor = Color(0xFF1E3A37);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FortyDaysScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مشروع 40 يوم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إدراك التكبيرة الأولى في جماعة',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: primaryColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
