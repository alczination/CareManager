// lib/services/pdf_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/betreuer.dart';
import '../models/kunde.dart';

class PdfExportOptions {
  String language;
  bool includePhoto;
  bool includePersonalData;
  bool includeMedicalOrHealth;
  bool includeTasksOrPrefs;
  bool includeHousing;

  PdfExportOptions({
    this.language = 'de',
    this.includePhoto = true,
    this.includePersonalData = true,
    this.includeMedicalOrHealth = true,
    this.includeTasksOrPrefs = true,
    this.includeHousing = true,
  });
}

class PdfOptionsDialog extends StatefulWidget {
  final String? profileImageUrl;
  final bool isKunde;

  const PdfOptionsDialog({
    super.key,
    this.profileImageUrl,
    required this.isKunde,
  });

  @override
  State<PdfOptionsDialog> createState() => _PdfOptionsDialogState();
}

class _PdfOptionsDialogState extends State<PdfOptionsDialog> {
  String _selectedLang = 'de';
  bool _includePhoto = true;
  bool _includePersonal = true;
  bool _includeMedical = true;
  bool _includeTasks = true;
  bool _includeHousing = true;

  @override
  void initState() {
    super.initState();
    _includePhoto = widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.isKunde ? 'Eksport profilu podopiecznego' : 'Eksport profilu opiekunki'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Język dokumentu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pl', label: Text('Polski')),
                ButtonSegment(value: 'de', label: Text('Deutsch')),
              ],
              selected: {_selectedLang},
              onSelectionChanged: (val) => setState(() => _selectedLang = val.first),
            ),
            const Divider(height: 24),
            const Text('Sekcje w dokumencie:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            CheckboxListTile(
              title: const Text('Zdjęcie profilowe'),
              value: _includePhoto,
              onChanged: (val) => setState(() => _includePhoto = val ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Dane osobowe i kontaktowe'),
              value: _includePersonal,
              onChanged: (val) => setState(() => _includePersonal = val ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(widget.isKunde ? 'Zdrowie i diagnozy (PG, parametry, leki)' : 'Kwalifikacje i umiejętności'),
              value: _includeMedical,
              onChanged: (val) => setState(() => _includeMedical = val ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Text(widget.isKunde ? 'Czynności opiekuńcze i domowe' : 'Preferencje zlecenia'),
              value: _includeTasks,
              onChanged: (val) => setState(() => _includeTasks = val ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.isKunde)
              CheckboxListTile(
                title: const Text('Warunki mieszkaniowe i wymogi'),
                value: _includeHousing,
                onChanged: (val) => setState(() => _includeHousing = val ?? true),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              PdfExportOptions(
                language: _selectedLang,
                includePhoto: _includePhoto,
                includePersonalData: _includePersonal,
                includeMedicalOrHealth: _includeMedical,
                includeTasksOrPrefs: _includeTasks,
                includeHousing: _includeHousing,
              ),
            );
          },
          child: const Text('Generuj PDF'),
        ),
      ],
    );
  }
}

class PdfService {
  static const Map<String, String> _translationsDE = {
    'Kobieta': 'Weiblich',
    'Mężczyzna': 'Männlich',
    'Małżeństwo': 'Ehepaar',
    'Panna / Kawaler': 'Ledig',
    'Mężatka / Żonaty': 'Verheiratet',
    'Rozwiedziona / Rozwiedziony': 'Geschieden',
    'Wdowa / Wdowiec': 'Verwitwet',
    'Brak': 'Keine',
    'Obojętnie': 'Egal / Keine Präferenz',
    'Dobra': 'Gut',
    'Komunikatywna': 'Kommunikativ',
    'Wymagane': 'Erforderlich',
    'Mile widziane': 'Erwünscht',
    'Własny pokój': 'Eigenes Zimmer',
    'Własne mieszkanie': 'Eigene Wohnung',
    'Miasto': 'Stadt',
    'Małe miasto': 'Kleinstadt',
    'Wioska': 'Dorf',
    'Tak': 'Ja',
    'Nie': 'Nein',
    'Syn / Córka': 'Sohn / Tochter',
    'Córka / Syn': 'Tochter / Sohn',
    'Małżonek / Partner życiowy': 'Ehepartner / Lebensgefährte',
    'Wnuk / Wnuczka': 'Enkel / Enkelin',
    'Inna': 'Andere',
    'Rodzina rozdziela': 'Familie richtet her',
    'Pflegedienst rozdziela': 'Pflegedienst richtet her',
    'Samodzielnie': 'Selbstständig',
    'Samemu': 'Selbstständig',
    'Pampersy / Wkładki': 'Windeln / Inkontinenzmaterial',
    'Pampers': 'Windeln / Inkontinenzmaterial',
    'Cewnik (Katheter)': 'Katheter',
    'Cewnik': 'Katheter',
    'Stomia (Stoma)': 'Stoma',
    'Stomia': 'Stoma',
    'Inkontynencja moczowa': 'Harninkontinenz',
    'Inkontynencja (nietrzymanie moczu)': 'Harninkontinenz',
    'Inkontynencja kałowa': 'Stuhlinkontinenz',
    'Krzesło toaletowe (Toilettenstuhl)': 'Toilettenstuhl',
    'Krzesło toaletowe': 'Toilettenstuhl',
    'Z pomocą opiekuna': 'Mit Hilfe',
  };

  static String _t(String? key, String lang) {
    if (key == null || key.trim().isEmpty) {
      return lang == 'de' ? 'Keine Angabe' : 'Brak danych';
    }
    final cleanKey = key.trim();
    if (lang == 'de') {
      return _translationsDE[cleanKey] ?? cleanKey;
    }
    return cleanKey;
  }

  static Future<pw.MemoryImage?> _loadImage(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(path));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          return pw.MemoryImage(bytes);
        }
      } else if (!kIsWeb) {
        final file = File(path);
        if (await file.exists()) {
          return pw.MemoryImage(await file.readAsBytes());
        }
      }
    } catch (e) {
      debugPrint('Błąd ładowania zdjęcia do PDF: $e');
    }
    return null;
  }

  static Future<void> showPdfOptionsAndGenerate(BuildContext context, Betreuer b) async {
    final options = await showDialog<PdfExportOptions>(
      context: context,
      builder: (ctx) => PdfOptionsDialog(profileImageUrl: b.profileImageUrl, isKunde: false),
    );
    if (options != null) {
      await _generateBetreuerPdf(b, options);
    }
  }

  static Future<void> generateKundePdf(BuildContext context, Kunde k) async {
    final options = await showDialog<PdfExportOptions>(
      context: context,
      builder: (ctx) => PdfOptionsDialog(profileImageUrl: k.profileImageUrl, isKunde: true),
    );
    if (options != null) {
      await _generateKundePdf(k, options);
    }
  }

  // --- GENERATOR DLA PODOPIECZNEGO (KUNDE) ---
  static Future<void> _generateKundePdf(Kunde k, PdfExportOptions options) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      debugPrint('Fallback do wbudowanych czcionek: $e');
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final profileImage = options.includePhoto ? await _loadImage(k.profileImageUrl) : null;
    final isDe = options.language == 'de';

    const primary = PdfColor.fromInt(0xFF5B3E96);
    const primarySoft = PdfColor.fromInt(0xFFF3EEFA);
    const textDark = PdfColor.fromInt(0xFF1E1B24);
    const textMuted = PdfColor.fromInt(0xFF6B6675);
    const borderSoft = PdfColor.fromInt(0xFFE7E3EE);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) => [
          // 1. Nagłówek dokumentu
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (options.includePhoto && profileImage != null)
                pw.Container(
                  width: 72,
                  height: 72,
                  margin: const pw.EdgeInsets.only(right: 18),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                    border: pw.Border.all(color: primary, width: 2),
                  ),
                )
              else
                pw.Container(
                  width: 72,
                  height: 72,
                  margin: const pw.EdgeInsets.only(right: 18),
                  decoration: const pw.BoxDecoration(color: primarySoft, shape: pw.BoxShape.circle),
                  child: pw.Center(
                    child: pw.Text(
                      '${k.vorname.isNotEmpty ? k.vorname[0] : ""}${k.name.isNotEmpty ? k.name[0] : ""}',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primary),
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${k.vorname} ${k.name}',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: textDark),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      k.anschrift.isNotEmpty ? k.anschrift : (isDe ? 'Keine Adresse' : 'Brak adresu'),
                      style: const pw.TextStyle(fontSize: 11, color: textMuted),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        _buildBadge(
                          (k.isAvailable ?? true) ? (isDe ? 'Aktiv' : 'Aktywny') : (isDe ? 'Pausiert' : 'Wstrzymany'),
                          (k.isAvailable ?? true) ? PdfColors.green800 : PdfColors.red800,
                          (k.isAvailable ?? true) ? PdfColors.green50 : PdfColors.red50,
                        ),
                        if (k.pflegegrad != null) ...[
                          pw.SizedBox(width: 8),
                          _buildBadge('Pflegegrad ${k.pflegegrad}', primary, primarySoft),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    isDe ? 'BETREUUNGSBEDARF' : 'KARTA PODOPIECZNEGO',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primary),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    DateTime.now().toString().substring(0, 10),
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                  if (k.tagessatz != null) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      isDe ? 'Tagessatz: ${k.tagessatz} €/Tag' : 'Stawka: ${k.tagessatz} €/dzień',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primary),
                    ),
                  ],
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: borderSoft),
          pw.SizedBox(height: 14),

          // 2. Dane personalne podopiecznego
          if (options.includePersonalData) ...[
            _buildCardSection(
              title: isDe ? 'Persönliche Informationen' : 'Dane personalne',
              primaryColor: primary,
              child: pw.Row(
                children: [
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Geschlecht' : 'Płeć', _t(k.geschlecht, options.language))),
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Geburtsdatum' : 'Data urodzenia', k.geburtsdatum ?? '-')),
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Telefon' : 'Telefon', k.telNr.isNotEmpty ? k.telNr : '-')),
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Familienstand' : 'Stan cywilny', _t(k.familienstand, options.language))),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Osoba kontaktowa (jeśli podana)
            if (k.vornameAnsprechperson != null && k.vornameAnsprechperson!.trim().isNotEmpty) ...[
              _buildCardSection(
                title: isDe ? 'Ansprechperson / Kontakt' : 'Osoba do kontaktu',
                primaryColor: primary,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildMetaItem(
                        isDe ? 'Name' : 'Imię i nazwisko',
                        '${k.vornameAnsprechperson ?? ""} ${k.nachnameAnsprechperson ?? ""}'.trim(),
                      ),
                    ),
                    pw.Expanded(
                      child: _buildMetaItem(
                        isDe ? 'Beziehung' : 'Relacja',
                        _t(k.bezugAnsprechperson, options.language),
                      ),
                    ),
                    pw.Expanded(
                      child: _buildMetaItem(
                        isDe ? 'Telefon' : 'Telefon',
                        k.telNrAnsprechperson != null && k.telNrAnsprechperson!.isNotEmpty ? k.telNrAnsprechperson! : '-',
                      ),
                    ),
                    pw.Expanded(
                      child: _buildMetaItem(
                        isDe ? 'E-Mail' : 'E-mail',
                        k.emailAnsprechperson != null && k.emailAnsprechperson!.isNotEmpty ? k.emailAnsprechperson! : '-',
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          ],

          // 3. Zdrowie, parametry fizyczne, toaleta, leki, sprzęt
          if (options.includeMedicalOrHealth) ...[
            _buildCardSection(
              title: isDe ? 'Gesundheitszustand & Physische Parameter' : 'Stan zdrowia i parametry fizyczne',
              primaryColor: primary,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Parametry: Waga, Wzrost, Leki, Toaleta
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Gewicht' : 'Waga',
                          k.gewicht != null ? '${k.gewicht} kg' : '-',
                        ),
                      ),
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Größe' : 'Wzrost',
                          k.groesse != null ? '${k.groesse} cm' : '-',
                        ),
                      ),
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Medikamentengabe' : 'Dzielenie leków',
                          k.medikamenteVerteilung.isEmpty
                              ? '-'
                              : k.medikamenteVerteilung.map((id) {
                                  final label = KundeOptions.findLabel(KundeOptions.medikamenteVerteilung, id);
                                  return _t(label, options.language);
                                }).join(', '),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // Toaleta i fizjologia
                  pw.Text(
                    isDe ? 'Toilettengang & Kontinenz:' : 'Toaleta i fizjologia:',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  pw.SizedBox(height: 4),
                  () {
                    final items = k.toilettenGang.map((id) {
                      final label = KundeOptions.findLabel(KundeOptions.toilettenGang, id);
                      return _t(label, options.language);
                    }).toList();

                    if (k.krankheiten.contains('inkontinenz') && !k.toilettenGang.contains('inkontinenz')) {
                      items.add(isDe ? 'Harninkontinenz' : 'Inkontynencja moczowa');
                    }
                    if (k.hilfsmittel.contains('toilettenstuhl') && !k.toilettenGang.contains('toilettenstuhl')) {
                      items.add(isDe ? 'Toilettenstuhl' : 'Krzesło toaletowe');
                    }

                    if (items.isEmpty) {
                      return pw.Text(
                        isDe ? 'Selbstständig / Keine Einschränkungen' : 'Samodzielnie / Brak problemów',
                        style: const pw.TextStyle(fontSize: 9.5, color: textMuted),
                      );
                    }

                    return pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.map((label) {
                        return _buildChip(label, PdfColors.indigo900, PdfColors.indigo50);
                      }).toList(),
                    );
                  }(),
                  pw.SizedBox(height: 10),

                  // Diagnozy i choroby
                  pw.Text(
                    isDe ? 'Diagnosen & Krankheiten:' : 'Diagnozy i choroby:',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  pw.SizedBox(height: 4),
                  k.krankheiten.isEmpty
                      ? pw.Text(isDe ? 'Keine erfasst' : 'Brak', style: const pw.TextStyle(fontSize: 9.5, color: textMuted))
                      : pw.Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: k.krankheiten.map((id) {
                            return _buildChip(KundeOptions.findLabel(KundeOptions.krankheiten, id), primary, primarySoft);
                          }).toList(),
                        ),
                  pw.SizedBox(height: 10),

                  // Środki pomocnicze i Pflegedienst
                  pw.Text(
                    isDe ? 'Vorhandene Hilfsmittel & Pflegedienst:' : 'Środki pomocnicze i Pflegedienst:',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                  pw.SizedBox(height: 4),
                  if (k.hilfsmittel.isEmpty)
                    pw.Text(isDe ? 'Keine' : 'Brak', style: const pw.TextStyle(fontSize: 9.5, color: textMuted))
                  else
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (k.hilfsmittel.contains('pflegedienst'))
                          _buildChip(
                            k.pflegedienstHaeufigkeit != null && k.pflegedienstHaeufigkeit!.isNotEmpty
                                ? 'Pflegedienst: ${k.pflegedienstHaeufigkeit}'
                                : 'Pflegedienst',
                            primary,
                            primarySoft,
                          ),
                        ...k.hilfsmittel.where((id) => id != 'pflegedienst').map((id) {
                          return _buildChip(
                            KundeOptions.findLabel(KundeOptions.hilfsmittel, id),
                            PdfColors.blueGrey800,
                            PdfColors.blueGrey50,
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // 4. Obowiązki (Pomoc przy osobie / Prowadzenie domu)
          if (options.includeTasksOrPrefs) ...[
            _buildCardSection(
              title: isDe ? 'Aufgabenbereich der Betreuungskraft' : 'Zakres obowiązków opiekuna',
              primaryColor: primary,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isDe ? 'Grundpflege & Betreuung:' : 'Pomoc przy osobie:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                        ),
                        pw.SizedBox(height: 6),
                        if (k.hilfsarbeiten.isEmpty)
                          pw.Text(isDe ? 'Keine' : 'Brak', style: const pw.TextStyle(fontSize: 9.5, color: textMuted))
                        else
                          ...k.hilfsarbeiten.map(
                            (id) => _buildCheckItem(KundeOptions.findLabel(KundeOptions.hilfsarbeiten, id), primary),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          isDe ? 'Hauswirtschaftliche Tätigkeiten:' : 'Prowadzenie gospodarstwa:',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textDark),
                        ),
                        pw.SizedBox(height: 6),
                        if (k.hausarbeiten.isEmpty)
                          pw.Text(isDe ? 'Keine' : 'Brak', style: const pw.TextStyle(fontSize: 9.5, color: textMuted))
                        else
                          ...k.hausarbeiten.map(
                            (id) => _buildCheckItem(KundeOptions.findLabel(KundeOptions.hausarbeiten, id), primary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // 5. Wymogi i warunki mieszkaniowe
          if (options.includeHousing) ...[
            _buildCardSection(
              title: isDe ? 'Wohnsituation & Anforderungen an die Betreuungskraft' : 'Wymogi i warunki lokalowe',
              primaryColor: primary,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Deutschkenntnisse' : 'Znajomość niemieckiego',
                          _t(k.deutschForderungen, options.language),
                        ),
                      ),
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Bevorzugtes Geschlecht' : 'Preferowana płeć',
                          _t(k.betreuerGeschlecht, options.language),
                        ),
                      ),
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Führerschein' : 'Prawo jazdy',
                          _t(k.fuehrerschein, options.language),
                        ),
                      ),
                      pw.Expanded(
                        child: _buildMetaItem(
                          isDe ? 'Standort / Wohnen' : 'Lokalizacja / Pokój',
                          '${_t(k.betreuungsOrt, options.language)} (${_t(k.wohnortSituation, options.language)})',
                        ),
                      ),
                    ],
                  ),
                  if (k.zimmerausstattung.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      isDe ? 'Zimmerausstattung für die Betreuungskraft:' : 'Wyposażenie pokoju opiekuna:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: k.zimmerausstattung.map((id) {
                        return _buildChip(
                          KundeOptions.findLabel(KundeOptions.zimmerausstattung, id),
                          primary,
                          primarySoft,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Profil_${k.vorname}_${k.name}.pdf',
    );
  }

  // --- GENERATOR DLA OPIEKUNKI (BETREUER) ---
  static Future<void> _generateBetreuerPdf(Betreuer b, PdfExportOptions options) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      fontBold = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final profileImage = options.includePhoto ? await _loadImage(b.profileImageUrl) : null;
    final isDe = options.language == 'de';

    const primaryBlue = PdfColor.fromInt(0xFF1E5BB8);
    const primarySoft = PdfColor.fromInt(0xFFEDF3FD);
    const textDark = PdfColor.fromInt(0xFF1A2230);
    const textMuted = PdfColor.fromInt(0xFF5F6B80);
    const borderSoft = PdfColor.fromInt(0xFFE2E8F0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) => [
          // Nagłówek
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (options.includePhoto && profileImage != null)
                pw.Container(
                  width: 72,
                  height: 72,
                  margin: const pw.EdgeInsets.only(right: 18),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(image: profileImage, fit: pw.BoxFit.cover),
                    border: pw.Border.all(color: primaryBlue, width: 2),
                  ),
                )
              else
                pw.Container(
                  width: 72,
                  height: 72,
                  margin: const pw.EdgeInsets.only(right: 18),
                  decoration: const pw.BoxDecoration(color: primarySoft, shape: pw.BoxShape.circle),
                  child: pw.Center(
                    child: pw.Text(
                      '${b.vorname.isNotEmpty ? b.vorname[0] : ""}${b.name.isNotEmpty ? b.name[0] : ""}',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryBlue),
                    ),
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${b.vorname} ${b.name}',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: textDark),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      b.anschrift.isNotEmpty ? b.anschrift : (isDe ? 'Keine Adresse' : 'Brak adresu'),
                      style: const pw.TextStyle(fontSize: 11, color: textMuted),
                    ),
                    pw.SizedBox(height: 6),
                    _buildBadge(
                      (b.isAvailable ?? true) ? (isDe ? 'Verfügbar' : 'Dostępny/a') : (isDe ? 'Im Einsatz' : 'W zleceniu'),
                      (b.isAvailable ?? true) ? PdfColors.green800 : PdfColors.orange900,
                      (b.isAvailable ?? true) ? PdfColors.green50 : PdfColors.orange50,
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    isDe ? 'BETREUERPROFIL' : 'PROFIL OPIEKUNA',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryBlue),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    DateTime.now().toString().substring(0, 10),
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: borderSoft),
          pw.SizedBox(height: 14),

          // Dane osobowe
          if (options.includePersonalData) ...[
            _buildCardSection(
              title: isDe ? 'Persönliche Angaben' : 'Dane personalne',
              primaryColor: primaryBlue,
              child: pw.Row(
                children: [
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Geschlecht' : 'Płeć', _t(b.geschlecht, options.language))),
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Geburtsdatum' : 'Data urodzenia', b.geburtsdatum ?? '-')),
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Handynummer' : 'Telefon', b.telNr.isNotEmpty ? b.telNr : '-')),
                  pw.Expanded(child: _buildMetaItem(isDe ? 'Familienstand' : 'Stan cywilny', _t(b.familienstand, options.language))),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Kwalifikacje
          if (options.includeMedicalOrHealth) ...[
            _buildCardSection(
              title: isDe ? 'Qualifikationen & Kenntnisse' : 'Kwalifikacje i umiejętności',
              primaryColor: primaryBlue,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Deutschkenntnisse' : 'Znajomość niemieckiego',
                      _t(b.deutschKenntnisse, options.language),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Führerschein' : 'Prawo jazdy',
                      b.fuehrerschein ? (isDe ? 'Ja' : 'Tak') : (isDe ? 'Nein' : 'Nie'),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Med. Erfahrung' : 'Doświadczenie med.',
                      b.medizinischeErfahrung ? (isDe ? 'Ja' : 'Tak') : (isDe ? 'Nein' : 'Nie'),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Raucher/in' : 'Palacz',
                      b.raucher ? (isDe ? 'Ja' : 'Tak') : (isDe ? 'Nein' : 'Nie'),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Preferencje
          if (options.includeTasksOrPrefs) ...[
            _buildCardSection(
              title: isDe ? 'Einsatzpräferenzen' : 'Preferencje zlecenia',
              primaryColor: primaryBlue,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Zu betreuende Person' : 'Preferowana płeć',
                      _t(b.betreuungGeschlecht, options.language),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Haustiere akzeptiert' : 'Zwierzęta',
                      b.betreuungHaustiere ? (isDe ? 'Ja' : 'Tak') : (isDe ? 'Nein' : 'Nie'),
                    ),
                  ),
                  pw.Expanded(
                    child: _buildMetaItem(
                      isDe ? 'Gartenarbeiten' : 'Prace w ogrodzie',
                      b.gartenArbeiten ? (isDe ? 'Ja' : 'Tak') : (isDe ? 'Nein' : 'Nie'),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // Notatki
          if (b.notizen != null && b.notizen!.trim().isNotEmpty) ...[
            _buildCardSection(
              title: isDe ? 'Zusätzliche Notizen' : 'Dodatkowe uwagi',
              primaryColor: primaryBlue,
              child: pw.Text(
                b.notizen!.trim(),
                style: const pw.TextStyle(fontSize: 10, color: textDark, lineSpacing: 2),
              ),
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Profil_${b.vorname}_${b.name}.pdf',
    );
  }

  // --- WIDGETY POMOCNICZE W STYLU "CARD" ---

  static pw.Widget _buildCardSection({
    required String title,
    required PdfColor primaryColor,
    required pw.Widget child,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  static pw.Widget _buildMetaItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColor.fromInt(0xFF6B7280))),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1F2937)),
        ),
      ],
    );
  }

  static pw.Widget _buildBadge(String label, PdfColor textColor, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: textColor),
      ),
    );
  }

  static pw.Widget _buildChip(String label, PdfColor textColor, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: 8.5, color: textColor, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildCheckItem(String text, PdfColor checkColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            decoration: pw.BoxDecoration(color: checkColor, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 6),
          pw.Text(text, style: const pw.TextStyle(fontSize: 9.5, color: PdfColor.fromInt(0xFF374151))),
        ],
      ),
    );
  }
}