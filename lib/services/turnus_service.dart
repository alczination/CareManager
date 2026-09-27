import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/turnus.dart';
import '../models/kunde.dart';
import '../models/betreuer.dart';
import '../screens/kalendarz/add_turnus_dialog.dart';

class TurnusService {
  static const String _turnusKey = 'turnus_database_v1';
  static const String _kundenKey = 'kunden_database_v1';
  static const String _betreuerKey = 'betreuer_database_v1';

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
    final prefs = await SharedPreferences.getInstance();

  // 1. Pobieranie listy podopiecznych
    List<Kunde> kundenList = [];
    if (lockedKunde != null) {
      kundenList = [lockedKunde];
    } else {
      final kJson = prefs.getString(_kundenKey);
      if (kJson != null && kJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(kJson);
          kundenList = decoded.map((e) => Kunde.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Błąd odczytu podopiecznych w TurnusService: $e');
        }
      }
    }
  // 2. Pobieranie listy opiekunek
    List<Betreuer> betreuerList = [];
    if (lockedBetreuer != null) {
      betreuerList = [lockedBetreuer];
    } else {
      final bJson = prefs.getString(_betreuerKey);
      if (bJson != null && bJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(bJson);
          betreuerList = decoded.map((e) => Betreuer.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Błąd odczytu opiekunek w TurnusService: $e');
        }
      }
    }

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

  // Trwały zapis do SharedPreferences
    if (newTurnus != null) {
      final tJson = prefs.getString(_turnusKey);
      List<Turnus> allTurnusy = [];
      if (tJson != null && tJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(tJson);
          allTurnusy = decoded.map((e) => Turnus.fromJson(e)).toList();
        } catch (_) {}
      }
      allTurnusy.add(newTurnus);
      await prefs.setString(
        _turnusKey,
        jsonEncode(allTurnusy.map((t) => t.toJson()).toList()),
      );
      return newTurnus;
    }
    return null;
  }
}