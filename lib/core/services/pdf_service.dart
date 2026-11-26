import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:jantabackery/core/constants/app_settings.dart';
import 'package:jantabackery/core/database/db_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<Uint8List> generateMonthlyReport(DateTime monthDate) async {
    final db = await DBHelper.database;
    final monthPrefix = DateFormat('yyyy-MM').format(monthDate);
    final monthTitle = DateFormat('MMMM yyyy').format(monthDate);
    final generatedDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    final sales = await db.query(
      'sales',
      where: 'date LIKE ?',
      whereArgs: ['$monthPrefix%'],
    );
    final specialOrders = await db.query(
      'special_orders',
      where: 'delivery_date LIKE ?',
      whereArgs: ['$monthPrefix%'],
    );
    final b2bDispatch = await db.query(
      'b2b_cake_dispatch',
      where: 'date LIKE ?',
      whereArgs: ['$monthPrefix%'],
    );
    final expenses = await db.query(
      'expenses',
      where: 'date LIKE ?',
      whereArgs: ['$monthPrefix%'],
    );
    final bakeryParties = await db.query(
      'bakery_parties',
      orderBy: 'bakery_name ASC',
    );

    double cashSales = 0;
    double upiSales = 0;
    final Map<String, Map<String, double>> dayMap = {};

    void ensureDay(String dayKey) {
      dayMap.putIfAbsent(
        dayKey,
            () => {
          'sales': 0,
          'orders': 0,
          'b2b': 0,
          'expense': 0,
        },
      );
    }

    for (final s in sales) {
      final amt = (s['total_amount'] as num? ?? 0).toDouble();
      final mode = (s['payment_mode'] ?? 'Cash').toString().toUpperCase();
      if (mode == 'UPI') {
        upiSales += amt;
      } else {
        cashSales += amt;
      }
      final dayKey = s['date'].toString().length >= 10
          ? s['date'].toString().substring(0, 10)
          : s['date'].toString();
      ensureDay(dayKey);
      dayMap[dayKey]!['sales'] = dayMap[dayKey]!['sales']! + amt;
    }
    final totalCounterSales = cashSales + upiSales;

    double totalSpecialOrders = 0;
    double totalSpecialAdvance = 0;
    for (final o in specialOrders) {
      final amt = (o['total_price'] as num? ?? 0).toDouble();
      final adv = (o['advance_paid'] as num? ?? 0).toDouble();
      totalSpecialOrders += amt;
      totalSpecialAdvance += adv;

      final rawDate = o['delivery_date'].toString();
      final dayKey = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
      ensureDay(dayKey);
      dayMap[dayKey]!['orders'] = dayMap[dayKey]!['orders']! + amt;
    }

    double totalB2bSupply = 0;
    final Map<String, Map<String, dynamic>> flavourSummary = {};
    for (final b in b2bDispatch) {
      final qty = (b['qty'] as num? ?? 0).toInt();
      final rate = (b['price_per_cake'] as num? ?? 0).toDouble();
      final amt = (b['total_amount'] as num? ?? (qty * rate)).toDouble();
      totalB2bSupply += amt;

      final flavour = (b['flavour'] ?? 'Custom').toString();
      final weight = (b['weight'] ?? '').toString();
      final key = weight.isNotEmpty ? '$flavour ($weight)' : flavour;

      flavourSummary.putIfAbsent(
        key,
            () => {
          'flavour': key,
          'qty': 0,
          'rate': rate,
          'total': 0.0,
        },
      );
      flavourSummary[key]!['qty'] = (flavourSummary[key]!['qty'] as int) + qty;
      flavourSummary[key]!['total'] = (flavourSummary[key]!['total'] as double) + amt;

      final dayKey = b['date'].toString().length >= 10
          ? b['date'].toString().substring(0, 10)
          : b['date'].toString();
      ensureDay(dayKey);
      dayMap[dayKey]!['b2b'] = dayMap[dayKey]!['b2b']! + amt;
    }

    double totalExpenses = 0;
    for (final e in expenses) {
      final amt = (e['amount'] as num? ?? 0).toDouble();
      totalExpenses += amt;

      final dayKey = e['date'].toString().length >= 10
          ? e['date'].toString().substring(0, 10)
          : e['date'].toString();
      ensureDay(dayKey);
      dayMap[dayKey]!['expense'] = dayMap[dayKey]!['expense']! + amt;
    }

    final totalRevenue = totalCounterSales + totalSpecialOrders + totalB2bSupply;
    final netProfitOrLoss = totalRevenue - totalExpenses;
    final sortedDays = dayMap.keys.toList()..sort();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(width: 2, color: PdfColors.pink800),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      AppSettings.shopName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.pink800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Monthly & Day-Wise Statement • $monthTitle',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Text(
                  'Generated: $generatedDate',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '1. Revenue & Profit / Loss Summary',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
            headers: ['Particulars', 'Breakdown', 'Amount'],
            data: [
              [
                'Counter Sales',
                'Cash: ${cashSales.toStringAsFixed(0)} | UPI: ${upiSales.toStringAsFixed(0)}',
                totalCounterSales.toStringAsFixed(0),
              ],
              [
                'Special Cake Orders',
                '${specialOrders.length} Orders (Advance: ${totalSpecialAdvance.toStringAsFixed(0)})',
                totalSpecialOrders.toStringAsFixed(0),
              ],
              [
                'B2B Cake Supply',
                '${b2bDispatch.length} Dispatches',
                totalB2bSupply.toStringAsFixed(0),
              ],
              [
                'Total Revenue',
                'Combined Sales',
                totalRevenue.toStringAsFixed(0),
              ],
              [
                'Total Expenses',
                '${expenses.length} Entries',
                '- ${totalExpenses.toStringAsFixed(0)}',
              ],
              [
                'NET PROFIT / LOSS',
                netProfitOrLoss >= 0 ? 'Profit' : 'Loss',
                netProfitOrLoss.toStringAsFixed(0),
              ],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '2. Day-Wise Breakdown ($monthTitle)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (sortedDays.isEmpty)
            pw.Text(
              'No daily records found in $monthTitle.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9.5,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
              headers: ['Date', 'Counter', 'Orders', 'B2B', 'Expense', 'Day Net'],
              data: sortedDays.map((dayKey) {
                final stats = dayMap[dayKey]!;
                final sVal = stats['sales']!;
                final oVal = stats['orders']!;
                final bVal = stats['b2b']!;
                final eVal = stats['expense']!;
                final dayNet = (sVal + oVal + bVal) - eVal;
                final parsed = DateTime.tryParse(dayKey);
                final label = parsed != null
                    ? DateFormat('dd MMM (EEE)').format(parsed)
                    : dayKey;
                return [
                  label,
                  sVal.toStringAsFixed(0),
                  oVal.toStringAsFixed(0),
                  bVal.toStringAsFixed(0),
                  eVal.toStringAsFixed(0),
                  dayNet.toStringAsFixed(0),
                ];
              }).toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            '3. B2B Flavour-Wise Cakes Supplied',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (flavourSummary.isEmpty)
            pw.Text(
              'No B2B cake supply in $monthTitle.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
              headers: ['Flavour', 'Qty', 'Rate', 'Total'],
              data: flavourSummary.values
                  .map(
                    (f) => [
                  f['flavour'].toString(),
                  '${f['qty']}',
                  (f['rate'] as num).toStringAsFixed(0),
                  (f['total'] as num).toStringAsFixed(0),
                ],
              )
                  .toList(),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            '4. Bakery Khata (Pending Balances)',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (bakeryParties.isEmpty)
            pw.Text(
              'No bakery parties recorded.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink700),
              headers: ['Bakery Name', 'Phone', 'Pending Balance'],
              data: bakeryParties
                  .map(
                    (p) => [
                  p['bakery_name'].toString(),
                  (p['phone'] ?? '').toString(),
                  (p['current_balance'] as num? ?? 0).toStringAsFixed(0),
                ],
              )
                  .toList(),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> shareMonthlyReport(DateTime monthDate) async {
    final bytes = await generateMonthlyReport(monthDate);
    final fileMonth = DateFormat('yyyy_MM').format(monthDate);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Janta_Bakery_Report_$fileMonth.pdf',
    );
  }
}