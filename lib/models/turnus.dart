class Turnus {
  final String id;
  final String betreuerId;
  final String betreuerName;
  final String kundeId;
  final String kundeName;
  final DateTime startDate;
  final DateTime endDate;
  final String? notiz;

  Turnus({
    required this.id,
    required this.betreuerId,
    required this.betreuerName,
    required this.kundeId,
    required this.kundeName,
    required this.startDate,
    required this.endDate,
    this.notiz,
  });

  int get durationInDays => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => {
    'id': id,
    'betreuerId': betreuerId,
    'betreuerName': betreuerName,
    'kundeId': kundeId,
    'kundeName': kundeName,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'notiz': notiz,
  };

  factory Turnus.fromJson(Map<String, dynamic> json) => Turnus(
    id: json['id'] as String? ?? '',
    betreuerId: json['betreuerId'] as String? ?? '',
    betreuerName: json['betreuerName'] as String? ?? '',
    kundeId: json['kundeId'] as String? ?? '',
    kundeName: json['kundeName'] as String? ?? '',
    startDate: DateTime.parse(json['startDate']?.toString() ?? '') ?? DateTime.now(), 
    endDate: DateTime.parse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
    notiz: json['notiz'] as String?, 
  );
}