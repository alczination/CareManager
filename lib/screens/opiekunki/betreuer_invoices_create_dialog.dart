import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/betreuer.dart';
import '../../models/rechnung.dart';
import '../../services/invoice_pdf_service.dart';

class InvoiceCreateDialog extends StatefulWidget {
  final Betreuer betreuer;
  const InvoiceCreateDialog({super.key, required this.betreuer});

  @override
  State<InvoiceCreateDialog> createState() => _InvoiceCreateDialogState();
}

class _InvoiceCreateDialogState extends State<InvoiceCreateDialog> {
  DateTimeRange? _selectedDateRange;

  final TextEditingController _dailyRateController = TextEditingController(text: '65.00');
  bool _includeInsurance = false;
  final TextEditingController _insuranceController = TextEditingController(text: '100.00');
  bool _includeLanguage = false;
  final TextEditingController _languageController = TextEditingController(text: '100.00');
  bool _includeNightShifts = false;
  final TextEditingController _nightCountController = TextEditingController(text: '1');
  final TextEditingController _nightRateController = TextEditingController(text: '10.00');
  bool _includeTravelCosts = false;
  final TextEditingController _travelCostsController = TextEditingController(text: '300.00');
  bool _includeMedical = false;
  final TextEditingController _medicalCostsController = TextEditingController(text: '100.00');
  bool _includeHoliday = false;
  final TextEditingController _holidayDaysController = TextEditingController(text: '2.5');
  late final TextEditingController _holidayRateController;


  final List<String> _germanMonths = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
  ];

  int get _calculatedDays {
    if (_selectedDateRange == null) return 0;
    return _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
  }

  double get _currentTotal {
    double total = 0.0;
    final dailyRate = double.tryParse(_dailyRateController.text.replaceAll(',', '.')) ?? 0.0;
    total += _calculatedDays * dailyRate;

    if (_includeInsurance) {
      total += double.tryParse(_insuranceController.text.replaceAll(',', '.')) ?? 0.0;
    }
    if (_includeLanguage) {
      total += double.tryParse(_languageController.text.replaceAll(',', '.')) ?? 0.0;
    }
    if (_includeNightShifts) {
      final nights = int.tryParse(_nightCountController.text) ?? 0;
      final rate = double.tryParse(_nightRateController.text.replaceAll(',', '.')) ?? 0.0;
      total += nights * rate;
    }
    if (_includeTravelCosts) {
      total += double.tryParse(_travelCostsController.text.replaceAll(',', '.')) ?? 0.0;
    }
    if (_includeMedical) {
      total += double.tryParse(_medicalCostsController.text.replaceAll(',', '.')) ?? 0.0;
    }
    if (_includeHoliday) {
      final days = double.tryParse(_holidayDaysController.text.replaceAll(',', '.')) ?? 0.0;
      final rate = double.tryParse(_holidayRateController.text.replaceAll(',', '.')) ?? 0.0;
      total += days * rate;
    }

    return total;
  }

  @override
  void initState() {
    super.initState();
    _holidayRateController = TextEditingController(text: _dailyRateController.text);
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _insuranceController.dispose();
    _languageController.dispose();
    _nightCountController.dispose();
    _nightRateController.dispose();
    _travelCostsController.dispose();
    _medicalCostsController.dispose();
    _holidayDaysController.dispose();
    _holidayRateController.dispose();
    super.dispose();
  }

  InvoiceData? _buildInvoiceData() {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz zakres dat pracy')),
      );
      return null;
    }

  final startDate = _selectedDateRange!.start;
  final endDate = _selectedDateRange!.end;
  final days = _calculatedDays;
  final dailyRate = double.tryParse(_dailyRateController.text.replaceAll(',', '.')) ?? 0.0;
  final dateFormat = DateFormat('dd.MM.');
  final periodString = '${dateFormat.format(startDate)} – ${DateFormat('dd.MM.yyyy').format(endDate)}';  
  final monthName = _germanMonths[startDate.month - 1];
  final List<InvoiceItem> items = [];

  items.add(
    InvoiceItem(
      title: monthName,
      calculation: '$days Tage * ${dailyRate.toStringAsFixed(2).replaceAll('.', ',')}',
      total: days * dailyRate,
    ),
  );

  if (_includeInsurance) {
    final ins = double.tryParse(_insuranceController.text.replaceAll(',', '.')) ?? 0.0;
    if (ins > 0) items.add(InvoiceItem(title: 'Versicherung', total: ins));
  }

  if (_includeLanguage) {
    final lang = double.tryParse(_languageController.text.replaceAll(',', '.')) ?? 0.0;
    if (lang > 0) items.add(InvoiceItem(title: 'Sprache', total: lang));
  }

  if (_includeNightShifts) {
    final nights = int.tryParse(_nightCountController.text) ?? 0;
    final rate = double.tryParse(_nightRateController.text.replaceAll(',', '.')) ?? 0.0;
    if (nights > 0 && rate > 0) {
      items.add(
        InvoiceItem(
          title: 'Nachtaufstehen',
          calculation: '$nights ${nights == 1 ? "Nacht" : "Nächte"} * ${rate.toStringAsFixed(2).replaceAll('.', ',')}',
          total: nights * rate,
        ),
      );
    }
  }

  if (_includeTravelCosts) {
    final travel = double.tryParse(_travelCostsController.text.replaceAll(',', '.')) ?? 0.0;
    if (travel > 0) items.add(InvoiceItem(title: 'Fahrtkosten', total: travel));
  }

  if (_includeMedical) {
    final med = double.tryParse(_medicalCostsController.text.replaceAll(',', '.')) ?? 0.0;
    if (med > 0) items.add(InvoiceItem(title: 'Mediz. Erfahrung', total: med));
  }

  if (_includeHoliday) {
    final days = double.tryParse(_holidayDaysController.text.replaceAll(',', '.')) ?? 0.0;
    final rate = double.tryParse(_holidayRateController.text.replaceAll(',', '.')) ?? 0.0;
    if (days > 0 && rate > 0) {
      final daysFormatted = days.toString().replaceAll('.', ',');
      final rateFormatted = rate.toString().replaceAll('.', ',');
      items.add(
        InvoiceItem(
          title: 'Urlaubsabgeltung',
          calculation: '$daysFormatted Tage * $rateFormatted',
          total: days * rate,
        ),
      );
    }
  }

  return InvoiceData(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    betreuerId: widget.betreuer.id,
    caregiverName: '${widget.betreuer.vorname} ${widget.betreuer.name}',
    period: periodString,
    month: startDate.month,
    year: startDate.year,
    createdAt: DateTime.now(),
    items: items,
  );
}

@override
Widget build(BuildContext context) {
  final dateFormat = DateFormat('dd.MM.yyyy');
  return Scaffold(
    backgroundColor: Colors.grey.shade100,
    appBar: AppBar(
      title: const Text('Wystaw rachunek'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Okres pracy (Beschäftigungsdauer)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context, 
                      firstDate: DateTime(2020), 
                      lastDate: DateTime(2035),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() => _selectedDateRange = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDateRange == null ? 'Wybierz zakres dat' 
                          : '${dateFormat.format(_selectedDateRange!.start)} – ${dateFormat.format(_selectedDateRange!.end)} ($_calculatedDays dni)',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedDateRange == null ? Colors.grey.shade600 : Colors.black87,
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _dailyRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Stawka dzienna (€)',
                  suffixText: '€',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              ],
            ),
            ),
        ),
      const SizedBox(height: 16),
      Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dodatki do rachunku', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(height: 24),

              SwitchListTile(
                title: const Text('Ubezpieczenie (Versicherung)'),
                value: _includeInsurance, 
                onChanged: (val) => setState(() => _includeInsurance = val),
                contentPadding: EdgeInsets.zero,
              ),

              if (_includeInsurance)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _insuranceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kwota ubezpieczenia',
                      suffixText: '€',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

                SwitchListTile(
                title: const Text('Dodatek językowy (Sprache)'),
                value: _includeLanguage, 
                onChanged: (val) => setState(() => _includeLanguage = val),
                contentPadding: EdgeInsets.zero,
              ),

              if (_includeLanguage)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _languageController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kwota za język',
                      suffixText: '€',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

                  SwitchListTile(
                title: const Text('Doświadczenie medyczne (Medizinische Erfahrung)'),
                value: _includeMedical, 
                onChanged: (val) => setState(() => _includeMedical = val),
                contentPadding: EdgeInsets.zero,
              ),

              if (_includeMedical)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _medicalCostsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kwota dodatku medycznego',
                      suffixText: '€',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

                SwitchListTile(
                title: const Text('Wstawanie nocne (Nachtzuschlag)'),
                value: _includeNightShifts, 
                onChanged: (val) => setState(() => _includeNightShifts = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (_includeNightShifts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nightCountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Liczba nocek',
                            border: OutlineInputBorder(),
                            isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nightRateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Stawka za nockę',
                          suffixText: '€',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],  
                ),
              ),

                SwitchListTile(
                title: const Text('Koszty podróży (Fahrtkosten)'),
                value: _includeTravelCosts, 
                onChanged: (val) => setState(() => _includeTravelCosts = val),
                contentPadding: EdgeInsets.zero,
              ),
              if (_includeTravelCosts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _travelCostsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Kwota zwrotu za dojazd',
                      suffixText: '€',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),

                SwitchListTile(
                  title: const Text('Urlop (Urlaubsabgeltung)'),
                  subtitle: const Text('2,5 dnia urlopu / miesiąc'),
                  value: _includeHoliday,
                  onChanged: (val) {
                    setState(() {
                      _includeHoliday = val;
                      if (_includeHoliday && _holidayRateController.text.isEmpty) {
                        _holidayRateController.text = _dailyRateController.text;
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (_includeHoliday)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _holidayDaysController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Liczba dni',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _holidayRateController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Stawka / dzień',
                                  suffixText: '€',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ActionChip(
                              label: const Text('1 msc (2.5 d)'),
                              onPressed: () {
                                setState(() { 
                                  _holidayDaysController.text = '2.5';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: const Text('2 msc (5.0 d)'),
                              onPressed: () {
                                setState(() {
                                  _holidayDaysController.text = '5.0';
                                }); 
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Łączna suma: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${_currentTotal.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final invoice = _buildInvoiceData();
                if (invoice != null) {
                  await InvoicePdfService.generateAndPrintInvoice(invoice);
                }
              },
              child: const Text('Drukuj (bez zapisu)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final invoice = _buildInvoiceData();
                if (invoice != null) {
                  await InvoicePdfService.generateAndPrintInvoice(invoice);
                  if (context.mounted) {
                    Navigator.pop(context, invoice);
                  }
                }
              },
              child: const Text('Zapisz i drukuj'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      ],
    ),
  );
}
}