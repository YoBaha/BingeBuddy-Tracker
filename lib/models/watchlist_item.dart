class WatchlistItem {
  final int? id; // Matches the id column in the watchlist table
  final String itemId;
  final String itemType;
  final int priority; // Use priority as the rating
  final Map<String, dynamic> metadata;

  WatchlistItem({
    this.id,
    required this.itemId,
    required this.itemType,
    required this.priority,
    required this.metadata,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'],
      itemId: json['item_id'],
      itemType: json['item_type'],
      priority: json['priority'] ?? 1, // Default to 1 if not present
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_type': itemType,
      'priority': priority,
      'metadata': metadata,
    };
  }
}