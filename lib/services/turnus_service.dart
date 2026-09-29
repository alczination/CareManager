import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/turnus.dart';
import '../models/kunde.dart';
import '../models/betreuer.dart';
import '../models/calendar_event.dart';
import '../screens/kalendarz/add_turnus_dialog.dart';
import '../screens/kalendarz/add_event_dialog.dart';

class TurnusService {
  static const String _turnusKey = 'turnus_database_v1';
  static const String _kundenKey = 'kunden_database_v1';
  static const String _betreuerKey = 'betreuer_database_v1';
  static const String _eventsKey = 'calendar_events_database_v1';

  static Future<List<Betreuer>> _loadBetreuerList() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_betreuerKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Betreuer.fromJson(e)).toList();
      } catch (_) {
        return [];
      }
  }

   static Future<List<Kunde>> _loadKundenList() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_kundenKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((e) => Kunde.fromJson(e)).toList();
      } catch (_) {
        return [];
      }
  }

  static Future<List<Turnus>> _loadAllTurnusy() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_turnusKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Turnus.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveTurnusList(List<Turnus> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _turnusKey,
      jsonEncode(list.map((t) => t.toJson()).toList()),
    );
  }

  static Future<CalendarEvent?> planAndSaveCalendarEvent({
    required BuildContext context,
    List<Betreuer>? betreuerList,
    List<Kunde>? kundeList,
    DateTime? initialDate,
    EventType? initialType,
  }) async {
    final bList = (betreuerList != null && betreuerList.isNotEmpty) ? betreuerList : await _loadBetreuerList();
    final kList = (kundeList != null && kundeList.isNotEmpty) ? kundeList : await _loadKundenList();
    
  if (!context.mounted) return null;

  final newEvent = await showModalBottomSheet<CalendarEvent>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => AddEventDialog(
      betreuerList: bList,
      kundeList: kList,
      initialDate: initialDate ?? DateTime.now(),
      initialType: initialType ?? EventType.survey, 
    ),
  );

  if (newEvent != null) {
    final prefs = await SharedPreferences.getInstance();
      final eJson = prefs.getString(_eventsKey);
      List<CalendarEvent> allEvents = [];
      if (eJson != null && eJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(eJson);
          allEvents = decoded.map((e) => CalendarEvent.fromJson(e)).toList();
        } catch (_) {}
      }

  allEvents.add(newEvent);
  await prefs.setString(
    _eventsKey,
    jsonEncode(allEvents.map((e) => e.toJson()).toList()),
  );
  return newEvent;
  }
  return null;
  }

// Otwarcie dialogu tworzeniu turnusu i automatyczny zapis do bazy po zatwierdzeniu
// [lockedBetreuer] - jeśli podany, formularz blokuje/ustawia tego opiekuna
// [lockedKunde] - jeśli podany, formularz blokuje/ustawia tego klienta
// Zwraca utworzony [Turnus] w razie sukcesu lub 'null', gdy anulowano
  static Future<Turnus?> planAndSaveTurnus({
    required BuildContext context,
    Betreuer? lockedBetreuer,
    Kunde? lockedKunde,
    DateTime? initialDate,
  }) async {
    final kundenList = lockedKunde != null ? [lockedKunde] : await _loadKundenList();
    final betreuerList = lockedBetreuer != null ? [lockedBetreuer] : await _loadBetreuerList();

    if (!context.mounted) return null;

    if (kundenList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baza podopiecznych jest pusta.')),
      );
      return null;
    }

    if (betreuerList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Baza opiekunek jest pusta.')),
      );
      return null;
    }

  // Otwarcie arkusza dialogu
    final newTurnus = await showModalBottomSheet<Turnus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddTurnusDialog(
        betreuerList: betreuerList, 
        kundeList: kundenList,
        initialDate: initialDate ?? DateTime.now(),
      ),
    );

    if (newTurnus != null) {
      final allTurnusy = await _loadAllTurnusy();
      allTurnusy.add(newTurnus);
      await _saveTurnusList(allTurnusy);
      return newTurnus;
    }
    return null;
  }

  static Future<Turnus?> editAndSaveTurnus({
    required BuildContext context,
    required Turnus turnusToEdit,
    List<Betreuer>? betreuerList,
    List<Kunde>? kundeList,
  }) async {
    final bList = (betreuerList != null && betreuerList.isNotEmpty) ? betreuerList : await _loadBetreuerList();
    final kList = (kundeList != null && kundeList.isNotEmpty) ? kundeList : await _loadKundenList();

    if (!context.mounted) return null;

    final updatedTurnus = await showModalBottomSheet<Turnus>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddTurnusDialog(
        betreuerList: bList,
        kundeList: kList,
        turnusToEdit: turnusToEdit,
      ),
    );

    if (updatedTurnus != null) {
      final allTurnusy = await _loadAllTurnusy();
      final idx = allTurnusy.indexWhere((t) => t.id == updatedTurnus.id);
      if (idx != -1) {
        allTurnusy[idx] = updatedTurnus;
        await _saveTurnusList(allTurnusy);
        return updatedTurnus;
      }
    }
    return null;
  }
  static Future<bool> confirmAndDeleteTurnus({
    required BuildContext context,
    required Turnus turnus,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń zaplanowany wyjazd'),
        content: Text(
          'Czy na pewno chcesz usunąć wyjazd opiekuna ${turnus.betreuerName} u klienta ${turnus.kundeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final allTurnusy = await _loadAllTurnusy();
      allTurnusy.removeWhere((t) => t.id == turnus.id);
      await _saveTurnusList(allTurnusy);
      return true;
    }
    return false;
  }
}