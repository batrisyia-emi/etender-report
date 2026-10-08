// lib/data/mock/report_mock_data.dart
//
// Sample data for the four reports. Vendor rows reference tenders by
// referenceNo and tenderNo, and RFC numbers match the tenders they came
// from, so cross-report figures stay consistent.
import 'package:etender_reports/data/mock/erfc_records.dart';
import 'package:etender_reports/data/mock/supplier_records.dart';
import 'package:etender_reports/data/mock/tender_records.dart';
import 'package:etender_reports/data/mock/tender_security_records.dart';
import 'package:etender_reports/data/mock/toc_records.dart';
import 'package:etender_reports/data/mock/vendor_participation_records.dart';
import 'package:etender_reports/data/mock/vtm_monitoring_records.dart';

class ReportMockData {
  const ReportMockData._();

  /// Each dataset lives in its own file; this keeps the one name every
  /// call site already uses.
  static const List<Map<String, dynamic>> tenderRecords = kTenderRecords;
  static const List<Map<String, dynamic>> vendorParticipationRecords =
      kVendorParticipationRecords;
  static const List<Map<String, dynamic>> erfcRecords = kErfcRecords;
  static const List<Map<String, dynamic>> supplierRecords = kSupplierRecords;

  /// Built on each read, not a const: the dates are relative to today so
  /// the time-based exception flags keep firing. See [buildTocRecords].
  static List<Map<String, dynamic>> get tocRecords => buildTocRecords();

  /// Relative dates too, so "expiring in 14 days" and "expired" keep
  /// meaning something. See [buildTenderSecurityRecords].
  static List<Map<String, dynamic>> get tenderSecurityRecords =>
      buildTenderSecurityRecords();

  /// Relative dates again: aging counts to today for anything in flight.
  /// See [buildVtmMonitoringRecords].
  static List<Map<String, dynamic>> get vtmMonitoringRecords =>
      buildVtmMonitoringRecords();
}
