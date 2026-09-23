// lib/data/repositories/mock_report_repository.dart
//
// The stand-in the app ships with until there is an API behind it.
//
// The mock rows go through the same `fromJson` the real responses will, so
// the contract is exercised on every run rather than only once a backend
// exists. A field the record does not know about is dropped here, which is
// how a mismatch surfaces early.
import 'package:etender_reports/data/mock/report_mock_data.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/models/records/erfc_record.dart';
import 'package:etender_reports/reports/models/records/supplier_record.dart';
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:etender_reports/reports/models/records/vendor_participation_record.dart';

class MockReportRepository extends ReportRepository {
  const MockReportRepository();

  @override
  Future<List<TenderRecord>> fetchTenderRecords() async => [
    for (final json in ReportMockData.tenderRecords)
      TenderRecord.fromJson(json),
  ];

  @override
  Future<List<VendorParticipationRecord>>
  fetchVendorParticipationRecords() async => [
    for (final json in ReportMockData.vendorParticipationRecords)
      VendorParticipationRecord.fromJson(json),
  ];

  @override
  Future<List<ErfcRecord>> fetchErfcRecords() async => [
    for (final json in ReportMockData.erfcRecords) ErfcRecord.fromJson(json),
  ];

  @override
  Future<List<SupplierRecord>> fetchSupplierRecords() async => [
    for (final json in ReportMockData.supplierRecords)
      SupplierRecord.fromJson(json),
  ];
}
