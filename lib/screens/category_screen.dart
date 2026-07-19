import 'package:flutter/material.dart';
import '../models/zikr_model.dart';
import '../widgets/zikr_card.dart';

class CategoryScreen extends StatelessWidget {
  final AzkarCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: category.items.length,
        itemBuilder: (context, index) {
          final zikr = category.items[index];
          return ZikrCard(zikr: zikr);
        },
      ),
    );
  }
}
