import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/zikr_model.dart';
import '../providers/azkar_provider.dart';
import '../widgets/category_card.dart';

class OtherAzkarScreen extends StatelessWidget {
  final List<AzkarCategory> otherCategories;

  const OtherAzkarScreen({super.key, required this.otherCategories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكار أخرى', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<AzkarProvider>(
        builder: (context, provider, child) {
          if (otherCategories.isEmpty) {
            return const Center(child: Text('لا توجد أذكار أخرى.'));
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
                childAspectRatio: 2.2,
              ),
              itemCount: otherCategories.length,
              itemBuilder: (context, index) {
                final category = otherCategories[index];
                return CategoryCard(category: category);
              },
            ),
          );
        },
      ),
    );
  }
}
