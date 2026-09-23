// lib/data/mock/report_mock_data.dart
//
// Sample data for the four reports. Vendor rows reference tenders by
// referenceNo and tenderNo, and RFC numbers match the tenders they came
// from, so cross-report figures stay consistent.
import 'package:etender_reports/data/mock/tender_records.dart';
import 'package:etender_reports/data/mock/vendor_participation_records.dart';
import 'package:etender_reports/data/mock/erfc_records.dart';
import 'package:etender_reports/data/mock/supplier_records.dart';
import 'package:etender_reports/data/mock/supplier_portal.dart';

class ReportMockData {
  const ReportMockData._();

  /// Each dataset lives in its own file; this keeps the one name every
  /// call site already uses.
  static const List<Map<String, dynamic>> tenderRecords = kTenderRecords;
  static const List<Map<String, dynamic>> vendorParticipationRecords =
      kVendorParticipationRecords;
  static const List<Map<String, dynamic>> erfcRecords = kErfcRecords;
  static const List<Map<String, dynamic>> supplierRecords = kSupplierRecords;

  static const Map<String, dynamic> supplierProfile = kSupplierProfile;
  static const List<Map<String, dynamic>> supplierDocuments =
      kSupplierDocuments;
  static const List<Map<String, dynamic>> supplierBidPipeline =
      kSupplierBidPipeline;
  static const List<Map<String, dynamic>> supplierNotifications =
      kSupplierNotifications;
}
