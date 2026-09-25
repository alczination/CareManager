import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/calendar_event.dart';
import 'add_turnus_dialog.dart';
import '../../models/turnus.dart';
import '../../models/kunde.dart';
import '../../models/betreuer.dart';

class KalendarzScreen extends StatefulWidget {
  final List<Betreuer> betreuerList;
  final List<Kunde> kundeList;

  const KalendarzScreen({
    super.key,
    this.betreuerList = const [],
    this.kundeList = const [],
  });

  @override
  State<KalendarzScreen> createState() => KalendarzScreenState();
}

class KalendarzScreenState extends State<KalendarzScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Turnus> _turnusList = [];
  static const String _turnusStorageKey = 'turnus_database_v1';

  final Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initData();
  }

  Future<void> _initData() async {
    await reloadTurnusData();
  }

  @override
  void didUpdateWidget(covariant KalendarzScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betreuerList != widget.betreuerList ||
        oldWidget.kundeList != widget.kundeList) {
      reloadTurnusData();
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  DateTime? _parseGeburtsdatum(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim().replaceAll('/', '.').replaceAll('-', '.');
    final parts = clean.split('.');

    if (parts.length == 3) {
      if (parts[0].length <= 2 && parts[2].length == 4) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime.utc(year, month, day);
        }
      }
      if (parts[0].length == 4) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime.utc(year, month, day);
        }
      }
    }
    return null;
  }

  DateTime? _parseVerfuegbarkeit(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim();
    final lower = clean.toLowerCase();
    if (lower.contains('zaraz') || lower.contains('sofort') || lower.contains('teraz')) return null;

    final normalized = clean.replaceAll('/', '.').replaceAll('-', '.');
    final parts = normalized.split('.');
    if (parts.length == 3) {
      if (parts[0].length <= 2 && parts[2].length == 4) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime.utc(y, m, d);
        }
      } else if (parts[0].length == 4) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime.utc(y, m, d);
        }
      }
    }
    return null;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.geburtstagBetreuer:
        return Colors.blueAccent;
      case EventType.geburtstagKunde:
        return Colors.deepPurpleAccent;
      case EventType.verfuegbar:
        return Colors.green;
      case EventType.turnus:
        return Colors.teal;
      case EventType.urlaub:
        return Colors.orange;
    }
  }

  void _loadCalendarEvents(int targetYear) {
    debugPrint("=== PRZELICZANIE KALENDARZA ($targetYear) ===");
    _events.clear();

    // 1. Zaplanowane wyjazdy (Turnusy)
    for (final t in _turnusList) {
      DateTime current = t.startDate;
        if (t.startDate.year == targetYear) {
          final startKey = _normalizeDate(t.startDate);
          final startEvent = CalendarEvent(
            id: 'evturnus##${t.id}##${t.startDate.toIso8601String()}',
            title: 'Rozpoczęcie: ${t.betreuerName} ➔ ${t.kundeName}',
            betreuerName: t.betreuerName,
            date: t.startDate,
            type: EventType.turnus,
          );
          _events.putIfAbsent(startKey, () => []).add(startEvent);
        }
          if (t.endDate.year == targetYear) {
            final endKey = _normalizeDate(t.endDate);
            if (!isSameDay(t.startDate, t.endDate)) {
              final endEvent = CalendarEvent(
                id: 'evturnus##${t.id}##${t.endDate.toIso8601String()}',
                title: 'Zakończenie: ${t.betreuerName} ➔ ${t.kundeName}',
                betreuerName: t.betreuerName,
                date: t.endDate,
                type: EventType.turnus,
              );
              _events.putIfAbsent(endKey, () => []).add(endEvent);
            }
          }
      }
    // 2. Urodziny Opiekunów
    for (final b in widget.betreuerList) {
      final birthDate = _parseGeburtsdatum(b.geburtsdatum);
      if (birthDate == null) continue;
      final birthdayThisYear = DateTime.utc(targetYear, birthDate.month, birthDate.day);
      final normalizedKey = _normalizeDate(birthdayThisYear);
      final wiek = targetYear - birthDate.year;
      final fullName = '${b.vorname} ${b.name}'.trim();

      final event = CalendarEvent(
        id: 'bday_betreuer_${b.id}_$targetYear',
        title: '$fullName ($wiek. urodziny)',
        betreuerName: fullName,
        date: birthdayThisYear,
        type: EventType.geburtstagBetreuer,
      );
      _events.putIfAbsent(normalizedKey, () => []).add(event);
    }

    // 3. Urodziny Podopiecznych
    for (final k in widget.kundeList) {
      final birthDate = _parseGeburtsdatum(k.geburtsdatum);
      if (birthDate == null) continue;

      final birthdayThisYear = DateTime.utc(targetYear, birthDate.month, birthDate.day);
      final normalizedKey = _normalizeDate(birthdayThisYear);
      final wiek = targetYear - birthDate.year;
      final fullName = '${k.vorname} ${k.name}'.trim();

      final event = CalendarEvent(
        id: 'bday_kunde_${k.id}_$targetYear',
        title: 'Podopieczny: $fullName ($wiek l.)',
        betreuerName: fullName,
        date: birthdayThisYear,
        type: EventType.geburtstagKunde,
      );
      _events.putIfAbsent(normalizedKey, () => []).add(event);
    }

    // 4. Dostępność Opiekunów
    for (final b in widget.betreuerList) {
      if (b.isAvailable == false) continue;
      final availDate = _parseVerfuegbarkeit(b.datumVerfuegbarkeit);
      if (availDate == null || availDate.year != targetYear) continue;

      final normalizedKey = _normalizeDate(availDate);
      final fullName = '${b.vorname} ${b.name}'.trim();

      final event = CalendarEvent(
        id: 'avail_betreuer_${b.id}',
        title: 'Dostępność od: $fullName',
        betreuerName: fullName,
        date: availDate,
        type: EventType.verfuegbar,
      );
      _events.putIfAbsent(normalizedKey, () => []).add(event);
    }

    setState(() {});
  }

  Future<void> _loadTurnusData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_turnusStorageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _turnusList = decoded.map((e) => Turnus.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Błąd odczytu turnusów: $e');
      }
    } else {
      _turnusList = [];
    }
    _loadCalendarEvents(_focusedDay.year);
  }

  Future<void> _saveTurnusData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _turnusList.map((t) => t.toJson()).toList();
    await prefs.setString(_turnusStorageKey, jsonEncode(jsonList));
  }

  Future<void> _editTurnusById(String turnusId) async {
    final turnus = _turnusList.cast<Turnus?>().firstWhere(
          (t) => t?.id == turnusId,
          orElse: () => null,
        );
    if (turnus == null) return;

    final updated = await showModalBottomSheet<Turnus>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddTurnusDialog(
        betreuerList: widget.betreuerList,
        kundeList: widget.kundeList,
        turnusToEdit: turnus,
      ),
    );

    if (updated != null) {
      final index = _turnusList.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _turnusList[index] = updated;
      }
      await _saveTurnusData();
      _loadCalendarEvents(_focusedDay.year);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zaktualizowano termin wyjazdu!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  Future<void> _deleteTurnusById(String turnusId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń zaplanowany wyjazd'),
        content: const Text('Czy na pewno chcesz usunąć ten wyjazd z terminarza?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _turnusList.removeWhere((t) => t.id == turnusId);
      await _saveTurnusData();
      _loadCalendarEvents(_focusedDay.year);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wyjazd został usunięty z terminarza')),
        );
      }
    }
  }

  Future<void> reloadTurnusData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_turnusStorageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _turnusList = decoded.map((e) => Turnus.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Błąd odczytu turnusów: $e');
      }
    } else {
      _turnusList = [];
    }
    _loadCalendarEvents(_focusedDay.year);
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Terminarz'),
        backgroundColor: Colors.blue.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież terminarz',
            onPressed: reloadTurnusData,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Dzisiaj',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Zaplanuj wyjazd'),
        tooltip: 'Dodaj turnus',
        onPressed: () async {
          final result = await showModalBottomSheet<Turnus>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => AddTurnusDialog(
              betreuerList: widget.betreuerList,
              kundeList: widget.kundeList,
              initialDate: _selectedDay ?? _focusedDay,
            ),
          );

          if (result != null) {
            final idx = _turnusList.indexWhere((t) => t.id == result.id);
            if (idx != -1) {
              _turnusList[idx] = result;
            } else {
              _turnusList.add(result);
            }
            await _saveTurnusData();
            _loadCalendarEvents(_focusedDay.year);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Zapisano wyjazd: ${result.betreuerName}!'),
                  backgroundColor: Colors.teal,
                ),
              );
            }
          }
        },
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((ev) {
                      final color = _getEventColor(ev.type);
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 0.8),
                      );
                    }).toList(),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) {
                final oldYear = _focusedDay.year;
                _focusedDay = focusedDay;
                if (oldYear != focusedDay.year) {
                  _loadCalendarEvents(focusedDay.year);
                }
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.event_note_outlined, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  'Zdarzenia: ${selectedEvents.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      'Brak zaplanowanych zdarzeń w tym dniu',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final ev = selectedEvents[index];
                      final color = _getEventColor(ev.type);

                      IconData leadingIcon;
                      if (ev.type == EventType.geburtstagBetreuer ||
                          ev.type == EventType.geburtstagKunde) {
                        leadingIcon = Icons.cake_outlined;
                      } else if (ev.type == EventType.verfuegbar) {
                        leadingIcon = Icons.check_circle_outline;
                      } else {
                        leadingIcon = Icons.flight_takeoff;
                      }

                      String badgeText;
                      if (ev.type == EventType.geburtstagBetreuer) {
                        badgeText = 'URODZINY OPIEKUNA';
                      } else if (ev.type == EventType.geburtstagKunde) {
                        badgeText = 'URODZINY KLIENTA';
                      } else if (ev.type == EventType.verfuegbar) {
                        badgeText = 'WOLNA';
                      } else {
                        badgeText = 'TURNUS';
                      }

                      String subtitleText;
                      String? turnusId;

                      if (ev.type == EventType.geburtstagBetreuer) {
                        subtitleText = 'Opiekunka • Pamiętaj o życzeniach!';
                      } else if (ev.type == EventType.geburtstagKunde) {
                        subtitleText = 'Podopieczny • Kontakt z rodziną!';
                      } else if (ev.type == EventType.verfuegbar) {
                        final bId = ev.id.replaceFirst('avail_betreuer_', '');
                        final bMatch = widget.betreuerList.cast<Betreuer?>().firstWhere(
                              (b) => b?.id == bId,
                              orElse: () => null,
                            );
                        subtitleText = bMatch != null
                            ? 'Niemiecki: ${bMatch.deutschKenntnisse} • ${bMatch.fuehrerschein ? "Prawo jazdy kat. B" : "Brak prawa jazdy"}'
                            : 'Dostępna do wyjazdu';
                      } else {
                        // Bezpieczne odczytywanie ID turnusu z evturnus::{ID}::{DATE}
                        final splitParts = ev.id.split('::');
                        if (splitParts.length >= 2) {
                          turnusId = splitParts[1];
                        }
                        subtitleText = 'Obsada zlecenia w toku';
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(leadingIcon, color: color, size: 20),
                          ),
                          title: Text(
                            ev.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (ev.type == EventType.turnus && turnusId != null) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                                  tooltip: 'Edytuj wyjazd',
                                  onPressed: () => _editTurnusById(turnusId!),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                  tooltip: 'Usuń wyjazd',
                                  onPressed: () => _deleteTurnusById(turnusId!),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}