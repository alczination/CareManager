import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/betreuer.dart';
import '../../models/kunde.dart';
import '../../models/turnus.dart';
import '../kalendarz/add_turnus_dialog.dart';

enum TurnusFilter { aktualne, nadchodzace, przeszle, wszystkie }

class TurnusListScreen extends StatefulWidget {
  const TurnusListScreen({super.key});

  @override
  State<TurnusListScreen> createState() => _TurnusListScreenState();
}

class _TurnusListScreenState extends State<TurnusListScreen>
    with SingleTickerProviderStateMixin {
  static const String _turnusStorageKey = 'turnus_database_v1';
  List<Turnus> _turnusList = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTurnusData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTurnusData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_turnusStorageKey);

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final list = decoded.map((e) => Turnus.fromJson(e)).toList();
        list.sort((a, b) => a.startDate.compareTo(b.startDate));

        if (!mounted) return;
        setState(() {
          _turnusList = list;
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('Błąd odczytu zleceń: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _turnusList = [];
      _isLoading = false;
    });
  }

  // Pomocnicza logika statusu
  bool _isOngoing(Turnus t, DateTime today) {
    return !today.isBefore(t.startDate) && !today.isAfter(t.endDate);
  }

  bool _isUpcoming(Turnus t, DateTime today) {
    return today.isBefore(t.startDate);
  }

  bool _isPast(Turnus t, DateTime today) {
    return today.isAfter(t.endDate);
  }

  List<Turnus> _filterTurnusy(TurnusFilter filter) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    switch (filter) {
      case TurnusFilter.aktualne:
        return _turnusList.where((t) => _isOngoing(t, today)).toList();
      case TurnusFilter.nadchodzace:
        return _turnusList.where((t) => _isUpcoming(t, today)).toList();
      case TurnusFilter.przeszle:
        final past = _turnusList.where((t) => _isPast(t, today)).toList();
        past.sort((a, b) => b.endDate.compareTo(a.endDate)); // najnowsze zakończone u góry
        return past;
      case TurnusFilter.wszystkie:
        return _turnusList;
    }
  }

  Future<void> _editTurnus(Turnus t) async {
    final prefs = await SharedPreferences.getInstance();

    List<Betreuer> bList = [];
    final bStr = prefs.getString('betreuer_database_v1');
    if (bStr != null && bStr.isNotEmpty) {
      try {
        final List<dynamic> dec = jsonDecode(bStr);
        bList = dec.map((e) => Betreuer.fromJson(e)).toList();
      } catch (_) {}
    }

    List<Kunde> kList = [];
    final kStr = prefs.getString('kunde_database_v1') ?? prefs.getString('kunden_database_v1');
    if (kStr != null && kStr.isNotEmpty) {
      try {
        final List<dynamic> dec = jsonDecode(kStr);
        kList = dec.map((e) => Kunde.fromJson(e)).toList();
      } catch (_) {}
    }

    if (!mounted) return;

    final updated = await showModalBottomSheet<Turnus>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => AddTurnusDialog(
        betreuerList: bList,
        kundeList: kList,
        turnusToEdit: t,
      ),
    );

    if (updated != null) {
      setState(() {
        final index = _turnusList.indexWhere((item) => item.id == updated.id);
        if (index != -1) {
          _turnusList[index] = updated;
          _turnusList.sort((a, b) => a.startDate.compareTo(b.startDate));
        }
      });
      final jsonList = _turnusList.map((item) => item.toJson()).toList();
      await prefs.setString(_turnusStorageKey, jsonEncode(jsonList));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zaktualizowano dane wyjazdu!'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  Future<void> _deleteTurnus(Turnus t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń zlecenie'),
        content: Text('Czy na pewno chcesz usunąć wyjazd: ${t.betreuerName} ➔ ${t.kundeName}?'),
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
      setState(() {
        _turnusList.removeWhere((item) => item.id == t.id);
      });
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _turnusList.map((item) => item.toJson()).toList();
      await prefs.setString(_turnusStorageKey, jsonEncode(jsonList));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zlecenie zostało usunięte')),
        );
      }
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Widget _buildTurnusList(List<Turnus> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    return RefreshIndicator(
      onRefresh: _loadTurnusData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final turnus = list[index];

          final bool isOngoing = _isOngoing(turnus, today);
          final bool isUpcoming = _isUpcoming(turnus, today);

          Color statusColor;
          String statusText;
          if (isOngoing) {
            statusColor = Colors.green;
            statusText = 'W TRAKCIE';
          } else if (isUpcoming) {
            statusColor = Colors.teal;
            statusText = 'NADCHODZĄCY';
          } else {
            statusColor = Colors.grey;
            statusText = 'ZAKOŃCZONY';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isOngoing ? Colors.green.shade300 : Colors.grey.shade200,
                width: isOngoing ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        child: Icon(Icons.flight_takeoff, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              turnus.betreuerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    turnus.kundeName,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.teal),
                            tooltip: 'Edytuj wyjazd',
                            onPressed: () => _editTurnus(turnus),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'Usuń wyjazd',
                            onPressed: () => _deleteTurnus(turnus),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatDate(turnus.startDate)} – ${_formatDate(turnus.endDate)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Czas trwania: ${turnus.durationInDays} dni',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (turnus.notiz != null && turnus.notiz!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Notatka: ${turnus.notiz}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);

    final aktualne = _turnusList.where((t) => _isOngoing(t, today)).toList();
    final nadchodzace = _turnusList.where((t) => _isUpcoming(t, today)).toList();
    final przeszle = _turnusList.where((t) => _isPast(t, today)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Baza zleceń i dojazdów'),
        backgroundColor: Colors.teal.shade50,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.teal.shade900,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.teal,
          indicatorWeight: 3,
          isScrollable: false,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: [
            Tab(text: 'Aktualne (${aktualne.length})'),
            Tab(text: 'Nadchodzące (${nadchodzace.length})'),
            Tab(text: 'Przeszłe (${przeszle.length})'),
            Tab(text: 'Wszystkie (${_turnusList.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTurnusList(aktualne, 'Brak aktywnych wyjazdów w tym momencie'),
                _buildTurnusList(nadchodzace, 'Brak zaplanowanych nadchodzących wyjazdów'),
                _buildTurnusList(przeszle, 'Brak zakończonych wyjazdów w historii'),
                _buildTurnusList(_turnusList, 'Brak jakichkolwiek zarejestrowanych wyjazdów'),
              ],
            ),
    );
  }
}