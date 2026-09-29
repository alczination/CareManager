import 'package:flutter/material.dart';

enum EventType {
  geburtstagBetreuer,
  geburtstagKunde,
  turnus,
  verfuegbar,
  urlaub,
  survey, 
  meeting,
  custom, 
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final EventType type;
  final String? relatedPersonId;
  final String? relatedPersonName;
  final int colorValue;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.type = EventType.custom,
    this.relatedPersonId,
    this.relatedPersonName,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'type': type.name,
    'relatedPersonId': relatedPersonId,
    'relatedPersonName': relatedPersonName,
    'colorValue': colorValue,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.custom,
      ),
      relatedPersonId: json['relatedPersonId'] as String?,
      relatedPersonName: json['relatedPersonName'] as String?,
      colorValue: json['colorValue'] as int? ?? Colors.blue.value,
    );
  }
}