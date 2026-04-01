import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';

class ExportService {
  static Future<void> exportTransactionsToCsv(List<TransactionModel> transactions) async {
    // 1. Define CSV Headers
    List<List<dynamic>> rows = [
      ["Date", "Category", "Type", "Amount", "Note"]
    ];

    // 2. Map Transactions to Rows
    for (var t in transactions) {
      rows.add([
        t.date.toIso8601String().split('T')[0],
        t.category,
        t.type,
        t.amount,
        t.note ?? ""
      ]);
    }

    // 3. Convert to CSV String
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Save to temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/FinTrack_Export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    // 5. Trigger Native Share/Save Dialog
    await Share.shareXFiles([XFile(file.path)], text: 'FinTrack Financial Export');
  }
}