enum EventType {geburtstagBetreuer, geburtstagKunde, turnus, verfuegbar, urlaub}

class CalendarEvent {
  final String id;
  final String title;
  final String betreuerName;
  final DateTime date;
  final EventType type;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.betreuerName,
    required this.date,
    this.type = EventType.turnus,
  });
}