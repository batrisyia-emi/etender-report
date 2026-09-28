// lib/reports/models/records/toc_opening_record.dart
//
// One tender or quotation and the Tender Opening Committee appointed to
// open it, per Blueprint v1.3 sections 3.6 / 4.5 / 8.3 / 8.4.
//
// ⚠️ This record deliberately carries no bid data. The report is visible to
// VTM staff before evaluation, so Harga Tawaran, Jadual Harga (Appendix C),
// Tempoh Siap, Tempoh Sah Laku, any other Appendix G content and OTP values
// must never reach it. Only *whether* Appendix G was submitted, by whom and
// when. Adding a price field here is a confidentiality breach, not a
// feature.
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';
import 'package:etender_reports/reports/models/toc_status.dart';

/// One seat on a committee.
class TocMember extends Equatable {
  const TocMember({
    required this.role,
    required this.staffId,
    required this.name,
    required this.designation,
    required this.department,
    required this.division,
    required this.email,
    required this.appendixIAckAt,
    required this.appendixJAckAt,
    required this.appendixGAckAt,
  });

  factory TocMember.fromJson(Map<String, dynamic> json) => TocMember(
    role: asString(json['role']),
    staffId: asString(json['staffId']),
    name: asString(json['name']),
    designation: asString(json['designation']),
    department: asString(json['department']),
    division: asString(json['division']),
    email: asString(json['email']),
    appendixIAckAt: asDateOrNull(json['appendixIAckAt']),
    appendixJAckAt: asDateOrNull(json['appendixJAckAt']),
    appendixGAckAt: asDateOrNull(json['appendixGAckAt']),
  );

  final String role;
  final String staffId;
  final String name;
  final String designation;
  final String department;
  final String division;
  final String email;

  /// Appendix I — non-conflict, confidentiality and anti-corruption.
  ///
  /// Carried because the endpoint sends it and the blueprint requires it,
  /// but nothing renders it: the report no longer tracks declarations.
  final DateTime? appendixIAckAt;

  /// Appendix J — Integrity Pledge, in BM or EN. Carried, not rendered;
  /// see [appendixIAckAt].
  final DateTime? appendixJAckAt;

  /// Acknowledgement of the completed Appendix G. Every member's timestamp
  /// follows the Chairman's, by process 1.6.
  final DateTime? appendixGAckAt;

  TocRole? get roleValue => TocRole.fromWire(role);

  Map<String, dynamic> toJson() => {
    'role': role,
    'staffId': staffId,
    'name': name,
    'designation': designation,
    'department': department,
    'division': division,
    'email': email,
    'appendixIAckAt': appendixIAckAt?.toIso8601String(),
    'appendixJAckAt': appendixJAckAt?.toIso8601String(),
    'appendixGAckAt': appendixGAckAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    role,
    staffId,
    name,
    designation,
    department,
    division,
    email,
    appendixIAckAt,
    appendixJAckAt,
    appendixGAckAt,
  ];
}

/// A member swapped out after appointment. Remarks are mandatory, and the
/// replaced member is not emailed.
class TocReplacement extends Equatable {
  const TocReplacement({
    required this.role,
    required this.replacedName,
    required this.newName,
    required this.remarks,
    required this.replacedAt,
    required this.replacedBy,
  });

  factory TocReplacement.fromJson(Map<String, dynamic> json) => TocReplacement(
    role: asString(json['role']),
    replacedName: asString(json['replacedName']),
    newName: asString(json['newName']),
    remarks: asString(json['remarks']),
    replacedAt: asDateOrNull(json['replacedAt']),
    replacedBy: asString(json['replacedBy']),
  );

  final String role;
  final String replacedName;
  final String newName;

  /// Mandatory, per the blueprint's business rules.
  final String remarks;

  final DateTime? replacedAt;
  final String replacedBy;

  Map<String, dynamic> toJson() => {
    'role': role,
    'replacedName': replacedName,
    'newName': newName,
    'remarks': remarks,
    'replacedAt': replacedAt?.toIso8601String(),
    'replacedBy': replacedBy,
  };

  @override
  List<Object?> get props => [
    role,
    replacedName,
    newName,
    remarks,
    replacedAt,
    replacedBy,
  ];
}

/// One opening: the document, its committee, and how far the process got.
class TocOpeningRecord extends Equatable {
  const TocOpeningRecord({
    required this.tenderNo,
    required this.documentType,
    required this.projectTitle,
    required this.erfcNo,
    required this.envelopeType,
    required this.status,
    required this.closingDateTime,
    required this.openingDateTime,
    required this.isExtended,
    required this.committee,
    required this.appointedAt,
    required this.replacements,
    required this.memoRefNo,
    required this.memoSentAt,
    required this.otpIssuedDates,
    required this.openedAt,
    required this.suppliersSubmittedCount,
    required this.appendixGSubmittedBy,
    required this.appendixGSubmittedAt,
    required this.appendixPSubmittedBy,
    required this.appendixPSubmittedAt,
  });

  factory TocOpeningRecord.fromJson(Map<String, dynamic> json) =>
      TocOpeningRecord(
        tenderNo: asString(json['tenderNo']),
        documentType: asString(json['documentType']),
        projectTitle: asString(json['projectTitle']),
        erfcNo: asString(json['erfcNo']),
        envelopeType: asString(json['envelopeType']),
        status: asString(json['status']),
        closingDateTime: asDateOrNull(json['closingDateTime']),
        openingDateTime: asDateOrNull(json['openingDateTime']),
        isExtended: asBool(json['isExtended']),
        committee: [
          for (final member in asList(json['committee']))
            TocMember.fromJson(member),
        ],
        appointedAt: asDateOrNull(json['appointedAt']),
        replacements: [
          for (final swap in asList(json['replacements']))
            TocReplacement.fromJson(swap),
        ],
        memoRefNo: asStringOrNull(json['memoRefNo']),
        memoSentAt: asDateOrNull(json['memoSentAt']),
        otpIssuedDates: asDateList(json['otpIssuedDates']),
        openedAt: asDateOrNull(json['openedAt']),
        suppliersSubmittedCount: asInt(json['suppliersSubmittedCount']),
        appendixGSubmittedBy: asStringOrNull(json['appendixGSubmittedBy']),
        appendixGSubmittedAt: asDateOrNull(json['appendixGSubmittedAt']),
        appendixPSubmittedBy: asStringOrNull(json['appendixPSubmittedBy']),
        appendixPSubmittedAt: asDateOrNull(json['appendixPSubmittedAt']),
      );

  /// e.g. T.10001, T.10001(2S), Q.10001, Z.10001
  final String tenderNo;

  /// 'Tender' or 'Quotation'; see [TocDocumentType].
  final String documentType;

  /// From eRFC section B-1.
  final String projectTitle;
  final String erfcNo;

  /// '1 Envelope' or '2 Envelope'; see [TocEnvelopeType]. Decides which
  /// statuses this tender can reach.
  final String envelopeType;

  /// Sent by the server, not derived here — see [TocStatus].
  final String status;

  final DateTime? closingDateTime;

  /// Defaults to 12:00 on the opening day, and is editable. Null until the
  /// opening has been coordinated.
  final DateTime? openingDateTime;

  /// An extension after appointment clears the committee, so this and an
  /// empty [committee] travel together.
  final bool isExtended;

  /// Empty or exactly three members.
  final List<TocMember> committee;

  final DateTime? appointedAt;
  final List<TocReplacement> replacements;

  /// SE/P/UVTM/{QTN|TN}/FY{yy}/TOC{running no}
  final String? memoRefNo;
  final DateTime? memoSentAt;

  /// One per opening day; a second is issued if the opening runs over. The
  /// passwords themselves are never carried here.
  final List<DateTime> otpIssuedDates;

  final DateTime? openedAt;
  final int suppliersSubmittedCount;

  /// Who submitted Appendix G and when — never what it contained.
  final String? appendixGSubmittedBy;
  final DateTime? appendixGSubmittedAt;

  final String? appendixPSubmittedBy;
  final DateTime? appendixPSubmittedAt;

  TocDocumentType? get documentTypeValue =>
      TocDocumentType.fromWire(documentType);

  /// Null when the seat is unfilled, which is every seat before appointment.
  TocMember? memberAt(TocRole role) {
    for (final member in committee) {
      if (member.roleValue == role) return member;
    }
    return null;
  }

  /// A committee is three seats; anything else is not yet appointed.
  bool get hasCommittee => committee.length == 3;

  TocStatus? get statusValue => TocStatus.fromWire(status);

  TocEnvelopeType? get envelopeTypeValue =>
      TocEnvelopeType.fromWire(envelopeType);

  /// True when the status the server sent cannot occur under this tender's
  /// envelope arrangement — a two-envelope stage on a one-envelope tender,
  /// or the reverse.
  ///
  /// The app does not correct it; it shows the row and flags it, because the
  /// disagreement is the finding.
  bool get hasEnvelopeMismatch {
    final value = statusValue;
    if (value == null) return false;
    return !value.appliesTo(envelopeType);
  }

  Map<String, dynamic> toJson() => {
    'tenderNo': tenderNo,
    'documentType': documentType,
    'projectTitle': projectTitle,
    'erfcNo': erfcNo,
    'envelopeType': envelopeType,
    'status': status,
    'closingDateTime': closingDateTime?.toIso8601String(),
    'openingDateTime': openingDateTime?.toIso8601String(),
    'isExtended': isExtended,
    'committee': [for (final member in committee) member.toJson()],
    'appointedAt': appointedAt?.toIso8601String(),
    'replacements': [for (final swap in replacements) swap.toJson()],
    'memoRefNo': memoRefNo,
    'memoSentAt': memoSentAt?.toIso8601String(),
    'otpIssuedDates': [
      for (final date in otpIssuedDates) date.toIso8601String(),
    ],
    'openedAt': openedAt?.toIso8601String(),
    'suppliersSubmittedCount': suppliersSubmittedCount,
    'appendixGSubmittedBy': appendixGSubmittedBy,
    'appendixGSubmittedAt': appendixGSubmittedAt?.toIso8601String(),
    'appendixPSubmittedBy': appendixPSubmittedBy,
    'appendixPSubmittedAt': appendixPSubmittedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    tenderNo,
    documentType,
    projectTitle,
    erfcNo,
    envelopeType,
    status,
    closingDateTime,
    openingDateTime,
    isExtended,
    committee,
    appointedAt,
    replacements,
    memoRefNo,
    memoSentAt,
    otpIssuedDates,
    openedAt,
    suppliersSubmittedCount,
    appendixGSubmittedBy,
    appendixGSubmittedAt,
    appendixPSubmittedBy,
    appendixPSubmittedAt,
  ];
}
