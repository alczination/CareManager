class Betreuer {
  String id;
  String name;
  String vorname;
  String? geburtsdatum;
  String? geburtsort;
  bool? hasKinder;
  final List<String> kinder;
  int? groesse;
  int? gewicht;
  String geschlecht;
  String anschrift;
  String telNr;
  String? email;
  final List<String> ausbildung;
  String? beruflicheErfahrung;
  String familienstand;
  final List<String> religion;
  final List<String> nationalitat;
  String deutschKenntnisse;
  final List<String> andereSprachen;
  bool fuehrerschein;
  bool bereitFuehrerschein;
  bool raucher;
  final List<String> allergien;
  final List<String> krankheiten;
  final List<String> medikamenten;
  bool gartenArbeiten;
  final List<String> versicherung;
  final List<String> betreuungsZyklen;
  String? datumVerfuegbarkeit;
  String betreuungGeschlecht;
  bool betreuungZweiPersonen;
  bool medizinischeErfahrung;
  bool betreuungHaustiere;
  bool? isAvailable;
  String? profileImageUrl;
  final List<String> hobbys;
  String? notizen;
  String? vornameAnsprechperson;
  String? nachnameAnsprechperson;
  String? anschriftAnsprechperson;
  String? telNrAnsprechperson;
  String? bezugAnsprechperson;

  Betreuer({
    required this.id,
    required this.name,
    required this.vorname,
    this.geburtsdatum,
    this.geburtsort,
    this.hasKinder,
    this.kinder = const [],
    this.groesse,
    this.gewicht,
    required this.geschlecht,
    required this.anschrift,
    required this.telNr,
    this.email,
    this.ausbildung = const [],
    this.beruflicheErfahrung,
    required this.familienstand,
    this.religion = const [],
    this.nationalitat = const [],
    required this.deutschKenntnisse,
    this.andereSprachen = const [],
    required this.fuehrerschein,
    required this.bereitFuehrerschein,
    required this.raucher,
    this.allergien = const [],
    this.krankheiten = const [],
    this.medikamenten = const [],
    required this.gartenArbeiten,
    this.versicherung = const [],
    this.betreuungsZyklen = const [],
    this.datumVerfuegbarkeit,
    required this.betreuungGeschlecht,
    required this.betreuungZweiPersonen,
    required this.medizinischeErfahrung,
    required this.betreuungHaustiere,
    this.isAvailable,
    this.profileImageUrl,
    this.hobbys = const [],
    this.notizen,
    this.vornameAnsprechperson,
    this.nachnameAnsprechperson,
    this.anschriftAnsprechperson,
    this.telNrAnsprechperson,
    this.bezugAnsprechperson,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vorname': vorname,
      'geburtsdatum': geburtsdatum,
      'geburtsort': geburtsort,
      'hasKinder': hasKinder,
      'kinder': kinder,
      'groesse': groesse,
      'gewicht': gewicht,
      'geschlecht': geschlecht,
      'anschrift': anschrift,
      'telNr': telNr,
      'email': email,
      'ausbildung': ausbildung,
      'beruflicheErfahrung': beruflicheErfahrung,
      'familienstand': familienstand,
      'religion': religion,
      'nationalitat': nationalitat,
      'deutschKenntnisse': deutschKenntnisse,
      'andereSprachen': andereSprachen,
      'fuehrerschein': fuehrerschein,
      'bereitFuehrerschein': bereitFuehrerschein,
      'raucher': raucher,
      'allergien': allergien,
      'krankheiten': krankheiten,
      'medikamenten': medikamenten,
      'gartenArbeiten': gartenArbeiten,
      'versicherung': versicherung,
      'betreuungsZyklen': betreuungsZyklen,
      'datumVerfuegbarkeit': datumVerfuegbarkeit,
      'betreuungGeschlecht': betreuungGeschlecht,
      'betreuungZweiPersonen': betreuungZweiPersonen,
      'medizinischeErfahrung': medizinischeErfahrung,
      'betreuungHaustiere': betreuungHaustiere,
      'isAvailable': isAvailable,
      'profileImageUrl': profileImageUrl,
      'hobbys': hobbys,
      'notizen': notizen,
      'vornameAnsprechperson': vornameAnsprechperson,
      'nachnameAnsprechperson': nachnameAnsprechperson,
      'anschriftAnsprechperson': anschriftAnsprechperson,
      'telNrAnsprechperson': telNrAnsprechperson,
      'bezugAnsprechperson': bezugAnsprechperson,
    };
  }

  factory Betreuer.fromJson(Map<String, dynamic> json) => Betreuer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        vorname: json['vorname'] as String? ?? '',
        geburtsdatum: json['geburtsdatum'] as String?,
        geburtsort: json['geburtsort'] as String?,
        hasKinder: json['hasKinder'] as bool? ?? false,
        kinder: List<String>.from(json['kinder'] ?? []),
        groesse: json['groesse'] as int?,
        gewicht: json['gewicht'] as int?,
        geschlecht: json['geschlecht'] as String? ?? 'Kobieta',
        anschrift: json['anschrift'] as String? ?? '',
        telNr: json['telNr'] as String? ?? '',
        email: json['email'] as String?,
        ausbildung: List<String>.from(json['ausbildung'] ?? []),
        beruflicheErfahrung: json['beruflicheErfahrung'] as String?,
        familienstand: json['familienstand'] as String? ?? 'Panna / Kawaler',
        religion: List<String>.from(json['religion'] ?? []),
        nationalitat: List<String>.from(json['nationalitat'] ?? []),
        deutschKenntnisse: json['deutschKenntnisse'] as String? ?? 'Komunikatywna',
        andereSprachen: List<String>.from(json['andereSprachen'] ?? []),
        fuehrerschein: json['fuehrerschein'] as bool? ?? false,
        bereitFuehrerschein: json['bereitFuehrerschein'] as bool? ?? false,
        raucher: json['raucher'] as bool? ?? false,
        allergien: List<String>.from(json['allergien'] ?? []),
        krankheiten: List<String>.from(json['krankheiten'] ?? []),
        medikamenten: List<String>.from(json['medikamenten'] ?? []),
        gartenArbeiten: json['gartenArbeiten'] as bool? ?? false,
        versicherung: List<String>.from(json['versicherung'] ?? []),
        betreuungsZyklen: List<String>.from(json['betreuungsZyklen'] ?? []),
        datumVerfuegbarkeit: json['datumVerfuegbarkeit'] as String?,
        betreuungGeschlecht: json['betreuungGeschlecht'] as String? ?? 'Obojętnie',
        betreuungZweiPersonen: json['betreuungZweiPersonen'] as bool? ?? false,
        medizinischeErfahrung: json['medizinischeErfahrung'] as bool? ?? false,
        betreuungHaustiere: json['betreuungHaustiere'] as bool? ?? false,
        isAvailable: json['isAvailable'] as bool?,
        profileImageUrl: json['profileImageUrl'] as String?,
        hobbys: List<String>.from(json['hobbys'] ?? []),
        notizen: json['notizen'] as String?,
        vornameAnsprechperson: json['vornameAnsprechperson'] as String?,
        nachnameAnsprechperson: json['nachnameAnsprechperson'] as String?,
        anschriftAnsprechperson: json['anschriftAnsprechperson'] as String?,
        telNrAnsprechperson: json['telNrAnsprechperson'] as String?,
        bezugAnsprechperson: json['bezugAnsprechperson'] as String? ?? 'Syn / Córka',
      );

  bool hasReligion(String id) => religion.contains(id);
  bool hasNationalitat(String id) => nationalitat.contains(id);
  bool hasAndereSprachen(String id) => andereSprachen.contains(id);
  bool hasAusbildung(String id) => ausbildung.contains(id);
  bool hasAllergien(String id) => allergien.contains(id);
  bool hasKrankheiten(String id) => krankheiten.contains(id);
  bool hasMedikamenten(String id) => medikamenten.contains(id);
  bool hasBetreuungsZyklen(String id) => betreuungsZyklen.contains(id);
}

class Option {
  final String id;
  final String label;

  const Option({
    required this.id,
    required this.label,
  });
}

class BetreuerOptions {

  static String findLabel(List<Option> list, String id) {
    return list.firstWhere(
      (opt) => opt.id == id,
      orElse: () => Option(id: id, label: id),
    ).label;
  }
}