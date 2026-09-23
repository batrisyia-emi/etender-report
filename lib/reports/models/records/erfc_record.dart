// lib/reports/models/records/erfc_record.dart
import 'package:equatable/equatable.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';

// The status sets and the overdue threshold live in erfc_metrics.dart and
// are re-exported here, so the record and the metric helpers can never drift
// apart the way they did when each kept its own copy.
export 'package:etender_reports/reports/models/erfc_metrics.dart'
    show
        kErfcEndorsedStatuses,
        kErfcOverdueDays,
        kErfcRejectedStatuses,
        kErfcTerminalStatuses;

/// One RFC, per report spec 6.2.
///
/// Aging and overdue live here rather than in a helper because they are
/// properties of the record, and having them on the type means a caller
/// cannot forget the terminal-status rule.
class ErfcRecord extends Equatable {
  const ErfcRecord({
    required this.rfcNumber,
    required this.division,
    required this.department,
    required this.unit,
    required this.modeOfProcurement,
    required this.value,
    required this.submissionDate,
    required this.verified1Date,
    required this.verified2Date,
    required this.endorsedDate,
    required this.status,
    required this.createdBy,
  });

  factory ErfcRecord.fromJson(Map<String, dynamic> json) => ErfcRecord(
    rfcNumber: asString(json['rfcNumber']),
    division: asString(json['division']),
    department: asString(json['department']),
    unit: asString(json['unit']),
    modeOfProcurement: asString(json['modeOfProcurement']),
    value: asDouble(json['value']),
    submissionDate: asDateOrNull(json['submissionDate']),
    verified1Date: asDateOrNull(json['verified1Date']),
    verified2Date: asDateOrNull(json['verified2Date']),
    endorsedDate: asDateOrNull(json['endorsedDate']),
    status: asString(json['status']),
    createdBy: asString(json['createdBy']),
  );

  final String rfcNumber;
  final String division;
  final String department;
  final String unit;
  final String modeOfProcurement;
  final double value;

  /// Null only if the source omitted it; every real RFC has one.
  final DateTime? submissionDate;

  /// The two verification gates, in order. Each is null until the RFC
  /// reaches that stage, so a rejection at the first leaves the second
  /// empty.
  final DateTime? verified1Date;
  final DateTime? verified2Date;

  final DateTime? endorsedDate;

  /// The latest verification the RFC actually reached.
  DateTime? get verifiedDate => verified2Date ?? verified1Date;

  final String status;
  final String createdBy;

  Map<String, dynamic> toJson() => {
    'rfcNumber': rfcNumber,
    'division': division,
    'department': department,
    'unit': unit,
    'modeOfProcurement': modeOfProcurement,
    'value': value,
    'submissionDate': submissionDate?.toIso8601String(),
    'verified1Date': verified1Date?.toIso8601String(),
    'verified2Date': verified2Date?.toIso8601String(),
    'endorsedDate': endorsedDate?.toIso8601String(),
    'status': status,
    'createdBy': createdBy,
  };

  String get divisionAndDepartment =>
      department.isEmpty ? division : '$division / $department';

  bool get isTerminal => kErfcTerminalStatuses.contains(status);

  /// True once endorsement is cleared, including the states the RFC passes
  /// through afterwards on its way to becoming a tender.
  bool get isEndorsed => kErfcEndorsedStatuses.contains(status);

  bool get isRejected => kErfcRejectedStatuses.contains(status);

  /// Days since submission.
  ///
  /// Still moving for an in-flight RFC. For a finished one it freezes at
  /// the endorsement date, or at the latest verification reached when the
  /// RFC was rejected, declined or cancelled before endorsement — so a
  /// rejection after the second gate freezes at that date, not the first.
  int? agingDays({DateTime? asOf}) {
    final submitted = submissionDate;
    if (submitted == null) return null;

    final frozenAt = endorsedDate ?? (isTerminal ? verifiedDate : null);
    final end = frozenAt ?? asOf ?? DateTime.now();

    final days = end.difference(submitted).inDays;
    return days < 0 ? 0 : days;
  }

  /// Submission to endorsement. Null unless the RFC completed the cycle.
  int? get processingDays {
    final submitted = submissionDate;
    final endorsed = endorsedDate;
    if (!isEndorsed || submitted == null || endorsed == null) return null;
    return endorsed.difference(submitted).inDays;
  }

  @override
  List<Object?> get props => [
    rfcNumber,
    division,
    department,
    unit,
    modeOfProcurement,
    value,
    submissionDate,
    verified1Date,
    verified2Date,
    endorsedDate,
    status,
    createdBy,
  ];
}
