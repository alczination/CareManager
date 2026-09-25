import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/rechnung.dart';

class InvoicePdfService {
  static Future<void> generateAndPrintInvoice(InvoiceData invoice) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final currencyFormat = NumberFormat('#,##0.00', 'de_DE');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 55, vertical: 60),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                invoice.caregiverName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 35),
              pw.Text(
                'Beschäftigungsdauer: ${invoice.period}',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 45),
              ...invoice.items.map((InvoiceItem item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          item.title,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ),
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          item.calculation ?? '',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          '${currencyFormat.format(item?.total ?? 0.0)}€',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.5, color: PdfColors.black),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  '${currencyFormat.format(invoice.totalSum)}€',
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Unterschrift des Arbeitgebers',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 45),
                      pw.Container(
                        width: 170,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.black,
                              width: 0.8,
                              style: pw.BorderStyle.dashed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Unterschrift des Arbeitnehmers',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 45),
                      pw.Container(
                        width: 170,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.black,
                              width: 0.8,
                              style: pw.BorderStyle.dashed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 15),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'Rachunek_${invoice.caregiverName.replaceAll(' ', '_')}_${invoice.period.replaceAll(' ', '')}.pdf',
    );
  }
}