class InvoiceItem {
  final String title;
  final String? calculation;
  final double total;

  InvoiceItem({
    required this.title,
    this.calculation,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'calculation': calculation,
        'total': total,
      };

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
        title: json['title'] ?? '',
        calculation: json['calculation'],
        total: (json['total'] as num?)?.toDouble() ?? 0.0,
      );
}

class InvoiceData {
  final String id;
  final String betreuerId;
  final String caregiverName;
  final String period;
  final int month;
  final int year;
  final DateTime createdAt;
  final List<InvoiceItem> items;

  InvoiceData({
    required this.id,
    required this.betreuerId,
    required this.caregiverName,
    required this.period,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.items,
  });

  double get totalSum => items.fold(0.0, (prev, item) => prev + item.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'betreuerId': betreuerId,
        'caregiverName': caregiverName,
        'period': period,
        'month': month,
        'year': year,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory InvoiceData.fromJson(Map<String, dynamic> json) => InvoiceData(
        id: json['id'] ?? '',
        betreuerId: json['betreuerId'] ?? '',
        caregiverName: json['caregiverName'] ?? '',
        period: json['period'] ?? '',
        month: json['month'] ?? 1,
        year: json['year'] ?? DateTime.now().year,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => InvoiceItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
      );
}