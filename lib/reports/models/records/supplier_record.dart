// lib/reports/models/records/supplier_record.dart
import 'package:equatable/equatable.dart';

import 'package:etender_reports/reports/models/supplier_status.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';

/// One supplier's involvement in one tender or quotation, from the
/// supplier's side of the portal.
class SupplierRecord extends Equatable {
  const SupplierRecord({
    required this.supplierName,
    required this.supplierId,
    required this.referenceNo,
    required this.tenderNo,
    required this.title,
    required this.tenderCategory,
    required this.division,
    required this.modeOfProcurement,
    required this.openTo,
    required this.certificationType,
    required this.status,
    required this.publishedDate,
    required this.requestDate,
    required this.decisionDate,
    required this.paymentDate,
    required this.closingDate,
    required this.submissionDateTime,
    required this.documentFee,
    required this.bidAmount,
  });

  factory SupplierRecord.fromJson(Map<String, dynamic> json) => SupplierRecord(
    supplierName: asString(json['supplierName']),
    supplierId: asString(json['supplierId']),
    referenceNo: asString(json['referenceNo']),
    tenderNo: asString(json['tenderNo']),
    title: asString(json['title']),
    tenderCategory: asString(json['tenderCategory']),
    division: asString(json['division']),
    modeOfProcurement: asString(json['modeOfProcurement']),
    openTo: asString(json['openTo']),
    certificationType: asString(json['certificationType']),
    status: asString(json['status']),
    publishedDate: asDateOrNull(json['publishedDate']),
    requestDate: asDateOrNull(json['requestDate']),
    decisionDate: asDateOrNull(json['decisionDate']),
    paymentDate: asDateOrNull(json['paymentDate']),
    closingDate: asDateOrNull(json['closingDate']),
    submissionDateTime: asDateOrNull(json['submissionDateTime']),
    documentFee: asDouble(json['documentFee']),
    bidAmount: asDouble(json['bidAmount']),
  );

  final String supplierName;

  /// The vendor registration code, e.g. VEN/2000/000004.
  final String supplierId;

  final String referenceNo;
  final String tenderNo;
  final String title;
  final String tenderCategory;
  final String division;
  final String modeOfProcurement;

  /// Appendix A 8.1 — who the tender was open to.
  final String openTo;
  final String certificationType;

  final String status;

  /// When the tender became visible to this supplier.
  final DateTime? publishedDate;

  /// Null until the supplier asks to take part.
  final DateTime? requestDate;

  /// When a gate approved or rejected the request. Null while it is still
  /// under review.
  final DateTime? decisionDate;

  /// Null until the document fee is settled.
  final DateTime? paymentDate;

  final DateTime? closingDate;

  /// Null unless the supplier actually bid.
  final DateTime? submissionDateTime;

  final double documentFee;

  /// Zero until a bid is submitted.
  final double bidAmount;

  Map<String, dynamic> toJson() => {
    'supplierName': supplierName,
    'supplierId': supplierId,
    'referenceNo': referenceNo,
    'tenderNo': tenderNo,
    'title': title,
    'tenderCategory': tenderCategory,
    'division': division,
    'modeOfProcurement': modeOfProcurement,
    'openTo': openTo,
    'certificationType': certificationType,
    'status': status,
    'publishedDate': publishedDate?.toIso8601String(),
    'requestDate': requestDate?.toIso8601String(),
    'decisionDate': decisionDate?.toIso8601String(),
    'paymentDate': paymentDate?.toIso8601String(),
    'closingDate': closingDate?.toIso8601String(),
    'submissionDateTime': submissionDateTime?.toIso8601String(),
    'documentFee': documentFee,
    'bidAmount': bidAmount,
  };

  SupplierStatus? get lifecycleStatus => SupplierStatus.fromWire(status);

  bool get isRejected => SupplierStatus.rejected.contains(lifecycleStatus);

  /// Cleared the gates: approved, or past that into payment.
  bool get isCleared => SupplierStatus.cleared.contains(lifecycleStatus);

  /// The fee is owed and not yet settled — the one status that asks the
  /// supplier to do something right now.
  bool get isAwaitingPayment =>
      lifecycleStatus == SupplierStatus.pendingPayment;

  bool get hasParticipated => lifecycleStatus == SupplierStatus.participated;

  /// Set by the system when the tender closed without a bid from this
  /// supplier.
  bool get missedParticipation =>
      lifecycleStatus == SupplierStatus.noParticipate;

  /// Nothing more will happen on this tender.
  bool get isTerminal => SupplierStatus.terminal.contains(lifecycleStatus);

  /// Request to decision. Null while the request is still under review, or
  /// before it was made at all.
  int? get daysToDecision {
    final requested = requestDate;
    final decided = decisionDate;
    if (requested == null || decided == null) return null;
    final days = decided.difference(requested).inDays;
    return days < 0 ? 0 : days;
  }

  /// Null when there is no closing date, or it has already passed.
  int? daysToClosing({DateTime? asOf}) {
    final closing = closingDate;
    if (closing == null) return null;
    final now = asOf ?? DateTime.now();
    if (closing.isBefore(now)) return null;
    return closing.difference(now).inDays;
  }

  @override
  List<Object?> get props => [
    supplierName,
    supplierId,
    referenceNo,
    tenderNo,
    title,
    tenderCategory,
    division,
    modeOfProcurement,
    openTo,
    certificationType,
    status,
    publishedDate,
    requestDate,
    decisionDate,
    paymentDate,
    closingDate,
    submissionDateTime,
    documentFee,
    bidAmount,
  ];
}
