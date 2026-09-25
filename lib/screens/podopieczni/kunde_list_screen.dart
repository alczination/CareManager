import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/pdf_service.dart';
import '../../models/kunde.dart';
import '../../screens/podopieczni/kunde_edit_screen.dart';
import '../../screens/podopieczni/kunde_detail_screen.dart';

enum SortOption { none, nameAsc, nameDesc, ageAsc, ageDesc }

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

  SortOption _currentSort = SortOption.none;
  bool _isLoading = true;

  List<Kunde> _kundenListe = [];
  static const String _storageKey = 'kunden_database_v1';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        final loaded = decoded.map((item) => Kunde.fromJson(item as Map<String, dynamic>)).toList();
        if (!mounted) return;
        setState(() {
          _kundenListe = loaded;
          _isLoading = false;
        });
        widget.onListChanged(_kundenListe);
        return;
      } catch (e) {
        debugPrint('Błąd odczytu danych: $e');
      }
    }
    setState(() {
      _kundenListe = [];
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
    } 

    else if (action == 'SHARE') {
      await PdfService.generateKundePdf(context, k);
    } 

    else if (action == 'DELETE') {
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

  List<Kunde> get _filteredKundenListe {
    final list = _kundenListe.where((k) {
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          query.isEmpty ||
          k.vorname.toLowerCase().contains(query) ||
          k.name.toLowerCase().contains(query) ||
          k.anschrift.toLowerCase().contains(query);

      final matchesAvailability = !_onlyAvailable || (k.isAvailable ?? true);
      final matchesPg = _selectedPflegegrad == null || k.pflegegrad == _selectedPflegegrad;

      return matchesSearch &&
          matchesAvailability &&
          matchesPg;
    }).toList();

    switch (_currentSort) {
      case SortOption.nameAsc:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case SortOption.nameDesc:
        list.sort(
          (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
        );
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
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
                              label: const Text('Aktywny'),
                              avatar: Icon(
                                _onlyAvailable
                                    ? Icons.check
                                    : Icons.filter_alt_outlined,
                                size: 16,
                                color: _onlyAvailable
                                    ? Colors.green.shade800
                                    : Colors.grey.shade700,
                              ),
                              selected: _onlyAvailable,
                              selectedColor: Colors.green.shade100,
                              checkmarkColor: Colors.green.shade800,
                              onSelected: (selected) =>
                                  setState(() => _onlyAvailable = selected),
                            ),
                            const SizedBox(width: 8),
                             FilterChip(
                              label: const Text('Wszyscy PG'),
                              selected: _selectedPflegegrad == null,
                              selectedColor: Colors.deepPurple.shade100,
                              onSelected: (_) => setState(() => _selectedPflegegrad == null),
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
                            // FilterChip(
                            //   label: const Text('Pflegedienst'),
                            //   avatar: const Icon(Icons.local_hospital_outlined, size: 16),
                            //   selected: _onlyPflegedienst,
                            //   selectedColor: Colors.deepPurple.shade100,
                            //   checkmarkColor: Colors.deepPurple.shade800,
                            //   onSelected: (val) { setState(() => _onlyPflegedienst = val);
                            //   }
                            // ),
                          ],
                        ),
                      ),
                            const SizedBox(width: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Wyniki: ${displayList.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
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
                              Icon(
                                Icons.person_search,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Brak wyników dla podanych kryteriów',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) =>
                              _buildKundeCard(displayList[index]),
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

  Widget _buildKundeCard(Kunde k) {
    final imageProvider = _getAvatarImage(k.profileImageUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.push<dynamic>(
              context,
              MaterialPageRoute(
                builder: (_) => KundeDetailScreen(kunde: k), 
              ),
            );
            if (result == 'DELETE') {
              setState(
                () => _kundenListe.removeWhere((item) => item.id == k.id),
              );
              _saveData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil został usunięty')),
                );
              }
            } else if (result is Kunde) {
              setState(() {
                final index = _kundenListe.indexWhere((item) => item.id == result.id,
                );
                if (index != -1) _kundenListe[index] = result;
              });
              _saveData();
            }
          },
          onLongPress: () => _showQuickActions(k),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${k.vorname} ${k.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        k.anschrift.isNotEmpty ? k.anschrift : 'Brak adresu',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (k.pflegegrad != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.deepPurple.shade100),
                              ),
                              child: Text(
                                'PG ${k.pflegegrad}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                              ),
                            ),
                          _buildStatusBadge(k.isAvailable ?? true, k.geschlecht),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.deepPurple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable, String geschlecht) {
    final color = isAvailable ? Colors.green : Colors.redAccent;
    final isMale = geschlecht.toLowerCase().startsWith('m');
    final text = isAvailable 
          ? (isMale ? 'Aktywny' : 'Aktywna')
          : (isMale ? 'Wstrzymany' : 'Wstrzymana');

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
