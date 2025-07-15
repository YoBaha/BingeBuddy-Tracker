class WatchlistItem {
  final String? id;
  final String itemId;
  final String itemType;
  final int priority; 
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
      id: json['id']?.toString(), 
      itemId: json['item_id'] as String? ?? '',
      itemType: json['item_type'] as String? ?? '',
      priority: json['priority'] is String
          ? int.parse(json['priority'])
          : (json['priority'] as num?)?.toInt() ?? 1,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
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