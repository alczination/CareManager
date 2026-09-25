import 'package:flutter/material.dart';
import '../../models/kunde.dart';

class KundeEditScreen extends StatefulWidget {
  final Kunde? kunde;

  const KundeEditScreen({super.key, this.kunde});

  @override
  State<KundeEditScreen> createState() => _KundeEditScreenState();
}

class _KundeEditScreenState extends State<KundeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _vornameController;
  late TextEditingController _vornameAnsprechpersonController;
  late TextEditingController _nameController;
  late TextEditingController _nameAnsprechpersonController;
  late TextEditingController _anschriftController;
  late TextEditingController _anschriftAnsprechpersonController;
  late TextEditingController _geburtsdatumController;
  late TextEditingController _profileImageUrlController;
  late TextEditingController _telNrController;
  late TextEditingController _telNrAnsprechpersonController;
  late TextEditingController _emailAnsprechpersonController;
  late TextEditingController _groesseController;
  late TextEditingController _gewichtController;
  late TextEditingController _tagessatzController;
  late TextEditingController _customKrankheitController;
  late TextEditingController _customHausarbeitenController;
  late TextEditingController _customHilfsarbeitenController;
  late TextEditingController _customHilfsmittelController;

  String _geschlecht = 'Kobieta';
  String _familienstand = 'Panna / Kawaler';
  String _deutschForderungen = 'Obojętnie';
  String _betreuerGeschlecht = 'Obojętnie';
  String _fuehrerschein = 'Obojętnie';
  String _betreuungsOrt = 'Wioska';
  String _wohnortSituation = 'Własny pokój';
  int? _pflegegrad;
  bool _isAvailable = true;
  String _bezugAnsprechperson = 'Córka / Syn';
  String _pflegedienstHaeufigkeit = '1x dziennie';

  late List<String> _selectedHilfsmittel;
  late List<String> _selectedKrankheiten;
  late List<String> _selectedHausarbeiten;
  late List<String> _selectedHilfsarbeiten;
  late List<String> _selectedZimmerausstattung;
  late List<String> _selectedMedikamenteVerteilung;
  late List<String> _selectedToilettenGang;

  bool get _isEditing => widget.kunde != null;

  @override
  void initState() {
    super.initState();
    final k = widget.kunde;
    _vornameController = TextEditingController(text: k?.vorname ?? '');
    _vornameAnsprechpersonController = TextEditingController(text: k?.vornameAnsprechperson ?? '');
    _nameController = TextEditingController(text: k?.name ?? '');
    _nameAnsprechpersonController = TextEditingController(text: k?.nachnameAnsprechperson ?? '');
    _anschriftController = TextEditingController(text: k?.anschrift ?? '');
    _anschriftAnsprechpersonController = TextEditingController(text: k?.anschriftAnsprechperson ?? '');
    _geburtsdatumController = TextEditingController(text: k?.geburtsdatum ?? '');
    _profileImageUrlController = TextEditingController(text: k?.profileImageUrl ?? '');
    _telNrController = TextEditingController(text: k?.telNr ?? '');
    _telNrAnsprechpersonController = TextEditingController(text: k?.telNrAnsprechperson ?? '');
    _emailAnsprechpersonController = TextEditingController(text: k?.emailAnsprechperson ?? '');
    _groesseController = TextEditingController(text: k?.groesse != null ? k!.groesse.toString() : '');
    _gewichtController = TextEditingController(text: k?.gewicht != null ? k!.gewicht.toString() : '');
    _tagessatzController = TextEditingController(text: k?.tagessatz != null ? k!.tagessatz.toString() : '');
    _customKrankheitController = TextEditingController();
    _customHausarbeitenController = TextEditingController();
    _customHilfsarbeitenController = TextEditingController();
    _customHilfsmittelController = TextEditingController();

    _familienstand = k?.familienstand ?? 'Panna / Kawaler';
    _deutschForderungen = k?.deutschForderungen ?? 'Obojętnie';
    _fuehrerschein = k?.fuehrerschein ?? 'Obojętnie';
    _betreuungsOrt = k?.betreuungsOrt ?? 'Wioska';
    _wohnortSituation = k?.wohnortSituation ?? 'Własny pokój';
    _geschlecht = k?.geschlecht ?? 'Kobieta';
    _betreuerGeschlecht = k?.betreuerGeschlecht ?? 'Obojętnie';
    _pflegegrad = k?.pflegegrad;
    _isAvailable = k?.isAvailable ?? true;
    _bezugAnsprechperson = k?.bezugAnsprechperson ?? 'Córka / Syn';
    _pflegedienstHaeufigkeit = k?.pflegedienstHaeufigkeit ?? '1x dziennie';

    _selectedHilfsmittel = List<String>.from(k?.hilfsmittel ?? []);
    _selectedKrankheiten = List<String>.from(k?.krankheiten ?? []);
    _selectedHausarbeiten = List<String>.from(k?.hausarbeiten ?? []);
    _selectedHilfsarbeiten = List<String>.from(k?.hilfsarbeiten ?? []);
    _selectedZimmerausstattung = List<String>.from(k?.zimmerausstattung ?? []);
    _selectedMedikamenteVerteilung = List<String>.from(k?.medikamenteVerteilung ?? []);
    _selectedToilettenGang = List<String>.from(k?.toilettenGang ?? []);
}

  @override
  void dispose() {
    _vornameController.dispose();
    _vornameAnsprechpersonController.dispose();
    _nameController.dispose();
    _nameAnsprechpersonController.dispose();
    _anschriftController.dispose();
    _anschriftAnsprechpersonController.dispose();
    _geburtsdatumController.dispose();
    _profileImageUrlController.dispose();
    _telNrController.dispose();
    _telNrAnsprechpersonController.dispose();
    _emailAnsprechpersonController.dispose();
    _groesseController.dispose();
    _gewichtController.dispose();
    _tagessatzController.dispose();
    _customKrankheitController.dispose();
    _customHausarbeitenController.dispose();
    _customHilfsarbeitenController.dispose();
    _customHilfsmittelController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij imię i nazwisko w zakładce Kontakt')),
      );
      return;
    }

    final updatedKunde = Kunde(
      id: widget.kunde?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      vorname: _vornameController.text.trim(),
      vornameAnsprechperson: _vornameAnsprechpersonController.text.trim(),
      name: _nameController.text.trim(),
      nachnameAnsprechperson: _nameAnsprechpersonController.text.trim(),
      anschrift: _anschriftController.text.trim(),
      anschriftAnsprechperson: _anschriftAnsprechpersonController.text.trim(),
      geburtsdatum: _geburtsdatumController.text.trim().isEmpty ? null : _geburtsdatumController.text.trim(),
      geschlecht: _geschlecht,
      groesse: int.tryParse(_groesseController.text.trim()),
      gewicht: int.tryParse(_gewichtController.text.trim()),
      betreuerGeschlecht: _betreuerGeschlecht,
      familienstand: _familienstand,
      deutschForderungen: _deutschForderungen,
      fuehrerschein: _fuehrerschein,
      betreuungsOrt: _betreuungsOrt,
      wohnortSituation: _wohnortSituation,
      telNr: _telNrController.text.trim(),
      telNrAnsprechperson: _telNrAnsprechpersonController.text.trim(),
      emailAnsprechperson: _emailAnsprechpersonController.text.trim(),
      bezugAnsprechperson: _bezugAnsprechperson,
      profileImageUrl: _profileImageUrlController.text.trim().isEmpty ? null : _profileImageUrlController.text.trim(),
      pflegegrad: _pflegegrad,
      isAvailable: _isAvailable,
      tagessatz: int.tryParse(_tagessatzController.text.trim()),
      pflegedienstHaeufigkeit: _selectedHilfsmittel.contains('pflegedienst') ? _pflegedienstHaeufigkeit : null,
      hilfsmittel: _selectedHilfsmittel,
      krankheiten: _selectedKrankheiten,
      hausarbeiten: _selectedHausarbeiten,
      hilfsarbeiten: _selectedHilfsarbeiten,
      zimmerausstattung: _selectedZimmerausstattung,
      medikamenteVerteilung: _selectedMedikamenteVerteilung,
      toilettenGang: _selectedToilettenGang,
    );

    Navigator.pop(context, updatedKunde);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń profil'),
        content: const Text('Czy na pewno chcesz usunąć tego podopiecznego?'),
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

  void _addCustomKrankheit() {
    final text = _customKrankheitController.text.trim();
    if (text.isEmpty) return;
    
    if (!_selectedKrankheiten.contains(text)) {
      setState(() {
        _selectedKrankheiten.add(text);
        _customKrankheitController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ta choroba znajduje się już na liście')),
      );
    }
  }

  void _addCustomHausarbeit() {
    final text = _customHausarbeitenController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedHausarbeiten.contains(text)) {
      setState(() {
        _selectedHausarbeiten.add(text);
        _customHausarbeitenController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ten obowiązek znajduje się już na liście')),
      );
    }
  }

  void _addCustomHilfsarbeit() {
    final text = _customHilfsarbeitenController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedHilfsarbeiten.contains(text)) {
      setState(() {
        _selectedHilfsarbeiten.add(text);
        _customHilfsarbeitenController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ta pomoc znajduje się już na liście')),
      );
    }
  }

  void _addCustomHilfsmittel() {
    final text = _customHilfsmittelController.text.trim();
    if (text.isEmpty) return;
    if (!_selectedHilfsmittel.contains(text)) {
      setState(() {
        _selectedHilfsmittel.add(text);
        _customHilfsmittelController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ta rzecz znajduje się już na liście')),
      );
    }
  }
  
  Widget _buildOptionList(List<Option> options, List<String> targetList) {
    return Column(
      children: options.map((opt) {
        final isChecked = targetList.contains(opt.id);
        return CheckboxListTile(
          title: Text(opt.label),
          value: isChecked,
          activeColor: Colors.deepPurple,
          contentPadding: EdgeInsets.zero,
          onChanged: (bool? val) {
            setState(() {
              if (val == true) {
                targetList.add(opt.id);
              } else {
                targetList.remove(opt.id);
              }
            });
          },
        );
      }).toList(),
    );
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

    return Theme(
      data: purpleTheme,
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edycja podopiecznego' : 'Nowy podopieczny'),
            backgroundColor: purpleTheme.colorScheme.primaryContainer,
            foregroundColor: purpleTheme.colorScheme.onPrimaryContainer,
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
              indicatorColor: Colors.deepPurple,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(icon: Icon(Icons.person_outline), text: 'Kontakt'),
                Tab(icon: Icon(Icons.favorite_outline), text: 'Zdrowie'),
                Tab(icon: Icon(Icons.task_alt), text: 'Obowiązki'),
                Tab(icon: Icon(Icons.accessible_outlined), text: 'Wymagania'),
                Tab(icon: Icon(Icons.home_work_outlined), text: 'Mieszkanie'),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            child: TabBarView(
              children: [
                _buildKontaktTab(),
                _buildZdrowieTab(),
                _buildObowiazkiTab(),
                _buildWymaganiaTab(),
                _buildMieszkanieTab(),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
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

  Widget _buildKontaktTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Dane osoby do opieki',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(height: 24),
        TextFormField(
          controller: _vornameController,
          decoration: const InputDecoration(
            labelText: 'Imię',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj imię' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nazwisko',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj nazwisko' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _anschriftController,
          decoration: const InputDecoration(
            labelText: 'Adres / Miasto',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telNrController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Numer telefonu',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _geburtsdatumController,
          decoration: const InputDecoration(
            labelText: 'Data urodzenia (DD.MM.YYYY)',
            hintText: '01.01.1940',
            prefixIcon: Icon(Icons.cake_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const ['Kobieta', 'Mężczyzna', 'Małżeństwo'].contains(_geschlecht) ? _geschlecht : 'Kobieta',
          decoration: const InputDecoration(
            labelText: 'Płeć podopiecznego',
            prefixIcon: Icon(Icons.wc_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Kobieta', child: Text('Kobieta')),
            DropdownMenuItem(value: 'Mężczyzna', child: Text('Mężczyzna')),
            DropdownMenuItem(value: 'Małżeństwo', child: Text('Małżeństwo')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _geschlecht = val);
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tagessatzController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Obecna stawka dniowa (w Euro)',
            prefixIcon: Icon(Icons.attach_money_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const [
            'Panna / Kawaler',
            'Mężatka / Żonaty',
            'Rozwiedziona / Rozwiedziony',
            'Wdowa / Wdowiec',
          ].contains(_familienstand)
              ? _familienstand
              : 'Panna / Kawaler',
          decoration: const InputDecoration(
            labelText: 'Stan cywilny',
            prefixIcon: Icon(Icons.favorite_outline),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Panna / Kawaler', child: Text('Panna / Kawaler')),
            DropdownMenuItem(value: 'Mężatka / Żonaty', child: Text('Mężatka / Żonaty')),
            DropdownMenuItem(value: 'Rozwiedziona / Rozwiedziony', child: Text('Rozwiedziona / Rozwiedziony')),
            DropdownMenuItem(value: 'Wdowa / Wdowiec', child: Text('Wdowa / Wdowiec')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _familienstand = val);
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          secondary: Icon(
            _isAvailable ? Icons.check_circle : Icons.pause_circle_outline,
            color: _isAvailable ? Colors.green : Colors.grey,
          ),
          title: const Text('Status aktywny / Potrzebuje opieki'),
          value: _isAvailable,
          onChanged: (val) => setState(() => _isAvailable = val),
        ),
      const Divider(height: 24),
      const Text(
          'Dane osoby do kontaktu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _vornameAnsprechpersonController,
          decoration: const InputDecoration(
            labelText: 'Imię',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj imię' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameAnsprechpersonController,
          decoration: const InputDecoration(
            labelText: 'Nazwisko',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj nazwisko' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _anschriftAnsprechpersonController,
          decoration: const InputDecoration(
            labelText: 'Adres',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj adres' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telNrAnsprechpersonController,
          decoration: const InputDecoration(
            labelText: 'Numer telefonu',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj telefon' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailAnsprechpersonController,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email),
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj adres mailowy' : null,
        ),
                const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const [
            'Syn / Córka',
            'Małżonek / Partner życiowy',
            'Wnuk / Wnuczka',
            'Inna',
          ].contains(_bezugAnsprechperson)
              ? _bezugAnsprechperson
              : 'Syn / Córka',
          decoration: const InputDecoration(
            labelText: 'Relacja z podopiecznym',
            prefixIcon: Icon(Icons.favorite_outline),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Syn / Córka', child: Text('Syn / Córka')),
            DropdownMenuItem(value: 'Małżonek / Partner życiowy', child: Text('Małżonek / Partner życiowy')),
            DropdownMenuItem(value: 'Wnuk / Wnuczka', child: Text('Wnuk / Wnuczka')),
            DropdownMenuItem(value: 'Inna', child: Text('Inna')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _bezugAnsprechperson = val);
          },
        ),
      ],
    );
  }

  Widget _buildZdrowieTab() {
    final predefinedIds = KundeOptions.krankheiten.map((e) => e.id).toSet();
    final customKrankheiten = _selectedKrankheiten.where((id) => !predefinedIds.contains(id)).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ciało',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
      TextFormField(
          controller: _gewichtController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Waga',
            suffixText: 'kg',
            prefixIcon: Icon(Icons.monitor_weight_outlined),
            border: OutlineInputBorder(),
          ),
        ),
    const SizedBox(height: 12),
    TextFormField(
          controller: _groesseController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Wzrost',
            suffixText: 'cm',
            prefixIcon: Icon(Icons.height_outlined),
            border: OutlineInputBorder(),
          ),
        ),
    const SizedBox(height: 12),
    const Divider(height: 8),
    const SizedBox(height: 12),
        const Text(
          'Stopień opieki (Pflegegrad)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Brak PG'),
              selected: _pflegegrad == null,
              selectedColor: Colors.deepPurple.shade100,
              onSelected: (_) => setState(() => _pflegegrad = null),
            ),
            ...[1, 2, 3, 4, 5].map((pg) {
              return ChoiceChip(
                label: Text('PG $pg'),
                selected: _pflegegrad == pg,
                selectedColor: Colors.deepPurple.shade100,
                onSelected: (selected) {
                  setState(() => _pflegegrad = selected ? pg : null);
                },
              );
            }),
          ],
        ),
        const Divider(height: 32),
        const Text(
          'Diagnozy i choroby (Krankheiten)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildOptionList(KundeOptions.krankheiten, _selectedKrankheiten),
        const SizedBox(height: 6),
        const Text(
          'Inne: ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customKrankheitController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Inne',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _addCustomKrankheit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _addCustomKrankheit,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Dodaj'),
            ),
          ],
        ),
          if (customKrankheiten.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customKrankheiten.map((customName) {
                return Chip(
                  avatar: const Icon(Icons.healing, size: 16, color: Colors.deepPurple),
                  label: Text(customName),
                  backgroundColor: Colors.deepPurple.shade50,
                  side: BorderSide(color: Colors.deepPurple.shade200),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onDeleted: () {
                    setState(() {
                      _selectedKrankheiten.remove(customName);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        const Divider(height: 16),
        const Text(
          'Dzielenie leków',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Kto przygotowuje i dzieli medykamenty:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: KundeOptions.medikamenteVerteilung.map((opt) {
            final isSelected = _selectedMedikamenteVerteilung.contains(opt.id);
            return FilterChip(
              avatar: Icon(
                opt.id == 'familie' ? Icons.family_restroom : Icons.medical_services_outlined,
                size: 18,
                color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
              ),
              label: Text(opt.label),
              selected: isSelected,
              selectedColor: Colors.deepPurple.shade50,
              checkmarkColor: Colors.deepPurple,
              side: BorderSide(
                color: isSelected ? Colors.deepPurple.shade300 : Colors.grey.shade300,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                  _selectedMedikamenteVerteilung.add(opt.id);
                } else {
                  _selectedMedikamenteVerteilung.remove(opt.id);
                }
                });
              },
            );
          }).toList(),
          ),
        const SizedBox(height: 12),
        const Divider(height: 12),
        const SizedBox(height: 12),
        const Text(
          'Wyjścia do toalety',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildOptionList(KundeOptions.toilettenGang, _selectedToilettenGang),
      ],
    );
}

  Widget _buildObowiazkiTab() {
    final predefinedHausIds = KundeOptions.hausarbeiten.map((e) => e.id).toSet();
    final predefinedHilfsIds = KundeOptions.hilfsarbeiten.map((e) => e.id).toSet();
    final customHausarbeiten = _selectedHausarbeiten.where((id) => !predefinedHausIds.contains(id)).toList();
    final customHilfsarbeiten = _selectedHilfsarbeiten.where((id) => !predefinedHilfsIds.contains(id)).toList(); 
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pomoc przy osobie (Hilfsarbeiten)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        const SizedBox(height: 8),
        _buildOptionList(KundeOptions.hilfsarbeiten, _selectedHilfsarbeiten),
                Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customHilfsarbeitenController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Inne',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _addCustomHilfsarbeit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _addCustomHilfsarbeit,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Dodaj'),
            ),
          ],
        ),
          if (customHilfsarbeiten.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customHilfsarbeiten.map((customName) {
                return Chip(
                  avatar: const Icon(Icons.healing, size: 16, color: Colors.deepPurple),
                  label: Text(customName),
                  backgroundColor: Colors.deepPurple.shade50,
                  side: BorderSide(color: Colors.deepPurple.shade200),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onDeleted: () {
                    setState(() {
                      _selectedHilfsarbeiten.remove(customName);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        const Divider(height: 32),
        const Text(
          'Prace domowe (Hausarbeiten)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        const SizedBox(height: 8),
        _buildOptionList(KundeOptions.hausarbeiten, _selectedHausarbeiten),
                const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customHausarbeitenController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Inne',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _addCustomHausarbeit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _addCustomHausarbeit,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Dodaj'),
            ),
          ],
        ),
          if (customHausarbeiten.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customHausarbeiten.map((customName) {
                return Chip(
                  avatar: const Icon(Icons.healing, size: 16, color: Colors.deepPurple),
                  label: Text(customName),
                  backgroundColor: Colors.deepPurple.shade50,
                  side: BorderSide(color: Colors.deepPurple.shade200),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                  onDeleted: () {
                    setState(() {
                      _selectedHausarbeiten.remove(customName);
                    });
                  },
                );
              }).toList(),
            ),
          ],
      ],
    );
  }

  Widget _buildWymaganiaTab() {
    final predefinedHilfsmittelIds = KundeOptions.hilfsmittel.map((e) => e.id).toSet();
    final customHilfsmittel = _selectedHilfsmittel.where((id) => !predefinedHilfsmittelIds.contains(id)).toList();
    final hasPflegedienst = _selectedHilfsmittel.contains('pflegedienst');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Środki pomocnicze i Pflegedienst (Hilfsmittel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildOptionList(KundeOptions.hilfsmittel, _selectedHilfsmittel),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customHilfsmittelController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Inne',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _addCustomHilfsmittel(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _addCustomHilfsmittel,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Dodaj'),
            ),
          ],
        ),
        if (customHilfsmittel.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: customHilfsmittel.map((customName) {
              return Chip(
                avatar: const Icon(Icons.healing, size: 16, color: Colors.deepPurple),
                label: Text(customName),
                backgroundColor: Colors.deepPurple.shade50,
                side: BorderSide(color: Colors.deepPurple.shade200),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.red),
                onDeleted: () {
                  setState(() {
                    _selectedHilfsmittel.remove(customName);
                  });
                },
              );
            }).toList(),
          ),
        ],
        if (hasPflegedienst) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.deepPurple.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_hospital_outlined, size: 18, color: Colors.deepPurple),
                    SizedBox(width: 6),
                    Text(
                      'Częstotliwość wizyt Pflegedienst',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: const [
                    '1x dziennie',
                    '2x dziennie',
                    'Więcej niż 2x dziennie',
                  ].contains(_pflegedienstHaeufigkeit)
                      ? _pflegedienstHaeufigkeit
                      : '1x dziennie',
                  decoration: const InputDecoration(
                    labelText: 'Ile razy dziennie?',
                    prefixIcon: Icon(Icons.access_time),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '1x dziennie', child: Text('1x dziennie')),
                    DropdownMenuItem(value: '2x dziennie', child: Text('2x dziennie')),
                    DropdownMenuItem(value: 'Więcej niż 2x dziennie', child: Text('Więcej niż 2x dziennie')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _pflegedienstHaeufigkeit = val);
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(height: 12),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const ['Obojętnie', 'Dobra', 'Komunikatywna'].contains(_deutschForderungen)
              ? _deutschForderungen
              : 'Obojętnie',
          decoration: const InputDecoration(
            labelText: 'Znajomość języka niemieckiego',
            prefixIcon: Icon(Icons.translate_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
            DropdownMenuItem(value: 'Dobra', child: Text('Dobra')),
            DropdownMenuItem(value: 'Komunikatywna', child: Text('Komunikatywna')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _deutschForderungen = val);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const ['Obojętnie', 'Kobieta', 'Mężczyzna'].contains(_betreuerGeschlecht)
              ? _betreuerGeschlecht
              : 'Obojętnie',
          decoration: const InputDecoration(
            labelText: 'Płeć opiekuna',
            prefixIcon: Icon(Icons.wc_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
            DropdownMenuItem(value: 'Kobieta', child: Text('Kobieta')),
            DropdownMenuItem(value: 'Mężczyzna', child: Text('Mężczyzna')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _betreuerGeschlecht = val);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const ['Obojętnie', 'Mile widziane', 'Wymagane'].contains(_fuehrerschein)
              ? _fuehrerschein
              : 'Obojętnie',
          decoration: const InputDecoration(
            labelText: 'Prawo jazdy',
            prefixIcon: Icon(Icons.directions_car_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
            DropdownMenuItem(value: 'Mile widziane', child: Text('Mile widziane')),
            DropdownMenuItem(value: 'Wymagane', child: Text('Wymagane')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _fuehrerschein = val);
          },
        ),
      ],
    );
  }

  Widget _buildMieszkanieTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Mieszkanie i pobyt',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: const ['Miasto', 'Małe miasto', 'Wioska'].contains(_betreuungsOrt) ? _betreuungsOrt : 'Wioska',
          decoration: const InputDecoration(
            labelText: 'Miejsce pobytu',
            prefixIcon: Icon(Icons.directions_car_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Miasto', child: Text('Miasto')),
            DropdownMenuItem(value: 'Małe miasto', child: Text('Małe miasto')),
            DropdownMenuItem(value: 'Wioska', child: Text('Wioska')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _betreuungsOrt = val);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: const ['Własny pokój', 'Własne mieszkanie'].contains(_wohnortSituation) ? _wohnortSituation : 'Własny pokój',
          decoration: const InputDecoration(
            labelText: 'Sytuacja mieszkalna',
            prefixIcon: Icon(Icons.directions_car_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Własny pokój', child: Text('Własny pokój')),
            DropdownMenuItem(value: 'Własne mieszkanie', child: Text('Własne mieszkanie')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _wohnortSituation = val);
          },
        ),
        const SizedBox(height: 8),
        _buildOptionList(KundeOptions.zimmerausstattung, _selectedZimmerausstattung),
      ],
    );
  }
}