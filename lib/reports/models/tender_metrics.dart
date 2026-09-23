// lib/reports/models/tender_metrics.dart

double _valueOf(Map<String, dynamic> record) =>
    double.tryParse(record['value']?.toString() ?? '') ?? 0;

double tenderTotalValue(List<Map<String, dynamic>> records) =>
    records.fold<double>(0, (total, record) => total + _valueOf(record));

double? tenderAverageValue(List<Map<String, dynamic>> records) =>
    records.isEmpty ? null : tenderTotalValue(records) / records.length;

Map<String, int> tenderStatusCounts(List<Map<String, dynamic>> records) {
  final counts = <String, int>{};
  for (final record in records) {
    final status = record['status']?.toString() ?? 'Unknown';
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}
