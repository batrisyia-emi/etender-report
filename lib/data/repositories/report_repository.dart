// lib/data/repositories/report_repository.dart
//
// The seam between this app and whatever supplies its data.
//
// Everything above this line is frontend: blocs, views, widgets. Nothing
// in there knows where records come from. Swapping the mock source for a
// real API is a matter of constructing [ReportsPage] with a different
// implementation of this interface — no widget changes.
//
// The return types are the contract. Each record class documents the exact
// JSON the endpoint has to produce, field by field, in its `fromJson`.
import 'package:etender_reports/reports/models/records/erfc_record.dart';
import 'package:etender_reports/reports/models/records/supplier_record.dart';
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:etender_reports/reports/models/records/vendor_participation_record.dart';

/// What the reports need, one method per dataset.
///
/// Each returns every record it has; filtering, sorting and searching all
/// happen in the app. A backend that would rather filter server-side can
/// add parameters here — the blocs are the only callers.
abstract class ReportRepository {
  const ReportRepository();

  /// GET /reports/tenders — see [TenderRecord.fromJson].
  Future<List<TenderRecord>> fetchTenderRecords();

  /// GET /reports/vendor-participation — see
  /// [VendorParticipationRecord.fromJson]. One row per vendor per tender
  /// invited, not one per tender.
  Future<List<VendorParticipationRecord>> fetchVendorParticipationRecords();

  /// GET /reports/erfc — see [ErfcRecord.fromJson].
  Future<List<ErfcRecord>> fetchErfcRecords();

  /// GET /reports/supplier-participation — see [SupplierRecord.fromJson].
  ///
  /// Scoped to the signed-in supplier: a supplier must never receive
  /// another supplier's rows, because the report shows bid amounts and
  /// document fees.
  Future<List<SupplierRecord>> fetchSupplierRecords();
}
