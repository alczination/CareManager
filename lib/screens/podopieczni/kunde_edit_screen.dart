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

  // Osoba 1 (Główny podopieczny)
  late TextEditingController _vornameController;
  late TextEditingController _nameController;
  late TextEditingController _anschriftController;
  late TextEditingController _geburtsdatumController;
  late TextEditingController _groesseController;
  late TextEditingController _gewichtController;
  late TextEditingController _tagessatzController;

  // Osoba 2 (Druga osoba do opieki)
  bool _betreuungZweiPersonen = false;
  late TextEditingController _zweitePersonVornameController;
  late TextEditingController _zweitePersonNameController;
  late TextEditingController _zweitePersonGeburtsdatumController;
  int? _zweitePersonPflegegrad;
  late TextEditingController _zweitePersonDiagnosenController;

  // Termin zlecenia
  DateTime? _datumBedarf;

  // Osoba kontaktowa
  late TextEditingController _vornameAnsprechpersonController;
  late TextEditingController _nameAnsprechpersonController;
  late TextEditingController _anschriftAnsprechpersonController;
  late TextEditingController _telNrController;
  late TextEditingController _telNrAnsprechpersonController;
  late TextEditingController _emailAnsprechpersonController;

  // Custom Tag Controllers
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
    _nameController = TextEditingController(text: k?.name ?? '');
    _anschriftController = TextEditingController(text: k?.anschrift ?? '');
    _geburtsdatumController = TextEditingController(text: k?.geburtsdatum ?? '');
    _telNrController = TextEditingController(text: k?.telNr ?? '');
    _groesseController = TextEditingController(text: k?.groesse != null ? k!.groesse.toString() : '');
    _gewichtController = TextEditingController(text: k?.gewicht != null ? k!.gewicht.toString() : '');
    _tagessatzController = TextEditingController(text: k?.tagessatz != null ? k!.tagessatz.toString() : '');

    // Druga osoba
    _betreuungZweiPersonen = k?.betreuungZweiPersonen ?? false;
    _zweitePersonVornameController = TextEditingController(text: k?.zweitePersonVorname ?? '');
    _zweitePersonNameController = TextEditingController(text: k?.zweitePersonName ?? '');
    _zweitePersonGeburtsdatumController = TextEditingController(text: k?.zweitePersonGeburtsdatum ?? '');
    _zweitePersonPflegegrad = k?.zweitePersonPflegegrad;
    _zweitePersonDiagnosenController = TextEditingController(text: k?.zweitePersonDiagnosen ?? '');

    // Data rozpoczęcia
    if (k?.datumBedarf != null && k!.datumBedarf!.isNotEmpty) {
      final parts = k.datumBedarf!.split('.');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          _datumBedarf = DateTime(y, m, d);
        }
      }
    }

    _vornameAnsprechpersonController = TextEditingController(text: k?.vornameAnsprechperson ?? '');
    _nameAnsprechpersonController = TextEditingController(text: k?.nachnameAnsprechperson ?? '');
    _anschriftAnsprechpersonController = TextEditingController(text: k?.anschriftAnsprechperson ?? '');
    _telNrAnsprechpersonController = TextEditingController(text: k?.telNrAnsprechperson ?? '');
    _emailAnsprechpersonController = TextEditingController(text: k?.emailAnsprechperson ?? '');

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
    _nameController.dispose();
    _anschriftController.dispose();
    _geburtsdatumController.dispose();
    _telNrController.dispose();
    _groesseController.dispose();
    _gewichtController.dispose();
    _tagessatzController.dispose();

    _zweitePersonVornameController.dispose();
    _zweitePersonNameController.dispose();
    _zweitePersonGeburtsdatumController.dispose();
    _zweitePersonDiagnosenController.dispose();

    _vornameAnsprechpersonController.dispose();
    _nameAnsprechpersonController.dispose();
    _anschriftAnsprechpersonController.dispose();
    _telNrAnsprechpersonController.dispose();
    _emailAnsprechpersonController.dispose();

    _customKrankheitController.dispose();
    _customHausarbeitenController.dispose();
    _customHilfsarbeitenController.dispose();
    _customHilfsmittelController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  Future<void> _pickBedarfDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datumBedarf ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      helpText: 'Data rozpoczęcia zlecenia',
      confirmText: 'Zatwierdź',
      cancelText: 'Anuluj',
    );
    if (picked != null) {
      setState(() => _datumBedarf = picked);
    }
  }

  void _save() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uzupełnij wymagane pola zaznaczone na czerwono')),
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
      profileImageUrl: widget.kunde?.profileImageUrl,
      pflegegrad: _pflegegrad,
      isAvailable: _isAvailable,
      tagessatz: int.tryParse(_tagessatzController.text.trim()),
      datumBedarf: _datumBedarf != null ? _formatDate(_datumBedarf!) : null,
      betreuungZweiPersonen: _betreuungZweiPersonen,
      zweitePersonVorname: _betreuungZweiPersonen ? _zweitePersonVornameController.text.trim() : null,
      zweitePersonName: _betreuungZweiPersonen ? _zweitePersonNameController.text.trim() : null,
      zweitePersonGeburtsdatum: _betreuungZweiPersonen ? _zweitePersonGeburtsdatumController.text.trim() : null,
      zweitePersonPflegegrad: _betreuungZweiPersonen ? _zweitePersonPflegegrad : null,
      zweitePersonDiagnosen: _betreuungZweiPersonen ? _zweitePersonDiagnosenController.text.trim() : null,
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.deepPurple.shade100, width: 1),
      ),
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.deepPurple.shade50,
                  child: Icon(icon, size: 18, color: Colors.deepPurple),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionList(List<Option> options, List<String> targetList) {
    return Column(
      children: options.map((opt) {
        final isChecked = targetList.contains(opt.id);
        return CheckboxListTile(
          title: Text(opt.label, style: const TextStyle(fontSize: 14)),
          value: isChecked,
          activeColor: Colors.deepPurple,
          contentPadding: EdgeInsets.zero,
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F7FC),
        appBar: AppBar(
          title: Text(_isEditing ? 'Edycja: ${_vornameController.text} ${_nameController.text}' : 'Nowy podopieczny'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple.shade900,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.deepPurple),
              tooltip: 'Zapisz profil',
              onPressed: _save,
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Kontakt i Termin'),
              Tab(icon: Icon(Icons.favorite_outline), text: 'Zdrowie i PG'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Zapisz dane podopiecznego', style: TextStyle(fontSize: 16)),
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

        // 2. DANE PODSTAWOWE OSOBY 1
        _buildSectionCard(
          title: 'Podopieczny (Główna osoba)',
          icon: Icons.person_outline,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vornameController,
                    decoration: InputDecoration(
                      labelText: 'Imię *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj imię' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nazwisko *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj nazwisko' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _anschriftController,
              decoration: InputDecoration(
                labelText: 'Adres i kod pocztowy w Niemczech',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _geburtsdatumController,
                    decoration: InputDecoration(
                      labelText: 'Data urodzenia',
                      hintText: 'DD.MM.RRRR',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _geschlecht,
                    decoration: InputDecoration(
                      labelText: 'Płeć',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Kobieta', child: Text('Kobieta')),
                      DropdownMenuItem(value: 'Mężczyzna', child: Text('Mężczyzna')),
                    ],
                    onChanged: (val) => setState(() => _geschlecht = val ?? 'Kobieta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagessatzController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Stawka dniowa (EUR)',
                prefixIcon: const Icon(Icons.euro),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),

                // 1. TERMIN I STATUS ZLECENIA
        _buildSectionCard(
          title: 'Termin zlecenia i dyspozycyjność',
          icon: Icons.calendar_today_outlined,
          children: [
            InkWell(
              onTap: _pickBedarfDate,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opieka potrzebna od:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _datumBedarf != null ? _formatDate(_datumBedarf!) : 'Od zaraz / Wybierz datę',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                    if (_datumBedarf != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => setState(() => _datumBedarf = null),
                      ),
                    const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(
                _isAvailable ? Icons.check_circle : Icons.pause_circle_outline,
                color: _isAvailable ? Colors.green : Colors.grey,
              ),
              title: const Text('Zlecenie aktywne', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                _isAvailable ? 'Poszukuje opiekuna w wyznaczonym terminie' : 'Wstrzymane / Brak zapotrzebowania',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isAvailable,
              onChanged: (val) => setState(() => _isAvailable = val),
            ),
          ],
        ),


        // 3. OPIEKA NAD PARĄ / DWOMA OSOBAMI
        _buildSectionCard(
          title: 'Opieka nad 2 osobami',
          icon: Icons.people_outline,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Zlecenie obejmuje dwie osoby', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Zaznacz, jeśli w domu opieki wymaga również druga osoba'),
              value: _betreuungZweiPersonen,
              activeColor: Colors.deepPurple,
              onChanged: (val) => setState(() => _betreuungZweiPersonen = val),
            ),
            if (_betreuungZweiPersonen) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _zweitePersonVornameController,
                      decoration: InputDecoration(
                        labelText: 'Imię 2. osoby',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _zweitePersonNameController,
                      decoration: InputDecoration(
                        labelText: 'Nazwisko 2. osoby',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zweitePersonGeburtsdatumController,
                decoration: InputDecoration(
                  labelText: 'Data urodzenia 2. osoby (DD.MM.RRRR)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Stopień opieki 2. osoby:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Brak PG'),
                    selected: _zweitePersonPflegegrad == null,
                    selectedColor: Colors.deepPurple.shade100,
                    onSelected: (_) => setState(() => _zweitePersonPflegegrad = null),
                  ),
                  ...[1, 2, 3, 4, 5].map((pg) {
                    return ChoiceChip(
                      label: Text('PG $pg'),
                      selected: _zweitePersonPflegegrad == pg,
                      selectedColor: Colors.deepPurple.shade100,
                      onSelected: (selected) => setState(() => _zweitePersonPflegegrad = selected ? pg : null),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zweitePersonDiagnosenController,
                decoration: InputDecoration(
                  labelText: 'Krótki opis stanu zdrowia / mobilności 2. osoby',
                  hintText: 'np. w pełni mobilny, lekka demencja...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),

// 4. OSOBA DO KONTAKTU / RODZINA
        _buildSectionCard(
          title: 'Osoba do kontaktu',
          icon: Icons.contact_phone_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vornameAnsprechpersonController,
                    decoration: InputDecoration(
                      labelText: 'Imię osoby kontaktowej *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj imię' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _nameAnsprechpersonController,
                    decoration: InputDecoration(
                      labelText: 'Nazwisko osoby kontaktowej *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj nazwisko' : null,
                  ),
                ),
              ],
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
              decoration: InputDecoration(
                labelText: 'Relacja z podopiecznym',
                prefixIcon: const Icon(Icons.favorite_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Syn / Córka', child: Text('Syn / Córka')),
                DropdownMenuItem(value: 'Małżonek / Partner życiowy', child: Text('Małżonek / Partner życiowy')),
                DropdownMenuItem(value: 'Wnuk / Wnuczka', child: Text('Wnuk / Wnuczka')),
                DropdownMenuItem(value: 'Inna', child: Text('Inna relacja')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _bezugAnsprechperson = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _anschriftAnsprechpersonController,
              decoration: InputDecoration(
                labelText: 'Adres zamieszkania osoby kontaktowej *',
                prefixIcon: const Icon(Icons.home_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj adres' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _telNrAnsprechpersonController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Numer telefonu *',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj telefon' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _emailAnsprechpersonController,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Adres e-mail *',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Podaj e-mail' : null,
                  ),
                ),
              ],
            ),
          ],
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
        _buildSectionCard(
          title: 'Ciało i Pflegegrad',
          icon: Icons.monitor_weight_outlined,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gewichtController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Waga',
                      suffixText: 'kg',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _groesseController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Wzrost',
                      suffixText: 'cm',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Stopień opieki (Pflegegrad)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
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
                    onSelected: (selected) => setState(() => _pflegegrad = selected ? pg : null),
                  );
                }),
              ],
            ),
          ],
        ),
        _buildSectionCard(
          title: 'Diagnozy i choroby',
          icon: Icons.healing_outlined,
          children: [
            _buildOptionList(KundeOptions.krankheiten, _selectedKrankheiten),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customKrankheitController,
                    decoration: InputDecoration(
                      hintText: 'Dodaj inną chorobę...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: () {
                    final text = _customKrankheitController.text.trim();
                    if (text.isNotEmpty && !_selectedKrankheiten.contains(text)) {
                      setState(() {
                        _selectedKrankheiten.add(text);
                        _customKrankheitController.clear();
                      });
                    }
                  },
                  child: const Text('Dodaj'),
                ),
              ],
            ),
            if (customKrankheiten.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: customKrankheiten.map((c) {
                  return Chip(
                    label: Text(c),
                    onDeleted: () => setState(() => _selectedKrankheiten.remove(c)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildObowiazkiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Pomoc przy osobie (Hilfsarbeiten)',
          icon: Icons.accessibility_new_outlined,
          children: [
            _buildOptionList(KundeOptions.hilfsarbeiten, _selectedHilfsarbeiten),
          ],
        ),
        _buildSectionCard(
          title: 'Prace domowe (Hausarbeiten)',
          icon: Icons.cleaning_services_outlined,
          children: [
            _buildOptionList(KundeOptions.hausarbeiten, _selectedHausarbeiten),
          ],
        ),
      ],
    );
  }

  Widget _buildWymaganiaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Wymagania wobec opiekunki',
          icon: Icons.assignment_turned_in_outlined,
          children: [
            DropdownButtonFormField<String>(
              value: _deutschForderungen,
              decoration: InputDecoration(
                labelText: 'Wymagany język niemiecki',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
                DropdownMenuItem(value: 'Podstawowa', child: Text('Podstawowa znajomość')),
                DropdownMenuItem(value: 'Komunikatywna', child: Text('Komunikatywna znajomość')),
                DropdownMenuItem(value: 'Dobra', child: Text('Dobra znajomość')),
                DropdownMenuItem(value: 'Biegła', child: Text('Biegła / Bardzo dobra')),
              ],
              onChanged: (val) => setState(() => _deutschForderungen = val ?? 'Obojętnie'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _betreuerGeschlecht,
              decoration: InputDecoration(
                labelText: 'Preferowana płeć opiekuna',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
                DropdownMenuItem(value: 'Kobieta', child: Text('Kobieta')),
                DropdownMenuItem(value: 'Mężczyzna', child: Text('Mężczyzna')),
              ],
              onChanged: (val) => setState(() => _betreuerGeschlecht = val ?? 'Obojętnie'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _fuehrerschein,
              decoration: InputDecoration(
                labelText: 'Prawo jazdy opiekuna',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Obojętnie', child: Text('Obojętnie')),
                DropdownMenuItem(value: 'Mile widziane', child: Text('Mile widziane')),
                DropdownMenuItem(value: 'Wymagane', child: Text('Bezwzględnie wymagane')),
              ],
              onChanged: (val) => setState(() => _fuehrerschein = val ?? 'Obojętnie'),
            ),
          ],
        ),
        _buildSectionCard(
          title: 'Środki pomocnicze (Hilfsmittel)',
          icon: Icons.wheelchair_pickup_outlined,
          children: [
            _buildOptionList(KundeOptions.hilfsmittel, _selectedHilfsmittel),
          ],
        ),
      ],
    );
  }

  Widget _buildMieszkanieTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          title: 'Warunki mieszkaniowe i lokalizacja',
          icon: Icons.home_work_outlined,
          children: [
            DropdownButtonFormField<String>(
              value: _betreuungsOrt,
              decoration: InputDecoration(
                labelText: 'Miejsce zamieszkania',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Miasto', child: Text('Duże miasto')),
                DropdownMenuItem(value: 'Małe miasto', child: Text('Małe miasto')),
                DropdownMenuItem(value: 'Wioska', child: Text('Wieś / Teren wiejski')),
              ],
              onChanged: (val) => setState(() => _betreuungsOrt = val ?? 'Wioska'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _wohnortSituation,
              decoration: InputDecoration(
                labelText: 'Zakwaterowanie opiekunki',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Własny pokój', child: Text('Własny pokój')),
                DropdownMenuItem(value: 'Własne piętro / Mieszkanie', child: Text('Własne piętro / Mieszkanie')),
              ],
              onChanged: (val) => setState(() => _wohnortSituation = val ?? 'Własny pokój'),
            ),
            const SizedBox(height: 16),
            const Text('Wyposażenie pokoju opiekuna:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _buildOptionList(KundeOptions.zimmerausstattung, _selectedZimmerausstattung),
          ],
        ),
      ],
    );
  }
}