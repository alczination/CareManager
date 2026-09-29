import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pers_ver_app/screens/opiekunki/betreuer_invoices_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pdf_service.dart';
import '../../models/betreuer.dart';
import '../../models/turnus.dart';
import 'betreuer_detail_screen.dart';
import 'betreuer_edit_screen.dart';

enum SortOption { none, nameAsc, nameDesc, ageAsc, ageDesc, availableSoon, availableFurther }

class BetreuerListScreen extends StatefulWidget {
  final List<Betreuer> betreuerList;
  final ValueChanged<List<Betreuer>> onDataChanged;

  const BetreuerListScreen({
    super.key,
    required this.betreuerList,
    required this.onDataChanged,
  });

  @override
  State<BetreuerListScreen> createState() => _BetreuerListScreenState();
}

class _BetreuerListScreenState extends State<BetreuerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyAvailable = false;
  bool _onlyGerman = false;
  bool _onlyDrivingLicense = false;
  bool _onlyMedicalExperience = false;
  bool _onlyNonSmoker = false;
  SortOption _currentSort = SortOption.none;
  bool _isLoading = true;

  List<Betreuer> _betreuerListe = [];
  List<Turnus> _turnusListe = [];

  static const String _storageKey = 'betreuer_database_v1';
  static const String _turnusStorageKey = 'turnus_database_v1';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant BetreuerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betreuerList != widget.betreuerList) {
      setState(() {
        _betreuerListe = List.from(widget.betreuerList);
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final String? jsonString = prefs.getString(_storageKey);
    List<Betreuer> loadedBetreuer = [];
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        loadedBetreuer = decoded
            .map((item) => Betreuer.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Błąd odczytu bazy opiekunek: $e');
      }
    }

    final String? turnusJson = prefs.getString(_turnusStorageKey);
    List<Turnus> loadedTurnusy = [];
    if (turnusJson != null && turnusJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(turnusJson);
        loadedTurnusy = decoded
            .map((item) => Turnus.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Błąd odczytu turnusów w liście opiekunek: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _betreuerListe = loadedBetreuer.isNotEmpty
          ? loadedBetreuer
          : List.from(widget.betreuerList);
      _turnusListe = loadedTurnusy;
      _isLoading = false;
    });
    widget.onDataChanged(_betreuerListe);
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _betreuerListe.map((b) => b.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      widget.onDataChanged(_betreuerListe);
    } catch (e) {
      debugPrint('Błąd zapisu bazy opiekunek: $e');
    }
  }

  Future<void> _showQuickActions(Betreuer b) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${b.vorname} ${b.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Wybierz akcję'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edytuj profil', style: TextStyle(color: Colors.black)),
              onTap: () => Navigator.pop(ctx, 'EDIT'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Eksportuj do PDF', style: TextStyle(color: Colors.black)),
              onTap: () => Navigator.pop(ctx, 'SHARE'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Wystaw rachunek', style: TextStyle(color: Colors.black)),
              onTap: () => Navigator.pop(ctx, 'INVOICE'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Usuń profil', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'DELETE'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'EDIT') {
      final updated = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute(builder: (_) => BetreuerEditScreen(betreuer: b)),
      );

      if (updated == 'DELETE') {
        setState(() => _betreuerListe.removeWhere((item) => item.id == b.id));
        await _saveData();
      } else if (updated is Betreuer) {
        setState(() {
          final idx = _betreuerListe.indexWhere((item) => item.id == updated.id);
          if (idx != -1) _betreuerListe[idx] = updated;
        });
        await _saveData();
      }
    } else if (action == 'SHARE') {
      await PdfService.showPdfOptionsAndGenerate(context, b);
    } else if (action == 'INVOICE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BetreuerInvoicesScreen(betreuer: b),
        ),
      );
    } else if (action == 'DELETE') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usuń profil'),
          content: Text('Czy na pewno chcesz usunąć profil ${b.vorname} ${b.name}?'),
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
        setState(() => _betreuerListe.removeWhere((item) => item.id == b.id));
        await _saveData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usunięto ${b.vorname} ${b.name}')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _parseBirthDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final clean = dateStr.replaceAll('-', '.');
      final parts = clean.split('.');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  DateTime? _getEffectiveAvailabilityDate(Betreuer b) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final activeTurnus = _turnusListe.cast<Turnus?>().firstWhere(
      (t) => t != null && (t.betreuerId == b.id ||
       t.betreuerName.trim().toLowerCase() == '${b.vorname} ${b.name}'.trim().toLowerCase()) &&
        !today.isBefore(t.startDate) &&
        !today.isAfter(t.endDate),
      orElse: () => null,
    );

  if (activeTurnus != null) {
    return activeTurnus.endDate;
  }

  if (b.isAvailable == false) {
    return null;
  }

  final rawDate = (b.datumVerfuegbarkeit ?? '').trim().toLowerCase();
  if (rawDate.isEmpty ||  rawDate.contains('zaraz') || rawDate.contains('teraz')) {
    return today;
  }

  try {
    final clean = rawDate.replaceAll('-', '.').replaceAll('/', '.');
    final parts = clean.split('.');
    if (parts.length >= 2) {
      final d = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final y = parts.length == 3 ? int.parse(parts[2]) : now.year;
      return DateTime(y, m, d);
    }
  } catch (_) {}
    return today;
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  bool _isBetreuerCurrentlyOnAssignment(Betreuer b) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return _turnusListe.any((t) {
      final matchesPerson = t.betreuerId == b.id || t.betreuerName.trim().toLowerCase() == '${b.vorname} ${b.name}'.trim().toLowerCase();
      final isOngoing = !today.isBefore(t.startDate) && !today.isAfter(t.endDate);
      return matchesPerson && isOngoing;
    });
  }

  List<Betreuer> get _filteredBetreuerListe {
    final list = _betreuerListe.where((b) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          b.vorname.toLowerCase().contains(query) ||
          b.name.toLowerCase().contains(query) ||
          b.anschrift.toLowerCase().contains(query);

      final isOnAssignment = _isBetreuerCurrentlyOnAssignment(b);
      final isTrulyAvailable = (b.isAvailable ?? true) && !isOnAssignment;
      final matchesAvailability = !_onlyAvailable || isTrulyAvailable;
      final level = (b.deutschKenntnisse ?? '').toLowerCase().trim();
      final hasGerman = level.isNotEmpty && level != 'brak' && level != 'keine';
      final matchesGerman = !_onlyGerman || hasGerman;
      final matchesLicense = !_onlyDrivingLicense || b.fuehrerschein;
      final matchesSmoker = !_onlyNonSmoker || !b.raucher;
      final matchesMedicalExperience =
          !_onlyMedicalExperience || b.medizinischeErfahrung;
      return matchesSearch &&
          matchesAvailability &&
          matchesGerman &&
          matchesLicense &&
          matchesSmoker &&
          matchesMedicalExperience;
    }).toList();

    switch (_currentSort) {
      case SortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortOption.ageAsc:
        list.sort((a, b) {
          final dateA = _parseBirthDate(a.geburtsdatum);
          final dateB = _parseBirthDate(b.geburtsdatum);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
        break;
      case SortOption.ageDesc:
        list.sort((a, b) {
          final dateA = _parseBirthDate(a.geburtsdatum);
          final dateB = _parseBirthDate(b.geburtsdatum);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;
      case SortOption.availableSoon:
        list.sort((a, b) {
          final dateA = _getEffectiveAvailabilityDate(a);
          final dateB = _getEffectiveAvailabilityDate(b);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;
      case SortOption.availableFurther:
        list.sort((a, b) {
          final dateA = _getEffectiveAvailabilityDate(a);
          final dateB = _getEffectiveAvailabilityDate(b);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
        break;
      case SortOption.none:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final blueTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FB),
    );

    final displayList = _filteredBetreuerListe;

    return Theme(
      data: blueTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baza Opiekunek'),
          backgroundColor: blueTheme.colorScheme.primaryContainer,
          foregroundColor: blueTheme.colorScheme.onPrimaryContainer,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Odśwież statusy i turnusy',
              onPressed: () async {
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Zaktualizowano statusy wyjazdów opiekunek'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            PopupMenuButton<SortOption>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sortuj listę',
              initialValue: _currentSort,
              onSelected: (option) => setState(() => _currentSort = option),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: SortOption.none,
                  child: Row(
                    children: [
                      Icon(Icons.restart_alt, size: 20),
                      SizedBox(width: 10),
                      Text('Domyślnie'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: SortOption.nameAsc,
                  child: Row(
                    children: [
                      Icon(Icons.text_rotate_vertical, size: 20),
                      SizedBox(width: 10),
                      Text('Nazwisko (A - Z)'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortOption.nameDesc,
                  child: Row(
                    children: [
                      Icon(Icons.text_rotation_down, size: 20),
                      SizedBox(width: 10),
                      Text('Nazwisko (Z - A)'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: SortOption.ageAsc,
                  child: Row(
                    children: [
                      Icon(Icons.child_care, size: 20),
                      SizedBox(width: 10),
                      Text('Wiek: najpierw najmłodsi'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortOption.ageDesc,
                  child: Row(
                    children: [
                      Icon(Icons.elderly, size: 20),
                      SizedBox(width: 10),
                      Text('Wiek: najstarsi najpierw'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: SortOption.availableSoon,
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 20, color: Color.fromARGB(255, 239, 108, 0)),
                      const SizedBox(width: 10),
                      const Text('Dostępność: najszybciej'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortOption.availableFurther,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, size: 20, color: Color.fromRGBO(25, 118, 210, 1)),
                      const SizedBox(width: 10),
                      const Text('Dostępność: najpóźniej'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: Colors.blueAccent,
                onRefresh: _loadData,
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Szukaj po imieniu, nazwisku, mieście...',
                              prefixIcon: const Icon(Icons.search, size: 22),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: const Text('Dostępny'),
                                  avatar: Icon(
                                    _onlyAvailable ? Icons.check : Icons.filter_alt_outlined,
                                    size: 16,
                                    color: _onlyAvailable ? Colors.green.shade800 : Colors.grey.shade700,
                                  ),
                                  selected: _onlyAvailable,
                                  selectedColor: Colors.green.shade100,
                                  checkmarkColor: Colors.green.shade800,
                                  onSelected: (selected) => setState(() => _onlyAvailable = selected),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Niemiecki'),
                                  avatar: Icon(
                                    _onlyGerman ? Icons.check : Icons.language,
                                    size: 16,
                                    color: _onlyGerman ? Colors.blue.shade800 : Colors.grey.shade700,
                                  ),
                                  selected: _onlyGerman,
                                  selectedColor: Colors.blue.shade100,
                                  checkmarkColor: Colors.blue.shade800,
                                  onSelected: (selected) => setState(() => _onlyGerman = selected),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Prawo jazdy'),
                                  avatar: Icon(
                                    _onlyDrivingLicense ? Icons.check : Icons.directions_car,
                                    size: 16,
                                    color: _onlyDrivingLicense ? Colors.orange.shade800 : Colors.grey.shade700,
                                  ),
                                  selected: _onlyDrivingLicense,
                                  selectedColor: Colors.teal.shade100,
                                  checkmarkColor: Colors.teal.shade800,
                                  onSelected: (selected) => setState(
                                    () => _onlyDrivingLicense = selected,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Niepalący'),
                                  avatar: Icon(
                                    _onlyNonSmoker ? Icons.check : Icons.smoke_free,
                                    size: 16,
                                    color: _onlyNonSmoker ? Colors.teal.shade800 : Colors.grey.shade700,
                                  ),
                                  selected: _onlyNonSmoker,
                                  selectedColor: Colors.teal.shade100,
                                  checkmarkColor: Colors.teal.shade800,
                                  onSelected: (selected) => setState(() => _onlyNonSmoker = selected),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Medyczne doś.'),
                                  avatar: Icon(
                                    _onlyMedicalExperience ? Icons.check : Icons.medical_services_outlined,
                                    size: 16,
                                    color: _onlyMedicalExperience ? Colors.orange.shade800 : Colors.grey.shade700,
                                  ),
                                  selected: _onlyMedicalExperience,
                                  selectedColor: Colors.teal.shade100,
                                  checkmarkColor: Colors.teal.shade800,
                                  onSelected: (selected) => setState(
                                    () => _onlyMedicalExperience = selected,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Wyniki: ${displayList.length}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: displayList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Brak wyników dla podanych kryteriów',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) => _buildBetreuerCard(displayList[index]),
                            ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_betreuer',
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          tooltip: 'Dodaj opiekunkę',
          onPressed: () async {
            final newBetreuer = await Navigator.push<Betreuer>(
              context,
              MaterialPageRoute(builder: (context) => const BetreuerEditScreen()),
            );
            if (newBetreuer != null) {
              setState(() => _betreuerListe.add(newBetreuer));
              await _saveData();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (!kIsWeb) {
      return FileImage(File(path));
    }
    return NetworkImage(path);
  }

  Widget _buildBetreuerCard(Betreuer b) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final activeTurnus = _turnusListe.cast<Turnus?>().firstWhere(
      (t) =>
          t != null &&
          (t.betreuerId == b.id ||
              t.betreuerName.trim().toLowerCase() ==
                  '${b.vorname} ${b.name}'.trim().toLowerCase()) &&
          !today.isBefore(t.startDate) &&
          !today.isAfter(t.endDate),
      orElse: () => null,
    );

    int? daysLeft;
    if (activeTurnus != null) {
      daysLeft = activeTurnus.endDate.difference(today).inDays;
    }
    final isOnAssignment = activeTurnus != null;
    final isEndingSoon = daysLeft != null && daysLeft <= 10;
    final imageProvider = _getAvatarImage(b.profileImageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEndingSoon
              ? Colors.amber.shade400
              : (isOnAssignment ? Colors.blue.shade200 : Colors.green.shade200),
          width: isEndingSoon ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BetreuerDetailScreen(betreuer: b),
              ),
            );

            if (result == 'DELETE') {
              setState(() => _betreuerListe.removeWhere((item) => item.id == b.id));
              await _saveData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil został usunięty')),
                );
              }
            } else if (result is Betreuer) {
              setState(() {
                final index = _betreuerListe.indexWhere((item) => item.id == result.id);
                if (index != -1) _betreuerListe[index] = result;
              });
              await _saveData();
            }
          },
          onLongPress: () => _showQuickActions(b),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? Text(
                              '${b.vorname.isNotEmpty ? b.vorname[0] : ""}${b.name.isNotEmpty ? b.name[0] : ""}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${b.vorname} ${b.name}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.deutschKenntnisse != null && b.deutschKenntnisse!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.teal.shade200),
                                  ),
                                  child: Text(
                                    b.deutschKenntnisse!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            b.anschrift.isNotEmpty ? b.anschrift : 'Brak adresu',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (b.fuehrerschein)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.directions_car, size: 12, color: Colors.blue.shade700),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Prawo jazdy',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
                const Divider(height: 18),
                _buildBetreuerOperationalStatusRow(b, activeTurnus, daysLeft),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBetreuerOperationalStatusRow(Betreuer b, Turnus? activeTurnus, int? daysLeft) {
    if (activeTurnus != null) {
      final isEndingSoon = daysLeft != null && daysLeft <= 10;
      return Row(
        children: [
          Icon(
            Icons.work_outline,
            size: 16,
            color: isEndingSoon ? Colors.amber.shade900 : Colors.blue.shade700,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Na zleceniu u: ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                children: [
                  TextSpan(
                    text: activeTurnus.kundeName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEndingSoon ? Colors.black87 : Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isEndingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flight_takeoff, size: 13, color: Colors.amber.shade900),
                  const SizedBox(width: 4),
                  Text(
                    daysLeft == 0
                        ? 'Zjazd dzisiaj!'
                        : 'Zjazd za $daysLeft dni (${_formatDate(activeTurnus.endDate)})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'do ${_formatDate(activeTurnus.endDate)}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
        ],
      );
    }

    final abWann = b.datumVerfuegbarkeit;
    final hasDate = abWann != null && abWann.isNotEmpty;

    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: Colors.green,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hasDate ? 'Wolny • Dostępny od $abWann' : 'Wolny • Gotowy do wyjazdu od zaraz',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Text(
            'DOSTĘPNY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAvailable, String geschlecht) {
    final color = isAvailable ? Colors.green : Colors.redAccent;
    final isMale = geschlecht.toLowerCase().startsWith('m');
    final text = isAvailable
        ? (isMale ? 'Dostępny' : 'Dostępna')
        : (isMale ? 'Zajęty' : 'Zajęta');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}