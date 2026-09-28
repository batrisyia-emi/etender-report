// lib/reports/models/records/tender_security_record.dart
//
// One tender security lodged by one tenderer against one tender, per
// Blueprint v1.3 chapter 9.1 and process flow 3.5 process 1.12.
//
// One row per tenderer per tender, not one per tender: two bidders on the
// same tender lodge two securities, each with its own unique number
// (TS/YYYY/NNNNNN, generated when the supplier submits).
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';
import 'package:etender_reports/reports/models/tender_security_attributes.dart';

class TenderSecurityRecord extends Equatable {
  const TenderSecurityRecord({
    required this.tenderNo,
    required this.vendorName,
    required this.uniqueNo,
    required this.amount,
    required this.bankName,
    required this.paymentType,
    required this.referenceNo,
    required this.scanCopy,
    required this.expiryDate,
    required this.originalCopyReceived,
    required this.submittedToRevenueAssuranceDate,
    required this.unsuccessfulTenderer,
    required this.refundDate,
  });

  factory TenderSecurityRecord.fromJson(Map<String, dynamic> json) =>
      TenderSecurityRecord(
        tenderNo: asString(json['tenderNo']),
        vendorName: asString(json['vendorName']),
        uniqueNo: asString(json['uniqueNo']),
        amount: asDouble(json['amount']),
        bankName: asString(json['bankName']),
        paymentType: asString(json['paymentType']),
        referenceNo: asString(json['referenceNo']),
        scanCopy: asStringOrNull(json['scanCopy']),
        expiryDate: asDateOrNull(json['expiryDate']),
        originalCopyReceived: asBool(json['originalCopyReceived']),
        submittedToRevenueAssuranceDate: asDateOrNull(
          json['submittedToRevenueAssuranceDate'],
        ),
        // Kept as the wire string rather than parsed to a bool: blank means
        // "not decided", which is not "NO", and a bool cannot hold three
        // states. See [UnsuccessfulTenderer].
        unsuccessfulTenderer: asStringOrNull(json['unsuccessfulTenderer']),
        refundDate: asDateOrNull(json['refundDate']),
      );

  // ---- System ------------------------------------------------------------

  final String tenderNo;
  final String vendorName;

  /// `TS/YYYY/NNNNNN`, generated when the supplier submits.
  final String uniqueNo;

  // ---- Supplier ----------------------------------------------------------

  final double amount;
  final String bankName;

  /// See [PaymentType]; a code, not a label.
  final String paymentType;

  /// The bank's own reference for the instrument.
  final String referenceNo;

  /// Scan of the instrument, uploaded with the submission. Null when
  /// nothing was attached, though the blueprint makes it mandatory.
  final String? scanCopy;

  /// When the instrument lapses. What the report is mostly about: a
  /// security that expires while still held secures nothing.
  final DateTime? expiryDate;

  // ---- VTM, editable -----------------------------------------------------

  /// Appendix F item (m): the scan is uploaded first and the original comes
  /// in physically before the tender closes. This marks it arrived.
  final bool originalCopyReceived;

  /// When the security was passed to Revenue Assurance / Contract Services.
  /// Null means it has not been. A date rather than a tick — see open
  /// question Q1 in docs/tender-security-report.md.
  final DateTime? submittedToRevenueAssuranceDate;

  /// `YES`, `NO`, or null for not yet decided.
  final String? unsuccessfulTenderer;

  final DateTime? refundDate;

  PaymentType? get paymentTypeValue => PaymentType.fromWire(paymentType);

  String get paymentTypeLabel => PaymentType.labelFor(paymentType);

  UnsuccessfulTenderer get outcome =>
      UnsuccessfulTenderer.fromWire(unsuccessfulTenderer);

  /// Handed to Revenue Assurance, whatever the date.
  bool get isSubmittedToRevenueAssurance =>
      submittedToRevenueAssuranceDate != null;

  /// A copy with the four VTM fields changed. Used to apply an edit before
  /// the server has confirmed it; see `TenderSecurityBloc`.
  ///
  /// Clearing beats setting, so a clear is never lost to a null that only
  /// meant "unchanged".
  TenderSecurityRecord copyWith({
    bool? originalCopyReceived,
    DateTime? submittedToRevenueAssuranceDate,
    bool clearSubmittedToRevenueAssuranceDate = false,
    String? unsuccessfulTenderer,
    bool clearUnsuccessfulTenderer = false,
    DateTime? refundDate,
    bool clearRefundDate = false,
  }) {
    return TenderSecurityRecord(
      tenderNo: tenderNo,
      vendorName: vendorName,
      uniqueNo: uniqueNo,
      amount: amount,
      bankName: bankName,
      paymentType: paymentType,
      referenceNo: referenceNo,
      scanCopy: scanCopy,
      expiryDate: expiryDate,
      originalCopyReceived: originalCopyReceived ?? this.originalCopyReceived,
      submittedToRevenueAssuranceDate: clearSubmittedToRevenueAssuranceDate
          ? null
          : submittedToRevenueAssuranceDate ??
                this.submittedToRevenueAssuranceDate,
      unsuccessfulTenderer: clearUnsuccessfulTenderer
          ? null
          : unsuccessfulTenderer ?? this.unsuccessfulTenderer,
      refundDate: clearRefundDate ? null : refundDate ?? this.refundDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'tenderNo': tenderNo,
    'vendorName': vendorName,
    'uniqueNo': uniqueNo,
    'amount': amount,
    'bankName': bankName,
    'paymentType': paymentType,
    'referenceNo': referenceNo,
    'scanCopy': scanCopy,
    'expiryDate': expiryDate?.toIso8601String(),
    'originalCopyReceived': originalCopyReceived,
    'submittedToRevenueAssuranceDate': submittedToRevenueAssuranceDate
        ?.toIso8601String(),
    'unsuccessfulTenderer': unsuccessfulTenderer,
    'refundDate': refundDate?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    tenderNo,
    vendorName,
    uniqueNo,
    amount,
    bankName,
    paymentType,
    referenceNo,
    scanCopy,
    expiryDate,
    originalCopyReceived,
    submittedToRevenueAssuranceDate,
    unsuccessfulTenderer,
    refundDate,
  ];
}
