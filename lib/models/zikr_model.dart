class ZikrItem {
  final String id;
  final String arabic;
  final String translation;
  final int count;

  ZikrItem({
    required this.id,
    required this.arabic,
    required this.translation,
    required this.count,
  });

  factory ZikrItem.fromJson(Map<String, dynamic> json) {
    return ZikrItem(
      id: json['id'],
      arabic: json['arabic'],
      translation: json['translation'],
      count: json['count'],
    );
  }
}

class AzkarCategory {
  final String id;
  final String title;
  final String description;
  final List<ZikrItem> items;

  AzkarCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
  });

  factory AzkarCategory.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<ZikrItem> items = itemsList.map((i) => ZikrItem.fromJson(i)).toList();

    return AzkarCategory(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      items: items,
    );
  }
}
