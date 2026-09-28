// test/helpers/failing_report_repository.dart
//
// A repository where every read fails, so the blocs can be tested against
// the case a real backend will produce and the mock one never does.
//
// This matters more than it looks. MockReportRepository always succeeds,
// so without this the failure branch of every bloc is dead code until the
// day someone points the app at a real API.
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/models/records/erfc_record.dart';
import 'package:etender_reports/reports/models/records/supplier_record.dart';
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/records/vendor_participation_record.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';

/// Stands in for the network being down, the endpoint 500ing, or the JSON
/// not parsing — as far as a bloc is concerned those are one case.
class FailingReportRepository extends ReportRepository {
  const FailingReportRepository([this.error = 'endpoint unavailable']);

  final String error;

  Future<List<T>> _fail<T>() async => throw StateError(error);

  @override
  Future<List<TenderRecord>> fetchTenderRecords() => _fail();

  @override
  Future<List<VendorParticipationRecord>> fetchVendorParticipationRecords() =>
      _fail();

  @override
  Future<List<ErfcRecord>> fetchErfcRecords() => _fail();

  @override
  Future<List<TocOpeningRecord>> fetchTocRecords() => _fail();

  @override
  Future<List<TenderSecurityRecord>> fetchTenderSecurityRecords() => _fail();

  @override
  Future<List<VtmMonitoringRecord>> fetchVtmMonitoringRecords() => _fail();

  @override
  Future<List<SupplierRecord>> fetchSupplierRecords() => _fail();
}

/// Counts how many times each read was called, to prove that filtering
/// happens in the app and does not go back to the server.
class CountingReportRepository extends ReportRepository {
  CountingReportRepository(this._inner);

  final ReportRepository _inner;
  int calls = 0;

  Future<List<T>> _count<T>(Future<List<T>> Function() read) {
    calls++;
    return read();
  }

  @override
  Future<List<TenderRecord>> fetchTenderRecords() =>
      _count(_inner.fetchTenderRecords);

  @override
  Future<List<VendorParticipationRecord>> fetchVendorParticipationRecords() =>
      _count(_inner.fetchVendorParticipationRecords);

  @override
  Future<List<ErfcRecord>> fetchErfcRecords() =>
      _count(_inner.fetchErfcRecords);

  @override
  Future<List<TocOpeningRecord>> fetchTocRecords() =>
      _count(_inner.fetchTocRecords);

  @override
  Future<List<TenderSecurityRecord>> fetchTenderSecurityRecords() =>
      _count(_inner.fetchTenderSecurityRecords);

  @override
  Future<List<VtmMonitoringRecord>> fetchVtmMonitoringRecords() =>
      _count(_inner.fetchVtmMonitoringRecords);

  @override
  Future<List<SupplierRecord>> fetchSupplierRecords() =>
      _count(_inner.fetchSupplierRecords);
}
