import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pdf_service.dart';
import '../../models/kunde.dart';
import '../../models/turnus.dart';
import '../../screens/podopieczni/kunde_edit_screen.dart';
import '../../screens/podopieczni/kunde_detail_screen.dart';

enum SortOption { none, nameAsc, nameDesc, ageAsc, ageDesc, bedarfSoonest, bedarfFurthest }

class KundenListScreen extends StatefulWidget {
  final List<Kunde> kundenList;
  final ValueChanged<List<Kunde>> onListChanged;
  const KundenListScreen({
    super.key,
    required this.kundenList,
    required this.onListChanged,
  });

  @override
  State<KundenListScreen> createState() => _KundenListScreenState();
}

class _KundenListScreenState extends State<KundenListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _onlyAvailable = false;
  int? _selectedPflegegrad;
  bool _onlyUrgentBedarf = false;

  SortOption _currentSort = SortOption.none;
  bool _isLoading = true;

  List<Kunde> _kundenListe = [];
  List<Turnus> _turnusListe = [];
  static const String _storageKey = 'kunden_database_v1';
  static const String _turnusStorageKey = 'turnus_database_v1';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    List<Kunde> loadedKunden = [];
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        loadedKunden = decoded.map((item) => Kunde.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Błąd odczytu podopiecznych: $e');
      }
    }

    final String? turnusJson = prefs.getString(_turnusStorageKey);
    List<Turnus> loadedTurnusy = [];
    if (turnusJson != null && turnusJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(turnusJson);
        loadedTurnusy = decoded.map((item) => Turnus.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Błąd odczytu turnusów w liście podopiecznych: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _kundenListe = loadedKunden;
      _turnusListe = loadedTurnusy;
      _isLoading = false;
    });
    widget.onListChanged(_kundenListe);
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _kundenListe.map((k) => k.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> _showQuickActions(Kunde k) async {
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
                '${k.vorname} ${k.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                k.pflegegrad != null ? 'Pflegegrad ${k.pflegegrad}' : 'Brak stopnia opieki',
              ),
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
        MaterialPageRoute(builder: (_) => KundeEditScreen(kunde: k)),
      );

      if (updated == 'DELETE') {
        setState(() => _kundenListe.removeWhere((item) => item.id == k.id));
        _saveData();
      } else if (updated is Kunde) {
        setState(() {
          final idx = _kundenListe.indexWhere((item) => item.id == updated.id);
          if (idx != -1) _kundenListe[idx] = updated;
        });
        _saveData();
      }
    } else if (action == 'SHARE') {
      await PdfService.generateKundePdf(context, k);
    } else if (action == 'DELETE') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usuń profil'),
          content: Text('Czy na pewno chcesz usunąć profil ${k.vorname} ${k.name}?'),
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
        setState(() => _kundenListe.removeWhere((item) => item.id == k.id));
        _saveData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usunięto ${k.vorname} ${k.name}')),
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

  DateTime? _parseBedarfDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final clean = dateStr.trim().toLowerCase();
    if (clean.contains('zaraz') || clean.contains('teraz')) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    try {
      final normalized = clean.replaceAll('-', '.').replaceAll('/', '.');
      final parts = normalized.split('.');
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

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
  }

  List<Kunde> get _filteredKundenListe {
    final now = DateTime.now();
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
    final list = _kundenListe.where((k) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          k.vorname.toLowerCase().contains(query) ||
          k.name.toLowerCase().contains(query) ||
          k.anschrift.toLowerCase().contains(query);

      final matchesAvailability = !_onlyAvailable || (k.isAvailable ?? true);
      final matchesPg = _selectedPflegegrad == null || k.pflegegrad == _selectedPflegegrad;
      bool matchesUrgent = true;
      if (_onlyUrgentBedarf) {
        final bedarfRaw = (k.datumBedarf ?? '').trim().toLowerCase();
        final isImmediate = bedarfRaw.isEmpty || bedarfRaw.contains('zaraz') || bedarfRaw.contains('teraz');
        if (isImmediate) {
          matchesUrgent = (k.isAvailable ?? true);
        } else {
          final bedarfDate = _parseBedarfDate(k.datumBedarf);
          matchesUrgent = bedarfDate != null && bedarfDate.isBefore(startOfNextMonth);
        }
      }
      return matchesSearch && matchesAvailability && matchesPg && matchesUrgent;
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
      case SortOption.bedarfSoonest:
        list.sort((a, b) {
          final dateA = _parseBedarfDate(a.datumBedarf);
          final dateB = _parseBedarfDate(b.datumBedarf);
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB); 
        });
        break;
      case SortOption.bedarfFurthest:
        list.sort((a, b) {
          final dateA = _parseBedarfDate(a.datumBedarf);
          final dateB = _parseBedarfDate(b.datumBedarf);
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
    final purpleTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F5FA),
    );

    final displayList = _filteredKundenListe;

    return Theme(
      data: purpleTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baza Podopiecznych'),
          backgroundColor: purpleTheme.colorScheme.primaryContainer,
          foregroundColor: purpleTheme.colorScheme.onPrimaryContainer,
          actions: [
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
                  value: SortOption.bedarfSoonest,
                  child: Row(
                    children: [
                      Icon(Icons.child_care, size: 20),
                      SizedBox(width: 10),
                      Text('Potrzeba opieki: najszybciej'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortOption.bedarfFurthest,
                  child: Row(
                    children: [
                      Icon(Icons.elderly, size: 20),
                      SizedBox(width: 10),
                      Text('Potrzeba opieki: najdalej'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                                label: const Text('Od zaraz / Ten miesiąc'),
                                avatar: Icon(
                                  _onlyUrgentBedarf ? Icons.bolt : Icons.flash_on_outlined,
                                  size: 16,
                                  color: _onlyUrgentBedarf ? Colors.amber.shade900 : Colors.deepOrange,
                                ),
                                selected: _onlyUrgentBedarf,
                                selectedColor: Colors.amber.shade100,
                                checkmarkColor: Colors.amber.shade900,
                                side: BorderSide(
                                  color: _onlyUrgentBedarf ? Colors.amber.shade400 : Colors.grey.shade300,
                                ),
                                onSelected: (selected) => setState(() => _onlyUrgentBedarf = selected),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Wszyscy PG'),
                                selected: _selectedPflegegrad == null,
                                selectedColor: Colors.deepPurple.shade100,
                                onSelected: (_) => setState(() => _selectedPflegegrad = null),
                              ),
                              const SizedBox(width: 8),
                              ...[1, 2, 3, 4, 5].map((pg) {
                                final isSelected = _selectedPflegegrad == pg;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text('PG $pg'),
                                    selected: isSelected,
                                    selectedColor: Colors.deepPurple.shade100,
                                    checkmarkColor: Colors.deepPurple.shade800,
                                    onSelected: (val) {
                                      setState(() => _selectedPflegegrad = val ? pg : null);
                                    },
                                  ),
                                );
                              }),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: displayList.length,
                            itemBuilder: (context, index) => _buildKundeCard(displayList[index]),
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_kunden_list',
          backgroundColor: purpleTheme.colorScheme.primary,
          foregroundColor: Colors.white,
          tooltip: 'Dodaj podopiecznego',
          onPressed: () async {
            final newKunde = await Navigator.push<Kunde>(
              context,
              MaterialPageRoute(builder: (context) => const KundeEditScreen()),
            );
            if (newKunde != null) {
              setState(() => _kundenListe.add(newKunde));
              _saveData();
              widget.onListChanged(_kundenListe);
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

  Widget _buildAvatarWidget(Kunde k) {
    final hasSecondPerson = k.betreuungZweiPersonen &&
        ((k.zweitePersonVorname?.isNotEmpty ?? false) || (k.zweitePersonName?.isNotEmpty ?? false));

    if (hasSecondPerson) {
      final p1Initials = '${k.vorname.isNotEmpty ? k.vorname[0] : ""}${k.name.isNotEmpty ? k.name[0] : ""}';
      final p2Initials = '${k.zweitePersonVorname?.isNotEmpty == true ? k.zweitePersonVorname![0] : ""}${k.zweitePersonName?.isNotEmpty == true ? k.zweitePersonName![0] : ""}';

      return SizedBox(
        width: 68,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 20,
              top: 4,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.purple.shade200,
                child: Text(
                  p2Initials.isNotEmpty ? p2Initials : '2P',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.deepPurple.shade100,
                  backgroundImage: _getAvatarImage(k.profileImageUrl),
                  child: k.profileImageUrl == null || k.profileImageUrl!.isEmpty
                      ? Text(
                          p1Initials,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade900,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final imageProvider = _getAvatarImage(k.profileImageUrl);
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.deepPurple.shade50,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              '${k.vorname.isNotEmpty ? k.vorname[0] : ""}${k.name.isNotEmpty ? k.name[0] : ""}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            )
          : null,
    );
  }

  Widget _buildKundeCard(Kunde k) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final activeTurnus = _turnusListe.cast<Turnus?>().firstWhere(
      (t) =>
          t != null &&
          (t.kundeId == k.id || t.kundeName.trim().toLowerCase() == '${k.vorname} ${k.name}'.trim().toLowerCase()) &&
          !today.isBefore(t.startDate) &&
          !today.isAfter(t.endDate),
      orElse: () => null,
    );

    int? daysLeft;
    if (activeTurnus != null) {
      daysLeft = activeTurnus.endDate.difference(today).inDays;
    }

    final hasSecondPerson = k.betreuungZweiPersonen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (daysLeft != null && daysLeft <= 10)
              ? Colors.amber.shade400
              : (activeTurnus != null ? Colors.green.shade200 : Colors.grey.shade200),
          width: (daysLeft != null && daysLeft <= 10) ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            final result = await Navigator.push<dynamic>(
              context,
              MaterialPageRoute(builder: (_) => KundeDetailScreen(kunde: k)),
            );
            if (result == 'DELETE') {
              setState(() => _kundenListe.removeWhere((item) => item.id == k.id));
              _saveData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil został usunięty')),
                );
              }
            } else if (result is Kunde) {
              setState(() {
                final index = _kundenListe.indexWhere((item) => item.id == result.id);
                if (index != -1) _kundenListe[index] = result;
              });
              _saveData();
              widget.onListChanged(_kundenListe);
            }
          },
          onLongPress: () => _showQuickActions(k),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarWidget(k),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hasSecondPerson && (k.zweitePersonVorname?.isNotEmpty ?? false)
                                      ? '${k.vorname} ${k.name} & ${k.zweitePersonVorname}'
                                      : '${k.vorname} ${k.name}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (k.tagessatz != null)
                                Text(
                                  '${k.tagessatz} €/dzień',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            k.anschrift.isNotEmpty ? k.anschrift : 'Brak adresu',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (k.pflegegrad != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.deepPurple.shade100),
                                  ),
                                  child: Text(
                                    'PG ${k.pflegegrad}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple.shade800,
                                    ),
                                  ),
                                ),
                              if (hasSecondPerson)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.purple.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people, size: 12, color: Colors.purple.shade700),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Para / 2 os.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade800,
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
                _buildOperationalStatusRow(k, activeTurnus, daysLeft),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationalStatusRow(Kunde k, Turnus? activeTurnus, int? daysLeft) {
    if (activeTurnus != null) {
      final isEndingSoon = daysLeft != null && daysLeft <= 10;

      return Row(
        children: [
          Icon(
            Icons.person_pin_circle,
            size: 16,
            color: isEndingSoon ? Colors.amber.shade900 : Colors.green.shade700,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Na miejscu: ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                children: [
                  TextSpan(
                    text: activeTurnus.betreuerName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isEndingSoon ? Colors.black87 : Colors.green.shade800,
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
                  Icon(Icons.warning_amber_rounded, size: 13, color: Colors.amber.shade900),
                  const SizedBox(width: 4),
                  Text(
                    daysLeft == 0 ? 'Koniec dzisiaj!' : 'Zmiana za $daysLeft dni (${_formatDate(activeTurnus.endDate)})',
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
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
        ],
      );
    }

    final isAvailable = k.isAvailable ?? true;
    final bedarfStr = k.datumBedarf;

    return Row(
      children: [
        Icon(
          isAvailable ? Icons.event_busy_outlined : Icons.pause_circle_outline,
          size: 16,
          color: isAvailable ? Colors.red.shade600 : Colors.grey,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            isAvailable
                ? (bedarfStr != null && bedarfStr.isNotEmpty
                    ? 'Wakat • Wymaga opieki od: $bedarfStr'
                    : 'Brak obsady • Wymaga opieki od zaraz')
                : 'Zlecenie wstrzymane / nieaktywne',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isAvailable ? FontWeight.w600 : FontWeight.normal,
              color: isAvailable ? Colors.red.shade800 : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.red.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isAvailable ? 'PILNE' : 'PAUZA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAvailable ? Colors.red.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}