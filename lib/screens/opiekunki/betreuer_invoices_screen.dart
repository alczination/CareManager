import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/betreuer.dart';
import '../../models/rechnung.dart';
import '../../services/invoice_pdf_service.dart';
import 'betreuer_invoices_create_dialog.dart';

class BetreuerInvoicesScreen extends StatefulWidget {
  final Betreuer betreuer;
  const BetreuerInvoicesScreen({super.key, required this.betreuer});

  @override
  State<BetreuerInvoicesScreen> createState() => _BetreuerInvoicesScreenState();
}

class _BetreuerInvoicesScreenState extends State<BetreuerInvoicesScreen> {
  List<InvoiceData> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  String get _storageKey => 'invoices_${widget.betreuer.id}';

  Future<void> _loadInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      setState(() {
        _invoices = decoded.map((e) => InvoiceData.fromJson(e)).toList();
        _sortInvoices();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _sortInvoices() {
    _invoices.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });
  }

  Future<void> _saveInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _invoices.map((i) => i.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> _deleteInvoice(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń rachunek'),
        content: const Text('Czy na pewno chcesz usunąć ten rachunek?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _invoices.removeAt(index);
      });
      await _saveInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rachunek został usunięty')),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Styczeń / Januar',
      'Luty / Februar',
      'Marzec / März',
      'Kwiecień / April',
      'Maj / Mai',
      'Czerwiec / Juni',
      'Lipiec / Juli',
      'Sierpień / August',
      'Wrzesień / September',
      'Październik / Oktober',
      'Listopad / November',
      'Grudzień / Dezember'
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  Future<void> _openCreateInvoiceDialog() async {
    final newInvoice = await Navigator.push<InvoiceData>(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceCreateDialog(betreuer: widget.betreuer),
      ),
    );

    if (newInvoice != null) {
      setState(() {
        _invoices.add(newInvoice);
        _sortInvoices();
      });
      await _saveInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Rachunki: ${widget.betreuer.vorname} ${widget.betreuer.name}'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Brak zapisanych rachunków',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Wystaw pierwszy rachunek'),
                        onPressed: _openCreateInvoiceDialog,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _invoices.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final inv = _invoices[index];
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.receipt,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          '${_getMonthName(inv.month)} ${inv.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Okres: ${inv.period}'),
                            Text(
                              'Kwota: ${inv.totalSum.toStringAsFixed(2)} €',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.blue),
                              tooltip: 'Drukuj / Pobierz PDF',
                              onPressed: () => InvoicePdfService.generateAndPrintInvoice(inv),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Usuń',
                              onPressed: () => _deleteInvoice(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nowy rachunek',
        onPressed: _openCreateInvoiceDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}