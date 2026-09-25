class Kunde {
  // Betreuende Person
  String id;
  String vorname;
  String name;
  String anschrift;
  String telNr;
  int? groesse;
  int? gewicht;
  int? pflegegrad;
  String? geburtsdatum;
  String geschlecht;
  String betreuerGeschlecht;
  String familienstand;
  String deutschForderungen;
  String fuehrerschein;
  String betreuungsOrt;
  String wohnortSituation;
  String? profileImageUrl;
  bool? isAvailable;
  int? tagessatz;
  String? pflegedienstHaeufigkeit;
  // Ansprechperson
  String vornameAnsprechperson;
  String nachnameAnsprechperson;
  String anschriftAnsprechperson;
  String telNrAnsprechperson;
  String emailAnsprechperson;
  String bezugAnsprechperson;
  // Checklists
  final List<String> hilfsmittel;
  final List<String> krankheiten;
  final List<String> hausarbeiten;
  final List<String> hilfsarbeiten;
  final List<String> zimmerausstattung;
  final List<String> medikamenteVerteilung;
  final List<String> toilettenGang;
  
  Kunde({
    required this.id,
    required this.name,
    required this.vorname,
    required this.telNr,
    this.groesse,
    this.gewicht,
    this.pflegegrad,
    this.geburtsdatum,
    required this.geschlecht,
    required this.betreuerGeschlecht,
    required this.anschrift,
    required this.familienstand,
    required this.deutschForderungen,
    required this.fuehrerschein,
    required this.betreuungsOrt,
    required this.wohnortSituation,
    this.profileImageUrl,
    this.isAvailable,
    this.tagessatz,
    this.pflegedienstHaeufigkeit,
    this.hilfsmittel = const [],
    this.krankheiten = const [],
    this.hausarbeiten = const [],
    this.hilfsarbeiten = const [],
    this.zimmerausstattung = const [],
    required this.vornameAnsprechperson,
    required this.nachnameAnsprechperson,
    required this.anschriftAnsprechperson,
    required this.telNrAnsprechperson,
    required this.emailAnsprechperson,
    required this.bezugAnsprechperson,
    required this.medikamenteVerteilung,
    required this.toilettenGang,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'vorname': vorname,
    'name': name,
    'anschrift': anschrift,
    'telNr': telNr,
    'koerpergroesse': groesse,
    'gewicht': gewicht,
    'pflegegrad': pflegegrad,
    'geburtsdatum': geburtsdatum,
    'geschlecht': geschlecht,
    'familienstand': familienstand,
    'deutschForderungen': deutschForderungen,
    'fuehrerschein': fuehrerschein,
    'betreuungsOrt': betreuungsOrt,
    'wohnortSituation': wohnortSituation,
    'profileImageUrl': profileImageUrl,
    'isAvailable': isAvailable,
    'tagessatz': tagessatz,
    'pflegedienstHaeufigkeit': pflegedienstHaeufigkeit,
    'hilfsmittel': hilfsmittel,
    'krankheiten': krankheiten,
    'hausarbeiten': hausarbeiten,
    'hilfsarbeiten': hilfsarbeiten,
    'zimmerausstattung': zimmerausstattung,
    'vornameAnsprechperson': vornameAnsprechperson,
    'nachnameAnsprechperson': nachnameAnsprechperson,
    'anschriftAnsprechperson': anschriftAnsprechperson,
    'telNrAnsprechperson': telNrAnsprechperson,
    'emailAnsprechperson': emailAnsprechperson,
    'bezugAnsprechperson': bezugAnsprechperson,
  };

  factory Kunde.fromJson(Map<String, dynamic> json) => Kunde(
    id: json['id'] ?? '',
    vorname: json['vorname'] ?? '',
    name: json['name'] ?? '',
    anschrift: json['anschrift'] ?? '',
    telNr: json['telNr'] ?? '',
    groesse: json['groesse'],
    gewicht: json['gewicht'],
    pflegegrad: json['pflegegrad'],
    geburtsdatum: json['geburtsdatum'],
    geschlecht: json['geschlecht'] ?? 'Kobieta',
    betreuerGeschlecht: json['betreuerGeschlecht'] ?? 'Obojętnie',
    familienstand: json['familienstand'] ?? 'Panna / Kawaler',
    deutschForderungen: json['deutschForderungen'] ?? 'Obojętnie',
    fuehrerschein: json['fuehrerschein'] ?? 'Obojętnie',
    betreuungsOrt: json['betreuungsOrt'] ?? 'Wioska',
    wohnortSituation: json['wohnortSituation'] ?? 'Własny pokój',
    profileImageUrl: json['profileImageUrl'],
    isAvailable: json['isAvailable'] ?? true,
    tagessatz: json['tagessatz'],
    pflegedienstHaeufigkeit: json['pflegedienstHaeufigkeit'] as String?,
    hilfsmittel: List<String>.from(json['hilfsmittel'] ?? []),
    krankheiten: List<String>.from(json['krankheiten'] ?? []),
    hausarbeiten: List<String>.from(json['hausarbeiten'] ?? []),
    hilfsarbeiten: List<String>.from(json['hilfsarbeiten'] ?? []),
    zimmerausstattung: List<String>.from(json['zimmerausstattung'] ?? []),
    medikamenteVerteilung: List<String>.from(json['medikamenteVerteilung'] ?? []),
    toilettenGang: List<String>.from(json['toilettenGang'] ?? []),
    vornameAnsprechperson: json['vornameAnsprechperson'],
    nachnameAnsprechperson: json['nachnameAnsprechperson'],
    anschriftAnsprechperson: json['anschriftAnsprechperson'],
    telNrAnsprechperson: json['telNrAnsprechperson'],
    emailAnsprechperson: json['emailAnsprechperson'],
    bezugAnsprechperson: json['bezugAnsprechperson'] ?? 'Córka / Syn',

  );

  bool hasHilfsmittel(String id) => hilfsmittel.contains(id);
  bool hasKrankheit(String id) => krankheiten.contains(id);
  bool hasHausarbeiten(String id) => hausarbeiten.contains(id);
  bool hasHilfsarbeiten(String id) => hilfsarbeiten.contains(id); 
  bool hasZimmerausstattung(String id) => zimmerausstattung.contains(id);
  bool hasMedikamenteverteilung(String id) => medikamenteVerteilung.contains(id);
  bool hasToilettenGang(String id) => toilettenGang.contains(id);
}

class Option {
  final String id;
  final String label;

  const Option({
    required this.id,
    required this.label,
  });
}

class KundeOptions {
  static const List<Option> hilfsmittel = [
    Option(id: 'pflegedienst', label: 'Pflegedienst'),
    Option(id: 'tagespflege', label: 'Tagespflege'),
    Option(id: 'notrufknopf', label: 'Notrufknopf'),
    Option(id: 'essenaufraedern', label: 'Essen auf Rädern'),
    Option(id: 'demenzcafe', label: 'Demenzcafe'),
    Option(id: 'rollator', label: 'Rollator'),
    Option(id: 'rollstuhl', label: 'Rollstuhl'),
    Option(id: 'duschstuhl', label: 'Duschstuhl'),
    Option(id: 'nachtstuhl', label: 'Nachtstuhl'),
    Option(id: 'hebegurt', label: 'Hebegurt'),
    Option(id: 'gehstock', label: 'Gehstock'),
    Option(id: 'badewannenlift', label: 'Badewannenlift'),
    Option(id: 'treppenlift', label: 'Treppenlift'),
    Option(id: 'lift', label: 'Lift'),
  ];

  static const List<Option> krankheiten = [
    Option(id: 'alzheimer_demenz', label: 'Alzheimer / Demencja'),
    Option(id: 'ms', label: 'Stwardnienie rozsiane'),
    Option(id: 'parkinson', label: 'Parkinson'),
    Option(id: 'diabetes', label: 'Cukrzyca'),
    Option(id: 'hoerprobleme', label: 'Problemy ze słuchem'),
    Option(id: 'sehprobleme', label: 'Problemy z widzeniem'),
    Option(id: 'sprachprobleme', label: 'Problemy z mówieniem'),
    Option(id: 'durchblutung', label: 'Schorzenie krążenia'),
    Option(id: 'dauerkatheter', label: 'Cewnik stały'),
    Option(id: 'tumor', label: 'Guz'),
    Option(id: 'asthma', label: 'Astma'),
    Option(id: 'dekubitus', label: 'Odleżyny'),
    Option(id: 'schlaganfall', label: 'Udar mózgu'),
    Option(id: 'hochdruck', label: 'Nadciśnienie'),
    Option(id: 'bettgebunden', label: 'Przykutany do łóżka'),
  ];

  static const List<Option> hausarbeiten = [
    Option(id: 'kochen', label: 'Gotowanie'),
    Option(id: 'waschen', label: 'Mycie / Pranie'),
    Option(id: 'essenvorbereiten', label: 'Przyg. jedzenia'),
    Option(id: 'aufraeumen', label: 'Ogólne porządki'),
    Option(id: 'gartenarbeiten', label: 'Prace w ogrodzie'),
    Option(id: 'haustiere', label: 'Opieka nad zwierzętami'),
    Option(id: 'fensterputzen', label: 'Czyszczenie okien'),
    Option(id: 'einkaufen', label: 'Robienie zakupów'),
  ];

  static const List<Option> hilfsarbeiten = [
    Option(id: 'toilettegang', label: 'Wyjście do toalety'),
    Option(id: 'anziehen', label: 'Ubieranie / Rozbieranie'),
    Option(id: 'arztbesuche', label: 'Wizyty u lekarza'),
    Option(id: 'mundhygiene', label: 'Higiena ustna'),
    Option(id: 'baden', label: 'Kąpanie'),
    Option(id: 'nachtarbeiten', label: 'Opieka w nocy'),
    Option(id: 'rauchen', label: 'Niepaląca osoba'),
  ];

  static const List<Option> zimmerausstattung = [
    Option(id: 'internet', label: 'Internet'),
    Option(id: 'fernseher', label: 'Telewizja'),
    Option(id: 'eigenesBad', label: 'Własna łazienka'),
    Option(id: 'fahrrad', label: 'Rower'),
    Option(id: 'auto', label: 'Auto'),
    Option(id: 'guteVerbindung', label: 'Dobra komunikacja miejska'),
  ];

  static const List<Option> medikamenteVerteilung = [
    Option(id: 'familie', label: 'Rodzina rozdziela'),
    Option(id: 'pflegedienst', label: 'Pflegedienst rozdziela'),
  ];

  static const List<Option> toilettenGang = [
    Option(id: 'allein', label: 'Samemu'),
    Option(id: 'mit_hilfe', label: 'Z pomocą opiekuna'),
    Option(id: 'inkontinenz', label: 'Inkontynencja (nietrzymanie moczu)'),
    Option(id: 'stuhlinkontinenz', label: 'Inkontynencja kałowa'),
    Option(id: 'pampers', label: 'Pampersy / Wkładki'),
    Option(id: 'toilettenstuhl', label: 'Krzesło toaletower (Toilettenstuhl)'),
    Option(id: 'katheter', label: 'Cewnik'),
    Option(id: 'stoma', label: 'Stomia'),
  ];

  static String findLabel(List<Option> list, String id) {
    return list.firstWhere((opt) => opt.id == id, orElse: () => Option(id: id, label: id)).label;
  }
}