// lib/reports/models/records/vtm_monitoring_record.dart
//
// One Appendix F on its way from preparation to floating, for the VTM
// Tender/Quotation Monitoring report.
//
// One row per eRFC, not per tender: the tender number is not assigned until
// the document is approved, so most rows in flight have none yet. The eRFC
// number is the key throughout.
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';

/// Who carried out one step.
class VtmActor extends Equatable {
  const VtmActor({
    required this.userId,
    required this.name,
    required this.role,
  });

  factory VtmActor.fromJson(Map<String, dynamic> json) => VtmActor(
    userId: asString(json['userId']),
    name: asString(json['name']),
    role: asString(json['role']),
  );

  final String userId;
  final String name;
  final String role;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'role': role,
  };

  @override
  List<Object?> get props => [userId, name, role];
}

/// Reads one actor, or null when the step has not happened.
VtmActor? _actorOrNull(Object? value) =>
    value is Map ? VtmActor.fromJson(Map<String, dynamic>.from(value)) : null;

class VtmMonitoringRecord extends Equatable {
  const VtmMonitoringRecord({
    required this.erfcNo,
    required this.tenderQuotationNo,
    required this.projectTitle,
    required this.documentType,
    required this.tenderType,
    required this.modeOfProcurement,
    required this.division,
    required this.department,
    required this.estimatedValue,
    required this.documentPrice,
    required this.status,
    required this.preparedBy,
    required this.verifiedBy,
    required this.approvedBy,
    required this.endorsedDate,
    required this.submittedDate,
    required this.verifiedDate,
    required this.approvedDate,
    required this.floatingDate,
    required this.closingDate,
    required this.rejectionRemarks,
  });

  factory VtmMonitoringRecord.fromJson(Map<String, dynamic> json) =>
      VtmMonitoringRecord(
        erfcNo: asString(json['erfcNo']),
        tenderQuotationNo: asStringOrNull(json['tenderQuotationNo']),
        projectTitle: asString(json['projectTitle']),
        documentType: asString(json['documentType']),
        tenderType: asString(json['tenderType']),
        modeOfProcurement: asString(json['modeOfProcurement']),
        division: asString(json['division']),
        department: asString(json['department']),
        estimatedValue: asDouble(json['estimatedValue']),
        documentPrice: asDouble(json['documentPrice']),
        status: asString(json['status']),
        preparedBy: _actorOrNull(json['preparedBy']),
        verifiedBy: _actorOrNull(json['verifiedBy']),
        approvedBy: _actorOrNull(json['approvedBy']),
        endorsedDate: asDateOrNull(json['endorsedDate']),
        submittedDate: asDateOrNull(json['submittedDate']),
        verifiedDate: asDateOrNull(json['verifiedDate']),
        approvedDate: asDateOrNull(json['approvedDate']),
        floatingDate: asDateOrNull(json['floatingDate']),
        closingDate: asDateOrNull(json['closingDate']),
        rejectionRemarks: asStringOrNull(json['rejectionRemarks']),
        // agingDays is deliberately not read. The report's own rule counts
        // to *today* for anything still in flight, so a number computed
        // when the payload was generated is stale by the time it is shown.
        // See vtmAgingDays.
      );

  /// The key: assigned by the eRFC, present from the first row onward.
  final String erfcNo;

  /// Null until the document is approved — the number is allocated on the
  /// way to floating, not before.
  final String? tenderQuotationNo;

  final String projectTitle;

  /// 'Tender' or 'Quotation'.
  final String documentType;

  /// '1S' or '2S'; see [VtmTenderType].
  final String tenderType;

  /// An Appendix A section 7 number; see [VtmProcurementMode].
  final String modeOfProcurement;

  final String division;
  final String department;

  final double estimatedValue;

  /// What a supplier pays for the document. Zero on quotations.
  final double documentPrice;

  /// A [VtmStatus] code, not a label.
  final String status;

  final VtmActor? preparedBy;
  final VtmActor? verifiedBy;
  final VtmActor? approvedBy;

  /// Where aging counts from.
  final DateTime? endorsedDate;

  final DateTime? submittedDate;
  final DateTime? verifiedDate;
  final DateTime? approvedDate;

  /// When it was floated to suppliers. Where aging counts *to*, once it is
  /// published.
  final DateTime? floatingDate;

  final DateTime? closingDate;

  /// Why it was sent back. Present on the two rejected statuses, and the
  /// thing a reader of a rejected row actually needs.
  final String? rejectionRemarks;

  VtmStatus? get statusValue => VtmStatus.fromCode(status);

  String get statusLabel => VtmStatus.labelFor(status);

  String get modeLabel => VtmProcurementMode.labelFor(modeOfProcurement);

  VtmTenderType? get tenderTypeValue => VtmTenderType.fromCode(tenderType);

  /// Sent back for correction by either gate.
  bool get isRejected => statusValue?.isRejected ?? false;

  /// Floated, so nothing further is expected.
  bool get isPublished => statusValue?.isTerminal ?? false;

  /// A rejected row with nothing said about why. The remark is what the
  /// preparer needs, so its absence is worth surfacing.
  bool get isRejectedWithoutReason =>
      isRejected && (rejectionRemarks == null || rejectionRemarks!.isEmpty);

  Map<String, dynamic> toJson() => {
    'erfcNo': erfcNo,
    'tenderQuotationNo': tenderQuotationNo,
    'projectTitle': projectTitle,
    'documentType': documentType,
    'tenderType': tenderType,
    'modeOfProcurement': modeOfProcurement,
    'division': division,
    'department': department,
    'estimatedValue': estimatedValue,
    'documentPrice': documentPrice,
    'status': status,
    'preparedBy': preparedBy?.toJson(),
    'verifiedBy': verifiedBy?.toJson(),
    'approvedBy': approvedBy?.toJson(),
    'endorsedDate': endorsedDate?.toIso8601String(),
    'submittedDate': submittedDate?.toIso8601String(),
    'verifiedDate': verifiedDate?.toIso8601String(),
    'approvedDate': approvedDate?.toIso8601String(),
    'floatingDate': floatingDate?.toIso8601String(),
    'closingDate': closingDate?.toIso8601String(),
    'rejectionRemarks': rejectionRemarks,
  };

  @override
  List<Object?> get props => [
    erfcNo,
    tenderQuotationNo,
    projectTitle,
    documentType,
    tenderType,
    modeOfProcurement,
    division,
    department,
    estimatedValue,
    documentPrice,
    status,
    preparedBy,
    verifiedBy,
    approvedBy,
    endorsedDate,
    submittedDate,
    verifiedDate,
    approvedDate,
    floatingDate,
    closingDate,
    rejectionRemarks,
  ];
}
