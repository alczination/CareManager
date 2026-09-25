import '../models/betreuer.dart';
import '../models/kunde.dart';
import '../models/turnus.dart';

class TurnusValidationIssue {
  final String message;
  final bool isSevere;

  TurnusValidationIssue({
    required this.message,
    this.isSevere = false,
  });
}

class TurnusValidator {
  static int _germanLevelWeight(String? level) {
    if (level == null) return 0;
    final l = level.trim().toLowerCase();
    if (l.contains('biegła') || l.contains('bardzo dobra') || l.contains('c1') || l.contains('c2')) return 4;
    if (l.contains('dobra') || l.contains('gut') || l.contains('b2')) return 3;
    if (l.contains('komunikatywna') || l.contains('mittel') || l.contains('b1')) return 2;
    if (l.contains('podstawowa') || l.contains('grund') || l.contains('a1') || l.contains('a2')) return 1;
    return 0;
  }

  static List<TurnusValidationIssue> validate({
    required Betreuer? betreuer,
    required Kunde? kunde,
    required DateTime? startDate,
    required DateTime? endDate,
    required List<Turnus> existingTurnusy,
    String? currentTurnusId,
  }) {
    final issues = <TurnusValidationIssue>[];
    if (betreuer == null || kunde == null || startDate == null || endDate == null) {
      return issues;
    }

    final durationInDays = endDate.difference(startDate).inDays + 1;

    // 1. Preferencje językowe
    final bLangWeight = _germanLevelWeight(betreuer.deutschKenntnisse);
    final kReqLang = kunde.deutschKenntnisse;
    if (kReqLang != null && kReqLang.isNotEmpty) {
      final kLangWeight = _germanLevelWeight(kReqLang);
      if (bLangWeight < kLangWeight) {
        issues.add(TurnusValidationIssue(
          message: 'Brak wymaganego poziomu języka (Podopieczny wymaga: $kReqLang, Opiekun: ${betreuer.deutschKenntnisse.isNotEmpty ? betreuer.deutschKenntnisse : "Brak"})',
        ));
      }
    }

    // 2. Preferencje płci (Podopieczny -> Opiekun)
    final kPrefSex = kunde.betreuungGeschlecht.toLowerCase().trim();
    final bSex = betreuer.geschlecht.toLowerCase().trim();
    if (kPrefSex.isNotEmpty && !kPrefSex.contains('obojętn')) {
      final bIsMale = bSex.startsWith('m');
      final kWantsFemale = kPrefSex.contains('kobieta');
      final kWantsMale = kPrefSex.contains('mężczyzna');
      if ((kWantsFemale && bIsMale) || (kWantsMale && !bIsMale)) {
        issues.add(TurnusValidationIssue(
          message: 'Podopieczny ma inne preferencje co do płci opiekuna (Preferuje: ${kunde.betreuungGeschlecht})',
        ));
      }
    }

    // 3. Preferencje płci (Opiekun -> Podopieczny)
    final bPrefSex = betreuer.betreuungGeschlecht.toLowerCase().trim();
    final kSex = kunde.geschlecht.toLowerCase().trim();
    if (bPrefSex.isNotEmpty && !bPrefSex.contains('obojętn')) {
      final kIsMale = kSex.startsWith('m');
      final bWantsFemale = bPrefSex.contains('kobieta');
      final bWantsMale = bPrefSex.contains('mężczyzna');
      if ((bWantsFemale && kIsMale) || (bWantsMale && !kIsMale)) {
        issues.add(TurnusValidationIssue(
          message: 'Opiekun ma inne preferencje co do płci osoby do opieki (Preferuje: ${betreuer.betreuungGeschlecht})',
        ));
      }
    }

    // 4. Wymagane prawo jazdy i gotowość do prowadzenia auta
    final kNeedsDriver = kunde.fuehrerschein;
    if (kNeedsDriver) {
      if (!betreuer.fuehrerschein) {
        issues.add(TurnusValidationIssue(
          message: 'Podopieczny wymaga prawa jazdy (Opiekun nie posiada prawa jazdy)',
        ));
      } else if (!betreuer.bereitFuehrerschein) {
        issues.add(TurnusValidationIssue(
          message: 'Podopieczny wymaga prawa jazdy i gotowości do jazdy (Opiekun ma prawo jazdy, lecz deklaruje brak gotowości do prowadzenia)',
        ));
      }
    }

    // 5. Wymóg osoby niepalącej
    final kNonSmoking = kunde.raucher;
    if (kNonSmoking && betreuer.raucher) {
      issues.add(TurnusValidationIssue(
        message: 'Podopieczny wymaga osoby niepalącej (Opiekun jest osobą palącą)',
      ));
    }

    // 6. Opieka nad dwiema osobami
    final isDoubleCare = kunde.betreuungZweiPersonen;
    if (isDoubleCare && !betreuer.betreuungZweiPersonen) {
      issues.add(TurnusValidationIssue(
        message: 'Opiekun nie chce się opiekować dwoma osobami (Podopieczny wymaga opieki nad dwoma osobami)',
      ));
    }

    // 7. Zwierzęta
    final hasPets = kunde.betreuungHaustiere;
    if (hasPets && !betreuer.betreuungHaustiere) {
      issues.add(TurnusValidationIssue(
        message: 'Opiekun nie chce się opiekować zwierzętami (Podopieczny wymaga opieki nad zwierzętami)',
      ));
    }

    // 8. Opieka nocna (weryfikacja na podstawie notatek lub flagi w modelu)
    final kNeedsNight = kunde.notizen.toLowerCase().contains('noc') || kunde.notizen.toLowerCase().contains('nocna');
    final bNoNight = betreuer.notizen?.toLowerCase().contains('bez nocy') == true ||
        betreuer.notizen?.toLowerCase().contains('nie wstaje w nocy') == true;
    if (kNeedsNight && bNoNight) {
      issues.add(TurnusValidationIssue(
        message: 'Podopieczny wymaga opieki w nocy, a opiekun deklaruje brak gotowości do pracy nocnej',
      ));
    }

    // 9. Długość wyjazdu (Cykle opiekuna)
    if (betreuer.betreuungsZyklen.isNotEmpty) {
      bool matchesCycle = false;
      for (final cycle in betreuer.betreuungsZyklen) {
        final cLower = cycle.toLowerCase();
        if (cLower.contains('1 m') && (durationInDays >= 25 && durationInDays <= 35)) matchesCycle = true;
        if (cLower.contains('2 m') && (durationInDays >= 50 && durationInDays <= 70)) matchesCycle = true;
        if (cLower.contains('3 m') && (durationInDays >= 80 && durationInDays <= 100)) matchesCycle = true;
        if (cLower.contains('dowoln')) matchesCycle = true;
      }
      if (!matchesCycle) {
        issues.add(TurnusValidationIssue(
          message: 'Opiekun z reguły wyjeżdża na inny okres ($durationInDays dni nie wpisuje się w preferencje: ${betreuer.betreuungsZyklen.join(", ")})',
        ));
      }
    }

    // 10. Opiekun na innym zleceniu w tym terminie
    final otherTurnusyBetreuer = existingTurnusy.where((t) {
      if (t.id == currentTurnusId) return false;
      return t.betreuerId == betreuer.id ||
          t.betreuerName.trim().toLowerCase() == '${betreuer.vorname} ${betreuer.name}'.trim().toLowerCase();
    }).toList();

    for (final other in otherTurnusyBetreuer) {
      final overlap = !startDate.isAfter(other.endDate) && !endDate.isBefore(other.startDate);
      if (overlap) {
        issues.add(TurnusValidationIssue(
          isSevere: true,
          message: 'Opiekun w wybranym okresie jest na innym zleceniu (${other.kundeName}: ${_formatDate(other.startDate)} – ${_formatDate(other.endDate)})',
        ));
      }
    }

    // 11. Podopieczny posiada już opiekunkę (tolerancja na zmianę turnusu <= 3 dni)
    final otherTurnusyKunde = existingTurnusy.where((t) {
      if (t.id == currentTurnusId) return false;
      return t.kundeId == kunde.id ||
          t.kundeName.trim().toLowerCase() == '${kunde.vorname} ${kunde.name}'.trim().toLowerCase();
    }).toList();

    for (final other in otherTurnusyKunde) {
      final overlapStart = startDate.isAfter(other.startDate) ? startDate : other.startDate;
      final overlapEnd = endDate.isBefore(other.endDate) ? endDate : other.endDate;
      if (!overlapStart.isAfter(overlapEnd)) {
        final overlapDays = overlapEnd.difference(overlapStart).inDays + 1;
        if (overlapDays > 3) {
          issues.add(TurnusValidationIssue(
            isSevere: true,
            message: 'Podopieczny posiada już opiekunkę w tym okresie (Kolizja $overlapDays dni z: ${other.betreuerName})',
          ));
        }
      }
    }

    return issues;
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}