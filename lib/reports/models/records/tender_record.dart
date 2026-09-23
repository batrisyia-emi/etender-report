// lib/reports/models/records/tender_record.dart
import 'package:equatable/equatable.dart';

import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';

/// A tender closing within this many days counts as closing soon.
const int kClosingSoonDays = 7;

/// One tender or quotation, per report spec 6.1.
class TenderRecord extends Equatable {
  const TenderRecord({
    required this.referenceNo,
    required this.tenderNo,
    required this.title,
    required this.tenderCategory,
    required this.division,
    required this.department,
    required this.unit,
    required this.value,
    required this.modeOfProcurement,
    required this.envelopeType,
    required this.itemType,
    required this.requestedDate,
    required this.endorsedDate,
    required this.floatingDate,
    required this.closingDate,
    required this.status,
    required this.erfcId,
    required this.createdBy,
    required this.lastUpdate,
    required this.lastUpdatedBy,
  });

  factory TenderRecord.fromJson(Map<String, dynamic> json) => TenderRecord(
    referenceNo: asString(json['referenceNo']),
    tenderNo: asString(json['tenderNo']),
    title: asString(json['title']),
    tenderCategory: asString(json['tenderCategory']),
    division: asString(json['division']),
    department: asString(json['department']),
    unit: asString(json['unit']),
    value: asDouble(json['value']),
    modeOfProcurement: asString(json['modeOfProcurement']),
    envelopeType: asString(json['envelopeType']),
    itemType: asString(json['itemType']),
    requestedDate: asDateOrNull(json['requestedDate']),
    endorsedDate: asDateOrNull(json['endorsedDate']),
    floatingDate: asDateOrNull(json['floatingDate']),
    closingDate: asDateOrNull(json['closingDate']),
    status: asString(json['status']),
    erfcId: asString(json['erfcId']),
    createdBy: asString(json['createdBy']),
    lastUpdate: asDateOrNull(json['lastUpdate']),
    lastUpdatedBy: asString(json['lastUpdatedBy']),
  );

  final String referenceNo;
  final String tenderNo;
  final String title;
  final String tenderCategory;
  final String division;
  final String department;
  final String unit;
  final double value;
  final String modeOfProcurement;

  /// 1 Envelope or 2 Envelope. Every tender carries one.
  final String envelopeType;

  /// Stock Item or Non-Stock Item.
  final String itemType;

  final DateTime? requestedDate;

  /// Carried over from the eRFC this tender came from.
  final DateTime? endorsedDate;

  /// Null until that stage is reached.
  final DateTime? floatingDate;
  final DateTime? closingDate;

  final String status;

  final String erfcId;
  final String createdBy;
  final DateTime? lastUpdate;
  final String lastUpdatedBy;

  Map<String, dynamic> toJson() => {
    'referenceNo': referenceNo,
    'tenderNo': tenderNo,
    'title': title,
    'tenderCategory': tenderCategory,
    'division': division,
    'department': department,
    'unit': unit,
    'value': value,
    'modeOfProcurement': modeOfProcurement,
    'envelopeType': envelopeType,
    'itemType': itemType,
    'requestedDate': requestedDate?.toIso8601String(),
    'endorsedDate': endorsedDate?.toIso8601String(),
    'floatingDate': floatingDate?.toIso8601String(),
    'closingDate': closingDate?.toIso8601String(),
    'status': status,
    'erfcId': erfcId,
    'createdBy': createdBy,
    'lastUpdate': lastUpdate?.toIso8601String(),
    'lastUpdatedBy': lastUpdatedBy,
  };

  TenderStatus? get lifecycleStatus => TenderStatus.fromWire(status);

  bool get isPublished => lifecycleStatus == TenderStatus.published;
  bool get isExtended => lifecycleStatus == TenderStatus.extended;
  bool get isClosed => lifecycleStatus == TenderStatus.closed;

  /// Still accepting bids, whether or not the closing date was pushed out.
  bool get isOpenForBidding =>
      TenderStatus.openForBidding.contains(lifecycleStatus);

  /// Null when there is no closing date, or it has already passed.
  int? daysToClosing({DateTime? asOf}) {
    final closing = closingDate;
    if (closing == null) return null;
    final now = asOf ?? DateTime.now();
    if (closing.isBefore(now)) return null;
    return closing.difference(now).inDays;
  }

  /// Request to market. Null unless the tender has been floated.
  int? get daysToMarket {
    final requested = requestedDate;
    final floating = floatingDate;
    if (requested == null || floating == null) return null;
    return floating.difference(requested).inDays;
  }

  @override
  List<Object?> get props => [
    referenceNo,
    tenderNo,
    title,
    tenderCategory,
    division,
    department,
    unit,
    value,
    modeOfProcurement,
    envelopeType,
    itemType,
    requestedDate,
    endorsedDate,
    floatingDate,
    closingDate,
    status,
    erfcId,
    createdBy,
    lastUpdate,
    lastUpdatedBy,
  ];
}
