import 'package:flutter/material.dart';
import '../../models/calendar_event.dart';
import '../../models/betreuer.dart';
import '../../models/kunde.dart';

class AddEventDialog extends StatefulWidget {
  final List<Betreuer> betreuerList;
  final List<Kunde> kundeList;
  final DateTime? initialDate;
  final EventType? initialType;

  const AddEventDialog({
    super.key,
    required this.betreuerList,
    required this.kundeList,
    this.initialDate,
    this.initialType,
  });

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  EventType _selectedType = EventType.survey;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _customPersonController = TextEditingController();

  String? _selectedPersonId;
  bool _isNewPerson = false; // Czy osoba jest spoza bazy (niezapisana)
  Color _selectedColor = Colors.orange.shade800;

  final List<Color> _palette = [
    Colors.orange.shade800,
    Colors.deepPurple,
    Colors.blueAccent.shade700,
    Colors.teal.shade700,
    Colors.pinkAccent.shade700,
    Colors.redAccent.shade700,
    Colors.green.shade700,
    Colors.indigo.shade700,
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedType = widget.initialType ?? EventType.survey;
    _applyDefaults(_selectedType);
  }

  void _applyDefaults(EventType type) {
    _selectedType = type;
    _isNewPerson = false;
    _customPersonController.clear();

    if (type == EventType.survey) {
      _titleController.text = 'Ankieta z opiekunką';
      _selectedColor = Colors.orange.shade800;
      _selectedPersonId = widget.betreuerList.isNotEmpty ? widget.betreuerList.first.id : null;
    } else if (type == EventType.meeting) {
      _titleController.text = 'Spotkanie z rodziną';
      _selectedColor = Colors.deepPurple;
      _selectedPersonId = widget.kundeList.isNotEmpty ? widget.kundeList.first.id : null;
    } else {
      _titleController.clear();
      _selectedColor = Colors.blueAccent.shade700;
      _selectedPersonId = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _customPersonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Nowy termin w kalendarzu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Segmented switch wyboru typu
            SegmentedButton<EventType>(
              segments: const [
                ButtonSegment(
                  value: EventType.survey,
                  label: Text('Ankieta', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.assignment_ind_outlined, size: 16),
                ),
                ButtonSegment(
                  value: EventType.meeting,
                  label: Text('Spotkanie', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.groups_outlined, size: 16),
                ),
                ButtonSegment(
                  value: EventType.custom,
                  label: Text('Własny', style: TextStyle(fontSize: 12)),
                  icon: Icon(Icons.edit_calendar_outlined, size: 16),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) => setState(() => _applyDefaults(set.first)),
            ),
            const SizedBox(height: 16),

            // Tytuł
            const Text('Tytuł wydarzenia', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: _selectedType == EventType.custom ? 'np. Telefon z biurem, Wizyta' : 'Tytuł',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // SEKCJA OSOBY DLA ANKIETY LUB SPOTKANIA
            if (_selectedType == EventType.survey || _selectedType == EventType.meeting) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedType == EventType.survey ? 'Kandydat / Opiekun' : 'Rodzina / Podopieczny',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(_isNewPerson ? Icons.list_alt : Icons.person_add_alt, size: 16),
                    label: Text(
                      _isNewPerson ? 'Wybierz z listy' : 'Wpisz nową osobę',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPerson = !_isNewPerson;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (_isNewPerson) ...[
                // Pole tekstowe dla nowej osoby (bez zapisywania w profilach)
                TextField(
                  controller: _customPersonController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_add_outlined, color: Colors.blueAccent),
                    hintText: _selectedType == EventType.survey
                        ? 'Imię i nazwisko nowej kandydatki (np. Anna Nowak)'
                        : 'Nazwisko rodziny / podopiecznego (np. Rodzina Schmidt)',
                    helperText: 'Osoba nie zostanie dodana do bazy danych aplikacji',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ] else ...[
                // Dropdown z istniejącej bazy
                if (_selectedType == EventType.survey)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedPersonId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.betreuerList.map((b) {
                      return DropdownMenuItem(
                        value: b.id,
                        child: Text('${b.vorname} ${b.name}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPersonId = val),
                  )
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedPersonId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.personal_injury_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: widget.kundeList.map((k) {
                      return DropdownMenuItem(
                        value: k.id,
                        child: Text('${k.vorname} ${k.name}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPersonId = val),
                  ),
              ],
              const SizedBox(height: 14),
            ],

            // Data i Godzina
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Data', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Godzina', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(_selectedTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Kolor kropki
            const Text('Kolor kropki w kalendarzu', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _palette.map((col) {
                final isSelected = _selectedColor.value == col.value;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = col),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.white,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: col.withValues(alpha: 0.45),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Notatka
            const Text('Notatka / Szczegóły (opcjonalnie)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                hintText: 'np. numer telefonu, pytania, oczekiwana stawka...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Zapis
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check),
                label: const Text('Zapisz termin', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Podaj tytuł wydarzenia!')),
                    );
                    return;
                  }

                  String? pName;
                  String? pId;

                  if (_isNewPerson) {
                    // Osoba jednorazowa, niezapisana w bazie
                    final typedName = _customPersonController.text.trim();
                    pName = typedName.isNotEmpty ? typedName : null;
                    pId = null;
                  } else {
                    // Osoba z bazy
                    pId = _selectedPersonId;
                    if (_selectedType == EventType.survey && _selectedPersonId != null) {
                      final b = widget.betreuerList.cast<Betreuer?>().firstWhere(
                        (item) => item?.id == _selectedPersonId,
                        orElse: () => null,
                      );
                      if (b != null) pName = '${b.vorname} ${b.name}';
                    } else if (_selectedType == EventType.meeting && _selectedPersonId != null) {
                      final k = widget.kundeList.cast<Kunde?>().firstWhere(
                        (item) => item?.id == _selectedPersonId,
                        orElse: () => null,
                      );
                      if (k != null) pName = '${k.vorname} ${k.name}';
                    }
                  }

                  final eventDate = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );

                  final newEvent = CalendarEvent(
                    id: 'event_${DateTime.now().millisecondsSinceEpoch}',
                    title: _titleController.text.trim(),
                    description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                    date: eventDate,
                    type: _selectedType,
                    relatedPersonId: pId,
                    relatedPersonName: pName,
                    colorValue: _selectedColor.value,
                  );

                  Navigator.pop(context, newEvent);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}