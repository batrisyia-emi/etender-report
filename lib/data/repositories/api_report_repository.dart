// lib/data/repositories/api_report_repository.dart
//
// The skeleton the backend work plugs into. It is deliberately unfinished:
// every method throws until the endpoint behind it exists, so a half-wired
// repository fails loudly rather than showing an empty report.
//
// To bring a report online:
//   1. implement its method below,
//   2. construct ReportsPage with ApiReportRepository instead of
//      MockReportRepository (see lib/main.dart),
//   3. the rest of the app needs no change.
//
// Nothing here depends on a particular HTTP client. Add `http` or `dio` to
// pubspec.yaml and fill in `_getList`.
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/models/records/erfc_record.dart';
import 'package:etender_reports/reports/models/records/supplier_record.dart';
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:etender_reports/reports/models/records/vendor_participation_record.dart';

class ApiReportRepository extends ReportRepository {
  const ApiReportRepository({required this.baseUrl});

  /// The API root, e.g. https://example.invalid/api — set it to the
  /// real host at construction rather than hard-coding one here.
  final String baseUrl;

  /// One GET returning a JSON array, mapped through the record's
  /// `fromJson`. Every method below is a one-liner on top of this.
  ///
  /// Decide here how the API reports failure and how the session token is
  /// attached; the blocs already surface a thrown error as the report's
  /// failure state, so throwing is the right thing to do.
  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    throw UnimplementedError(
      'ApiReportRepository._getList: GET $baseUrl$path is not wired up yet. '
      'Issue the request, decode the JSON array, and map each element '
      'through fromJson.',
    );
  }

  @override
  Future<List<TenderRecord>> fetchTenderRecords() =>
      _getList('/reports/tenders', TenderRecord.fromJson);

  @override
  Future<List<VendorParticipationRecord>> fetchVendorParticipationRecords() =>
      _getList(
        '/reports/vendor-participation',
        VendorParticipationRecord.fromJson,
      );

  @override
  Future<List<ErfcRecord>> fetchErfcRecords() =>
      _getList('/reports/erfc', ErfcRecord.fromJson);

  /// Must be scoped to the signed-in supplier server-side. The app does not
  /// filter by supplier and deliberately shows no supplier column, so
  /// returning every supplier's rows here would leak competitors' bid
  /// amounts and fees.
  @override
  Future<List<SupplierRecord>> fetchSupplierRecords() =>
      _getList('/reports/supplier-participation', SupplierRecord.fromJson);
}
