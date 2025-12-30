class Purchase {
  final String id;
  final String store;
  final String date;
  final double total;
  final int items;

  Purchase({
    required this.id,
    required this.store,
    required this.date,
    required this.total,
    required this.items,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] ?? '',
      store: json['store'] ?? '',
      date: json['date'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      items: json['items'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store': store,
      'date': date,
      'total': total,
      'items': items,
    };
  }
}
