import 'package:flutter/material.dart';
import '../../models/betreuer.dart';

class BetreuerEditScreen extends StatefulWidget {
  final Betreuer? betreuer;

  const BetreuerEditScreen({super.key, this.betreuer});

  @override
  State<BetreuerEditScreen> createState() => _BetreuerEditScreenState();
}

class _BetreuerEditScreenState extends State<BetreuerEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vornameController;
  late TextEditingController _nameController;
  late TextEditingController _anschriftController;
  late TextEditingController _geburtsdatumController;
  late TextEditingController _geburtsortController;
  late TextEditingController _groesseController;
  late TextEditingController _gewichtController;
  late TextEditingController _emailController;
  late TextEditingController _profileImageUrlController;
  late TextEditingController _telNrController;
  late TextEditingController _notizenController;
  late TextEditingController _beruflicheErfahrungController;
  late TextEditingController _datumVerfuegbarkeitController;
  late TextEditingController _vornameAnsprechpersonController;
  late TextEditingController _nachnameAnsprechpersonController;
  late TextEditingController _anschriftAnsprechpersonController;
  late TextEditingController _telNrAnsprechpersonController;
  final TextEditingController _customSpracheController = TextEditingController();
  final TextEditingController _customAllergieController = TextEditingController();
  final TextEditingController _customKrankheitController = TextEditingController();
  final TextEditingController _customMedikamentController = TextEditingController();
  final TextEditingController _customHobbyController = TextEditingController();
  final TextEditingController _customAusbildungController = TextEditingController();
  final TextEditingController _alterKindController = TextEditingController();

  String _geschlecht = 'Kobieta';
  String _familienstand = 'Panna / Kawaler';
  String _deutschKenntnisse = 'Komunikatywna';
  String _betreuungGeschlecht = 'Obojętnie';
  String _bezugAnsprechperson = 'Syn / Córka';
  String _nationalitat = 'Polska';
  String _religion = 'Katolicyzm';

  bool _isAvailable = true;
  bool _fuehrerschein = false;
  bool _bereitFuehrerschein = false;
  bool _hasKinder = false;
  bool _raucher = false;
  bool _gartenArbeiten = false;
  bool _betreuungZweiPersonen = false;
  bool _medizinischeErfahrung = false;
  bool _betreuungHaustiere = false;

  late List<String> _selectedAndereSprachen;
  late List<String> _selectedAllergien;
  late List<String> _selectedKrankheiten;
  late List<String> _selectedMedikamenten;
  late List<String> _selectedVersicherung;
  late List<String> _selectedBetreuungsZyklen;
  late List<String> _kinder;
  String _geschlechtKind = 'Syn';
  late List<String> _selectedHobbys;
  late List<String> _selectedAusbildung;

  bool get _isEditing => widget.betreuer != null;

  @override
  void initState() {
    super.initState();
    final b = widget.betreuer;

    _vornameController = TextEditingController(text: b?.vorname ?? '');
    _nameController = TextEditingController(text: b?.name ?? '');
    _anschriftController = TextEditingController(text: b?.anschrift ?? '');
    _groesseController = TextEditingController(text: b?.groesse != null ? b!.groesse.toString() : '');
    _gewichtController = TextEditingController(text: b?.gewicht != null ? b!.gewicht.toString() : '');
    _geburtsdatumController = TextEditingController(text: b?.geburtsdatum ?? '');
    _geburtsortController = TextEditingController(text: b?.geburtsort ?? '');
    _emailController = TextEditingController(text: b?.email ?? '');
    _profileImageUrlController = TextEditingController(text: b?.profileImageUrl ?? '');
    _telNrController = TextEditingController(text: b?.telNr ?? '');
    _notizenController = TextEditingController(text: b?.notizen ?? '');
    _beruflicheErfahrungController = TextEditingController(text: b?.beruflicheErfahrung ?? '');
    _datumVerfuegbarkeitController = TextEditingController(text: b?.datumVerfuegbarkeit ?? '');
    _vornameAnsprechpersonController = TextEditingController(text: b?.vornameAnsprechperson ?? '');
    _nachnameAnsprechpersonController = TextEditingController(text: b?.nachnameAnsprechperson ?? '');
    _anschriftAnsprechpersonController = TextEditingController(text: b?.anschriftAnsprechperson ?? '');
    _telNrAnsprechpersonController = TextEditingController(text: b?.telNrAnsprechperson ?? '');

    _familienstand = b?.familienstand ?? 'Panna / Kawaler';
    _geschlecht = b?.geschlecht ?? 'Kobieta';
    _deutschKenntnisse = b?.deutschKenntnisse ?? 'Komunikatywna';
    _betreuungGeschlecht = b?.betreuungGeschlecht ?? 'Obojętnie';
    _bezugAnsprechperson = b?.bezugAnsprechperson ?? 'Syn / Córka';
    _isAvailable = b?.isAvailable ?? true;
    _hasKinder = b?.hasKinder ?? false;
    _kinder = List<String>.from(b?.kinder ?? []);
    _fuehrerschein = b?.fuehrerschein ?? false;
    _bereitFuehrerschein = b?.bereitFuehrerschein ?? false;
    _gartenArbeiten = b?.gartenArbeiten ?? false;
    _medizinischeErfahrung = b?.medizinischeErfahrung ?? false;
    _betreuungZweiPersonen = b?.betreuungZweiPersonen ?? false;
    _betreuungHaustiere = b?.betreuungHaustiere ?? false;
    _raucher = b?.raucher ?? false;

    if (b?.nationalitat != null && b!.nationalitat.isNotEmpty) {
      _nationalitat = b.nationalitat.first;
    }
    if (b?.religion != null && b!.religion.isNotEmpty) {
      _religion = b.religion.first;
    }

    _selectedAndereSprachen = List<String>.from(
      b?.andereSprachen.where((s) => s.isNotEmpty).toList() ?? [],
    );
    _selectedAllergien = List<String>.from(b?.allergien ?? []);
    _selectedKrankheiten = List<String>.from(b?.krankheiten ?? []);
    _selectedMedikamenten = List<String>.from(b?.medikamenten ?? []);
    _selectedBetreuungsZyklen = List<String>.from(b?.betreuungsZyklen ?? []);
    _selectedVersicherung = List<String>.from(b?.versicherung ?? []);
    _selectedHobbys = List<String>.from(b?.hobbys ?? []);
    _selectedAusbildung = List<String>.from(b?.ausbildung ?? []);
  }

  @override
  void dispose() {
    _vornameController.dispose();
    _nameController.dispose();
    _anschriftController.dispose();
    _groesseController.dispose();
    _gewichtController.dispose();
    _geburtsdatumController.dispose();
    _geburtsortController.dispose();
    _profileImageUrlController.dispose();
    _emailController.dispose();
    _alterKindController.dispose();
    _notizenController.dispose();
    _telNrController.dispose();
    _beruflicheErfahrungController.dispose();
    _datumVerfuegbarkeitController.dispose();
    _vornameAnsprechpersonController.dispose();
    _nachnameAnsprechpersonController.dispose();
    _anschriftAnsprechpersonController.dispose();
    _telNrAnsprechpersonController.dispose();
    _customAusbildungController.dispose();
    _customSpracheController.dispose();
    _customAllergieController.dispose();
    _customKrankheitController.dispose();
    _customMedikamentController.dispose();
    _customHobbyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij wymagane pola (imię i nazwisko w Profilu)')),
      );
      return;
    }

    final rawGroesse = _groesseController.text.trim();
    final rawGewicht = _gewichtController.text.trim().split(RegExp(r'[,.]')).first;

    final updatedBetreuer = Betreuer(
      id: widget.betreuer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      vorname: _vornameController.text.trim(),
      geburtsdatum: _geburtsdatumController.text.trim().isEmpty ? null : _geburtsdatumController.text.trim(),
      geburtsort: _geburtsortController.text.trim().isEmpty ? null : _geburtsortController.text.trim(),
      hasKinder: _hasKinder,
      kinder: _hasKinder ? _kinder : [],
      groesse: int.tryParse(rawGroesse),
      gewicht: int.tryParse(rawGewicht),
      geschlecht: _geschlecht,
      anschrift: _anschriftController.text.trim(),
      telNr: _telNrController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      ausbildung: _selectedAusbildung,
      beruflicheErfahrung: _beruflicheErfahrungController.text.trim().isEmpty ? null : _beruflicheErfahrungController.text.trim(),
      familienstand: _familienstand,
      religion: _religion.isNotEmpty ? [_religion] : [],
      nationalitat: _nationalitat.isNotEmpty ? [_nationalitat] : [],
      deutschKenntnisse: _deutschKenntnisse,
      andereSprachen: _selectedAndereSprachen,
      fuehrerschein: _fuehrerschein,
      bereitFuehrerschein: _bereitFuehrerschein,
      raucher: _raucher,
      allergien: _selectedAllergien,
      krankheiten: _selectedKrankheiten,
      medikamenten: _selectedMedikamenten,
      gartenArbeiten: _gartenArbeiten,
      betreuungsZyklen: _selectedBetreuungsZyklen,
      datumVerfuegbarkeit: _datumVerfuegbarkeitController.text.trim().isEmpty ? null : _datumVerfuegbarkeitController.text.trim(),
      versicherung: _selectedVersicherung,
      betreuungGeschlecht: _betreuungGeschlecht,
      betreuungZweiPersonen: _betreuungZweiPersonen,
      medizinischeErfahrung: _medizinischeErfahrung,
      betreuungHaustiere: _betreuungHaustiere,
      isAvailable: _isAvailable,
      profileImageUrl: _profileImageUrlController.text.trim().isEmpty ? null : _profileImageUrlController.text.trim(),
      hobbys: _selectedHobbys,
      notizen: _notizenController.text.trim().isEmpty ? null : _notizenController.text.trim(),
      vornameAnsprechperson: _vornameAnsprechpersonController.text.trim().isEmpty ? null : _vornameAnsprechpersonController.text.trim(),
      nachnameAnsprechperson: _nachnameAnsprechpersonController.text.trim().isEmpty ? null : _nachnameAnsprechpersonController.text.trim(),
      anschriftAnsprechperson: _anschriftAnsprechpersonController.text.trim().isEmpty ? null : _anschriftAnsprechpersonController.text.trim(),
      telNrAnsprechperson: _telNrAnsprechpersonController.text.trim().isEmpty ? null : _telNrAnsprechpersonController.text.trim(),
      bezugAnsprechperson: _bezugAnsprechperson,
    );

    Navigator.pop(context, updatedBetreuer);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń profil'),
        content: const Text('Czy na pewno chcesz usunąć tę opiekunkę?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'DELETE');
            },
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  void _addKind() {
    final alter = _alterKindController.text.trim();
    if (alter.isEmpty && _geschlechtKind.isEmpty) return;
    final eintrag = alter.isNotEmpty ? '$_geschlechtKind ($alter lat)' : _geschlechtKind;
    setState(() {
      _kinder.add(eintrag);
      _alterKindController.clear();
    });
  }

  void _addCustomSprache() {
    final text = _customSpracheController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedAndereSprachen.contains(text)) {
      setState(() {
        _selectedAndereSprachen.add(text);
        _customSpracheController.clear();
      });
    }
  }

  void _addCustomAllergie() {
    final text = _customAllergieController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedAllergien.contains(text)) {
      setState(() {
        _selectedAllergien.add(text);
        _customAllergieController.clear();
      });
    }
  }

  void _addCustomKrankheit() {
    final text = _customKrankheitController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedKrankheiten.contains(text)) {
      setState(() {
        _selectedKrankheiten.add(text);
        _customKrankheitController.clear();
      });
    }
  }

  void _addCustomMedikament() {
    final text = _customMedikamentController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedMedikamenten.contains(text)) {
      setState(() {
        _selectedMedikamenten.add(text);
        _customMedikamentController.clear();
      });
    }
  }

  void _addHobby() {
    final text = _customHobbyController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedHobbys.contains(text)) {
      setState(() {
        _selectedHobbys.add(text);
        _customHobbyController.clear();
      });
    }
  }

  void _addAusbildung() {
    final text = _customAusbildungController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedAusbildung.contains(text)) {
      setState(() {
        _selectedAusbildung.add(text);
        _customAusbildungController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blueTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F7FC),
    );

    return Theme(
      data: blueTheme,
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edycja opiekuna' : 'Nowy opiekun'),
            backgroundColor: blueTheme.colorScheme.primaryContainer,
            foregroundColor: blueTheme.colorScheme.onPrimaryContainer,
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Usuń profil',
                  onPressed: _delete,
                ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Zapisz',
                onPressed: _save,
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(icon: Icon(Icons.badge_outlined), text: 'Profil'),
                Tab(icon: Icon(Icons.workspace_premium_outlined), text: 'Umiejętności'),
                Tab(icon: Icon(Icons.health_and_safety_outlined), text: 'Zdrowie'),
                Tab(icon: Icon(Icons.event_available_outlined), text: 'Zlecenie'),
                Tab(icon: Icon(Icons.contact_emergency_outlined), text: 'Kontakt ICE'),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: TabBarView(
              children: [
                _buildProfilTab(),
                _buildUmiejetnosciTab(),
                _buildZdrowieTab(),
                _buildZlecenieTab(),
                _buildKontaktIceTab(),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Zapisz profil', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. PROFIL & DANE OSOBOWE ---
  Widget _buildProfilTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Podstawowe dane osobowe',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vornameController,
                decoration: const InputDecoration(
                  labelText: 'Imię',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj imię' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwisko',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj nazwisko' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _anschriftController,
          decoration: const InputDecoration(
            labelText: 'Adres zamieszkania (Polska / UE)',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _telNrController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _geburtsdatumController,
                decoration: const InputDecoration(
                  labelText: 'Data urodzenia',
                  hintText: '01.01.1980',
                  prefixIcon: Icon(Icons.cake_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _geburtsortController,
                decoration: const InputDecoration(
                  labelText: 'Miejsce urodzenia',
                  prefixIcon: Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: const ['Kobieta', 'Mężczyzna'].contains(_geschlecht) ? _geschlecht : 'Kobieta',
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Płeć',
                  prefixIcon: Icon(Icons.wc_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Kobieta', child: Text('Kobieta')),
                  DropdownMenuItem(value: 'Mężczyzna', child: Text('Mężczyzna')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _geschlecht = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: const [
                  'Panna / Kawaler',
                  'Mężatka / Żonaty',
                  'Rozwiedziona / Rozwiedziony',
                  'Wdowa / Wdowiec',
                ].contains(_familienstand)
                    ? _familienstand
                    : 'Panna / Kawaler',
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Stan cywilny',
                  prefixIcon: Icon(Icons.favorite_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Panna / Kawaler',
                    child: Text('Panna / Kawaler', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Mężatka / Żonaty',
                    child: Text('Mężatka / Żonaty', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Rozwiedziona / Rozwiedziony',
                    child: Text('Rozwiedziona / Rozwiedziony', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'Wdowa / Wdowiec',
                    child: Text('Wdowa / Wdowiec', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _familienstand = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: const ['Polska', 'Niemiecka', 'Ukraińska', 'Inna'].contains(_nationalitat) ? _nationalitat : 'Polska',
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Obywatelstwo',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Polska', child: Text('Polska')),
                  DropdownMenuItem(value: 'Niemiecka', child: Text('Niemiecka')),
                  DropdownMenuItem(value: 'Ukraińska', child: Text('Ukraińska')),
                  DropdownMenuItem(value: 'Inna', child: Text('Inna')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _nationalitat = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: const ['Katolicyzm', 'Prawosławie', 'Protestantyzm', 'Brak / Inna'].contains(_religion) ? _religion : 'Katolicyzm',
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Religia',
                  prefixIcon: Icon(Icons.auto_awesome_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Katolicyzm', child: Text('Katolicyzm')),
                  DropdownMenuItem(value: 'Prawosławie', child: Text('Prawosławie')),
                  DropdownMenuItem(value: 'Protestantyzm', child: Text('Protestantyzm')),
                  DropdownMenuItem(value: 'Brak / Inna', child: Text('Brak / Inna')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _religion = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Posiada dzieci?'),
          subtitle: const Text('Czy opiekunka ma dzieci na utrzymaniu / w domu'),
          secondary: const Icon(Icons.child_care_outlined),
          value: _hasKinder,
          onChanged: (val) => setState(() {
            _hasKinder = val;
            if (!val) _kinder.clear();
          }),
        ),
        if (_hasKinder) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _geschlechtKind,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Dziecko',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Syn', child: Text('Syn')),
                            DropdownMenuItem(value: 'Córka', child: Text('Córka')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _geschlechtKind = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _alterKindController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Wiek',
                            suffixText: 'lat',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (_) => _addKind(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _addKind,
                        child: const Icon(Icons.add, size: 20),
                      ),
                    ],
                  ),
                  if (_kinder.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _kinder.map((kindText) {
                        final isSyn = kindText.startsWith('Syn');
                        return Chip(
                          avatar: Icon(
                            isSyn ? Icons.boy_outlined : Icons.girl_outlined,
                            size: 18,
                            color: isSyn ? Colors.blue.shade700 : Colors.pink.shade700,
                          ),
                          label: Text(kindText),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSyn ? Colors.blue.shade200 : Colors.pink.shade200),
                          deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                          onDeleted: () => setState(() => _kinder.remove(kindText)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Zainteresowania / Hobby:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customHobbyController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Wpisz hobby',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addHobby(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _addHobby,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (_selectedHobbys.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedHobbys.map((hobby) {
              return Chip(
                avatar: const Icon(Icons.palette_outlined, size: 16, color: Colors.blueAccent),
                label: Text(hobby),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedHobbys.remove(hobby)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- 2. UMIEJĘTNOŚCI & KWALIFIKACJE ---
  Widget _buildUmiejetnosciTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Języki i kwalifikacje',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
        DropdownButtonFormField<String>(
          value: const [
            'Brak',
            'Podstawowa',
            'Komunikatywna',
            'Dobra',
            'Biegła',
          ].contains(_deutschKenntnisse)
              ? _deutschKenntnisse
              : 'Komunikatywna',
          decoration: const InputDecoration(
            labelText: 'Znajomość języka niemieckiego',
            prefixIcon: Icon(Icons.translate_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Brak', child: Text('Brak')),
            DropdownMenuItem(value: 'Podstawowa', child: Text('Podstawowa')),
            DropdownMenuItem(value: 'Komunikatywna', child: Text('Komunikatywna')),
            DropdownMenuItem(value: 'Dobra', child: Text('Dobra')),
            DropdownMenuItem(value: 'Biegła', child: Text('Biegła')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _deutschKenntnisse = val);
          },
        ),
        const SizedBox(height: 16),
        const Text('Inne języki obce:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customSpracheController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'np. Angielski, Rosyjski',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addCustomSprache(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: _addCustomSprache,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (_selectedAndereSprachen.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedAndereSprachen.map((sp) {
              return Chip(
                avatar: const Icon(Icons.language_outlined, size: 16, color: Colors.blueAccent),
                label: Text(sp),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedAndereSprachen.remove(sp)),
              );
            }).toList(),
          ),
        ],
        const Divider(height: 32),
        SwitchListTile(
          title: const Text('Prawo jazdy'),
          secondary: const Icon(Icons.directions_car_outlined),
          value: _fuehrerschein,
          onChanged: (val) {
            setState(() {
              _fuehrerschein = val;
              if (!val) _bereitFuehrerschein = false;
            });
          },
        ),
        if (_fuehrerschein)
          SwitchListTile(
            title: const Text('Gotowa prowadzić auto w Niemczech'),
            subtitle: const Text('Czynny kierowca (jazda po autostradach / mieście)'),
            secondary: const Icon(Icons.car_rental_outlined),
            value: _bereitFuehrerschein,
            onChanged: (val) => setState(() => _bereitFuehrerschein = val),
          ),
        SwitchListTile(
          title: const Text('Doświadczenie medyczne'),
          subtitle: const Text('np. pielęgniarka, opiekun medyczny, podawanie insuliny'),
          secondary: const Icon(Icons.medical_services_outlined),
          value: _medizinischeErfahrung,
          onChanged: (val) => setState(() => _medizinischeErfahrung = val),
        ),
        const Divider(height: 24),
        const Text(
          'Wykształcenie',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customAusbildungController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Np. liceum / kurs',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addAusbildung(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: _addAusbildung,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (_selectedAusbildung.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedAusbildung.map((sp) {
              return Chip(
                avatar: const Icon(Icons.language_outlined, size: 16, color: Colors.blueAccent),
                label: Text(sp),
                backgroundColor: Colors.blue.shade50,
                side: BorderSide(color: Colors.blue.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedAusbildung.remove(sp)),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _beruflicheErfahrungController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Doświadczenie zawodowe w opiece',
            hintText: 'Gdzie i jak długo pracowała, jacy podopieczni, demencja itp.',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // --- 3. ZDROWIE & CECHY FIZYCZNE ---
  Widget _buildZdrowieTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Parametry fizyczne i stan zdrowia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _gewichtController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Waga',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _groesseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Wzrost',
                  suffixText: 'cm',
                  prefixIcon: Icon(Icons.height_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Osoba paląca tytoń'),
          subtitle: const Text('Zaznacz, jeśli pali (nawet tylko na zewnątrz)'),
          secondary: const Icon(Icons.smoking_rooms_outlined),
          value: _raucher,
          onChanged: (val) => setState(() => _raucher = val),
        ),
        const Divider(height: 24),
        const Text('Alergie i nietolerancje:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customAllergieController,
                decoration: const InputDecoration(
                  hintText: 'np. koty, psy, pyłki, penicylina',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addCustomAllergie(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: _addCustomAllergie,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (_selectedAllergien.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedAllergien.map((all) {
              return Chip(
                avatar: const Icon(Icons.coronavirus_outlined, size: 16, color: Colors.redAccent),
                label: Text(all),
                backgroundColor: Colors.red.shade50,
                side: BorderSide(color: Colors.red.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedAllergien.remove(all)),
              );
            }).toList(),
          ),
        ],
        const Divider(height: 24),
        const Text('Choroby:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customKrankheitController,
                decoration: const InputDecoration(
                  hintText: 'np. chora tarczyca',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addCustomKrankheit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: _addCustomKrankheit,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (_selectedKrankheiten.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedKrankheiten.map((all) {
              return Chip(
                avatar: const Icon(Icons.coronavirus_outlined, size: 16, color: Colors.redAccent),
                label: Text(all),
                backgroundColor: Colors.red.shade50,
                side: BorderSide(color: Colors.red.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedKrankheiten.remove(all)),
              );
            }).toList(),
          ),
        ],
        const Divider(height: 24),
        const Text('Leki, które biorę:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customMedikamentController,
                decoration: const InputDecoration(
                  hintText: 'np. tabletki na serce itp.',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _addCustomMedikament(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: _addCustomMedikament,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (_selectedMedikamenten.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _selectedMedikamenten.map((all) {
              return Chip(
                avatar: const Icon(Icons.coronavirus_outlined, size: 16, color: Colors.redAccent),
                label: Text(all),
                backgroundColor: Colors.red.shade50,
                side: BorderSide(color: Colors.red.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () => setState(() => _selectedMedikamenten.remove(all)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // --- 4. PREFERENCJE ZLECENIA & DOSTĘPNOŚĆ ---
  Widget _buildZlecenieTab() {
    const cycleOptions = ['1 miesiąc', '6 tygodni', '2 miesiące', '3 miesiące', 'Długie wyjazdy'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Dostępność i warunki wyjazdu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: const Text('Status profilu: Aktywna / Dostępna'),
          secondary: Icon(
            _isAvailable ? Icons.check_circle_outline : Icons.pause_circle_outline,
            color: _isAvailable ? Colors.green : Colors.grey,
          ),
          value: _isAvailable,
          onChanged: (val) => setState(() => _isAvailable = val),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _datumVerfuegbarkeitController,
          decoration: const InputDecoration(
            labelText: 'Dostępna od zaraz lub od daty',
            hintText: 'np. Od zaraz / 15.10.2026',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Preferowane długości wyjazdu (turnusy):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: cycleOptions.map((cycle) {
            final isSelected = _selectedBetreuungsZyklen.contains(cycle);
            return FilterChip(
              label: Text(cycle),
              selected: isSelected,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blueAccent,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedBetreuungsZyklen.add(cycle);
                  } else {
                    _selectedBetreuungsZyklen.remove(cycle);
                  }
                });
              },
            );
          }).toList(),
        ),
        const Divider(height: 28),
        DropdownButtonFormField<String>(
          value: _betreuungGeschlecht,
          decoration: const InputDecoration(
            labelText: 'Preferowana płeć podopiecznego',
            prefixIcon: Icon(Icons.person_search_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
            DropdownMenuItem(value: 'Tylko kobieta', child: Text('Tylko kobieta')),
            DropdownMenuItem(value: 'Tylko mężczyzna', child: Text('Tylko mężczyzna')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _betreuungGeschlecht = val);
          },
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Zgoda na opiekę nad 2 osobami (małżeństwo)'),
          secondary: const Icon(Icons.group_outlined),
          value: _betreuungZweiPersonen,
          onChanged: (val) => setState(() => _betreuungZweiPersonen = val ?? false),
        ),
        CheckboxListTile(
          title: const Text('Akceptacja zwierząt domowych'),
          secondary: const Icon(Icons.pets_outlined),
          value: _betreuungHaustiere,
          onChanged: (val) => setState(() => _betreuungHaustiere = val ?? false),
        ),
        CheckboxListTile(
          title: const Text('Pomoc przy pracach w ogrodzie'),
          secondary: const Icon(Icons.yard_outlined),
          value: _gartenArbeiten,
          onChanged: (val) => setState(() => _gartenArbeiten = val ?? false),
        ),
        const Divider(height: 24),
        const Text(
          'Status ubezpieczenia:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        ...[
          'Ubezpieczenie polskie (NFZ / ZUS)',
          'Karta EKUZ',
          'Ubezpieczenie prywatne',
          'Bez ubezpieczenia',
        ].map((typ) {
          final isSelected = _selectedVersicherung.contains(typ);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(typ, style: const TextStyle(fontSize: 14)),
            secondary: Icon(
              typ == 'Bez ubezpieczenia' ? Icons.money_off_csred_outlined : Icons.verified_user_outlined,
              size: 20,
              color: typ == 'Bez ubezpieczenia' ? Colors.redAccent : Colors.blueAccent,
            ),
            value: isSelected,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  if (typ == 'Bez ubezpieczenia') {
                    _selectedVersicherung = ['Bez ubezpieczenia'];
                  } else {
                    _selectedVersicherung.remove('Bez ubezpieczenia');
                    _selectedVersicherung.add(typ);
                  }
                } else {
                  _selectedVersicherung.remove(typ);
                }
                });
                },
          );
        }),
        const Divider(height: 24),
        TextFormField(
          controller: _notizenController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notatki wewnętrzne / Dodatkowe uwagi agencji',
            hintText: 'Wpisz tutaj uwagi dotyczące charakteru, oczekiwań finansowych itp.',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // --- 5. OSOBA DO KONTAKTU / AWARYJNA (ICE) ---
  Widget _buildKontaktIceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Osoba do kontaktu w nagłych wypadkach (Notfallkontakt)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dane bliskiej osoby opiekunki w Polsce do kontaktu w nagłych wypadkach.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _vornameAnsprechpersonController,
                decoration: const InputDecoration(
                  labelText: 'Imię',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _nachnameAnsprechpersonController,
                decoration: const InputDecoration(
                  labelText: 'Nazwisko',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const [
            'Syn / Córka',
            'Mąż / Partner',
            'Matka / Ojciec',
            'Rodzeństwo',
            'Inna',
          ].contains(_bezugAnsprechperson)
              ? _bezugAnsprechperson
              : 'Syn / Córka',
          decoration: const InputDecoration(
            labelText: 'Relacja z opiekunką',
            prefixIcon: Icon(Icons.connect_without_contact_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Syn / Córka', child: Text('Syn / Córka')),
            DropdownMenuItem(value: 'Mąż / Partner', child: Text('Mąż / Partner')),
            DropdownMenuItem(value: 'Matka / Ojciec', child: Text('Matka / Ojciec')),
            DropdownMenuItem(value: 'Rodzeństwo', child: Text('Rodzeństwo')),
            DropdownMenuItem(value: 'Inna', child: Text('Inna')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _bezugAnsprechperson = val);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telNrAnsprechpersonController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Numer telefonu ICE',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _anschriftAnsprechpersonController,
          decoration: const InputDecoration(
            labelText: 'Adres zamieszkania osoby kontaktowej',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}