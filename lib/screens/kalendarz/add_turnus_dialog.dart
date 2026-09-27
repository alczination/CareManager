import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/betreuer.dart';
import '../../models/kunde.dart';
import '../../models/turnus.dart';
import '../../services/turnus_validator.dart';

class AddTurnusDialog extends StatefulWidget {
  final List<Betreuer> betreuerList;
  final List<Kunde> kundeList;
  final DateTime? initialDate;
  final Turnus? turnusToEdit;

  const AddTurnusDialog({
    super.key,
    required this.betreuerList,
    required this.kundeList,
    this.initialDate,
    this.turnusToEdit,
  });

  @override
  State<AddTurnusDialog> createState() => _AddTurnusDialogState();
}

class _AddTurnusDialogState extends State<AddTurnusDialog> {
  String? _selectedBetreuerId;
  String? _selectedKundeId;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _notizController = TextEditingController();

  List<Turnus> _allExistingTurnusy = [];
  bool get isEditing => widget.turnusToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadExistingTurnusy();

    if (isEditing) {
      final t = widget.turnusToEdit!;
      _selectedDateRange = DateTimeRange(start: t.startDate, end: t.endDate);
      _notizController.text = t.notiz ?? '';
      _selectedBetreuerId = t.betreuerId;
      _selectedKundeId = t.kundeId;
    } else {
      final start = widget.initialDate ?? DateTime.now();
      _selectedDateRange = DateTimeRange(
        start: DateTime(start.year, start.month, start.day),
        end: DateTime(start.year, start.month, start.day).add(const Duration(days: 30)),
      );

      if (widget.betreuerList.isNotEmpty) {
        _selectedBetreuerId = widget.betreuerList.first.id;
      }
      if (widget.kundeList.isNotEmpty) {
        _selectedKundeId = widget.kundeList.first.id;
      }
    }
  }

  Future<void> _loadExistingTurnusy() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('turnus_database_v1');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        setState(() {
          _allExistingTurnusy = decoded.map((e) => Turnus.fromJson(e)).toList();
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _notizController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      helpText: 'Wybierz czas trwania wyjazdu',
      confirmText: 'Zatwierdź',
      cancelText: 'Anuluj',
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final daysCount = _selectedDateRange != null
        ? _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1
        : 0;

    final betreuerMatch = widget.betreuerList.cast<Betreuer?>().firstWhere(
          (b) => b?.id == _selectedBetreuerId,
          orElse: () => null,
        );

    final kundeMatch = widget.kundeList.cast<Kunde?>().firstWhere(
          (k) => k?.id == _selectedKundeId,
          orElse: () => null,
        );

    // Dynamiczna walidacja w locie
    final validationIssues = TurnusValidator.validate(
      betreuer: betreuerMatch,
      kunde: kundeMatch,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      existingTurnusy: _allExistingTurnusy,
      currentTurnusId: widget.turnusToEdit?.id,
    );

    final betreuerItems = widget.betreuerList.map((b) {
      return DropdownMenuItem<String>(
        value: b.id,
        child: Text('${b.vorname} ${b.name}', overflow: TextOverflow.ellipsis),
      );
    }).toList();

    if (isEditing &&
        _selectedBetreuerId != null &&
        !widget.betreuerList.any((b) => b.id == _selectedBetreuerId)) {
      betreuerItems.add(
        DropdownMenuItem<String>(
          value: _selectedBetreuerId,
          child: Text(widget.turnusToEdit!.betreuerName, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    final kundeItems = widget.kundeList.map((k) {
      final extra = k.anschrift.isNotEmpty ? ' (${k.anschrift})' : '';
      return DropdownMenuItem<String>(
        value: k.id,
        child: Text('${k.vorname} ${k.name}$extra', overflow: TextOverflow.ellipsis),
      );
    }).toList();

    if (isEditing &&
        _selectedKundeId != null &&
        !widget.kundeList.any((k) => k.id == _selectedKundeId)) {
      kundeItems.add(
        DropdownMenuItem<String>(
          value: _selectedKundeId,
          child: Text(widget.turnusToEdit!.kundeName, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edytuj wyjazd' : 'Zaplanuj nowy wyjazd',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // 1. Opiekun
            const Text('Opiekun / Opiekunka', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedBetreuerId,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: betreuerItems,
              onChanged: (val) => setState(() => _selectedBetreuerId = val),
            ),
            const SizedBox(height: 16),

            // 2. Podopieczny
            const Text('Podopieczny (Klient)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedKundeId,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.personal_injury_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: kundeItems,
              onChanged: (val) => setState(() => _selectedKundeId = val),
            ),
            if (kundeMatch != null) ...[
              const SizedBox(height: 6),
              Builder(builder: (context) {
                final bedarf = kundeMatch.datumBedarf;
                final hasBedarf = bedarf != null && bedarf.trim().isNotEmpty;
                final isImmediate = !hasBedarf ||
                  bedarf.toLowerCase().contains('zaraz') ||
                  bedarf.toLowerCase().contains('sofort');
                final badgeColor = isImmediate ? Colors.deepOrange : Colors.deepPurple;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isImmediate ? Icons.bolt : Icons.event_available,
                        size: 16,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isImmediate ? 'Opieka potrzebna: Od zaraz' : 'Opieka potrzebana od: $bedarf',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: badgeColor.shade800,
                          ),
                        ),
                      ),
                      if (hasBedarf && !isImmediate)
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Colors.deepPurple.shade900,
                          ),
                          onPressed: () {
                            try {
                              final parts = bedarf.split('.');
                              if (parts.length == 3) {
                                final d = int.parse(parts[0]);
                                final m = int.parse(parts[1]);
                                final y = int.parse(parts[2]);
                                final newStart = DateTime(y, m, d);
                                setState(() {
                                  _selectedDateRange = DateTimeRange(
                                    start: newStart,
                                    end: newStart.add(Duration(days: daysCount > 0 ? daysCount - 1 : 30)),
                                  );
                                });
                              }
                            } catch (_) {}
                          },
                          child: const Text(
                            'Ustaw jako start',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            // 3. Zakres dat
            const Text('Czas trwania wyjazdu', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedDateRange != null
                                ? '${_formatDate(_selectedDateRange!.start)} – ${_formatDate(_selectedDateRange!.end)}'
                                : 'Wybierz zakres dat',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_selectedDateRange != null)
                            Text(
                              'Łącznie: $daysCount dni',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === SEKCJA UWAG I KONFLIKTÓW (WALIDACJA W LOCIE) ===
            if (validationIssues.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Uwagi i potencjalne niezgodności (${validationIssues.length}):',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...validationIssues.map((issue) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: issue.isSevere ? Colors.red.shade700 : Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                issue.message,
                                style: TextStyle(
                                  color: issue.isSevere ? Colors.red.shade900 : Colors.brown.shade800,
                                  fontSize: 12,
                                  fontWeight: issue.isSevere ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. Notatka
            const Text('Notatka (opcjonalnie)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _notizController,
              decoration: InputDecoration(
                hintText: 'np. transport busem, stawka świąteczna...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Przycisk Zapisu
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: validationIssues.any((i) => i.isSevere) ? Colors.orange.shade800 : Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(isEditing ? Icons.save : Icons.check),
                label: Text(
                  isEditing ? 'Zapisz zmiany' : 'Zatwierdź wyjazd',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  if (_selectedBetreuerId == null ||
                      _selectedKundeId == null ||
                      _selectedDateRange == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Wypełnij wszystkie pola!')),
                    );
                    return;
                  }

                  String bName = widget.turnusToEdit?.betreuerName ?? '';
                  if (betreuerMatch != null) {
                    bName = '${betreuerMatch.vorname} ${betreuerMatch.name}'.trim();
                  }

                  String kName = widget.turnusToEdit?.kundeName ?? '';
                  if (kundeMatch != null) {
                    kName = '${kundeMatch.vorname} ${kundeMatch.name}'.trim();
                  }

                  final resultTurnus = Turnus(
                    id: isEditing
                        ? widget.turnusToEdit!.id
                        : 'turnus_${DateTime.now().millisecondsSinceEpoch}',
                    betreuerId: _selectedBetreuerId!,
                    betreuerName: bName,
                    kundeId: _selectedKundeId!,
                    kundeName: kName,
                    startDate: DateTime.utc(
                      _selectedDateRange!.start.year,
                      _selectedDateRange!.start.month,
                      _selectedDateRange!.start.day,
                    ),
                    endDate: DateTime.utc(
                      _selectedDateRange!.end.year,
                      _selectedDateRange!.end.month,
                      _selectedDateRange!.end.day,
                    ),
                    notiz: _notizController.text.trim().isEmpty ? null : _notizController.text.trim(),
                  );

                  Navigator.pop(context, resultTurnus);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}