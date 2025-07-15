class WatchedItem {
  final String? id;
  final String itemId;
  final String itemType;
  final int rating;
  final Map<String, dynamic> metadata;

  WatchedItem({
    this.id,
    required this.itemId,
    required this.itemType,
    required this.rating,
    required this.metadata,
  });

  factory WatchedItem.fromJson(Map<String, dynamic> json) {
    return WatchedItem(
      id: json['id']?.toString(),
      itemId: json['item_id'].toString(),
      itemType: json['item_type'],
      rating: json['rating'],
      metadata: json['metadata'] ?? {},
    );
  }
}