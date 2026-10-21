// lib/reports/procurement_lead_time/data/lead_time_repository.dart
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';

/// Where the Procurement Lead Time report reads from. Implement this
/// against the real API and pass it to `ReportsPage`; nothing in the UI
/// changes.
abstract class LeadTimeRepository {
  const LeadTimeRepository();

  /// Published records whose VTM received date falls between
  /// [receivedFrom] and [receivedTo], both calendar dates inclusive,
  /// narrowed to [type] and,
  /// when given, to one [procurementMode] code such as '7.2'. One not yet
  /// published has no lead time and is left out.
  Future<List<LeadTimeRecord>> fetchRecords({
    required DateTime receivedFrom,
    required DateTime receivedTo,
    DocumentTypeFilter type = DocumentTypeFilter.tender,
    String? procurementMode,
  });

  /// Public holidays that are not working days. Meant to be a maintained
  /// table; any time of day is ignored.
  Future<Set<DateTime>> fetchHolidays();
}
