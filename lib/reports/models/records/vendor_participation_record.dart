// lib/reports/models/records/vendor_participation_record.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/models/records/record_parsing.dart';

/// One vendor's involvement in one tender or quotation.
class VendorParticipationRecord extends Equatable {
  const VendorParticipationRecord({
    required this.referenceNo,
    required this.tenderNo,
    required this.title,
    required this.tenderCategory,
    required this.division,
    required this.vendorName,
    required this.invitationStatus,
    required this.documentPurchased,
    required this.submissionStatus,
    required this.submissionDateTime,
    required this.participationStatus,
    required this.openTo,
    required this.vendorCategory,
    required this.certificationType,
  });

  factory VendorParticipationRecord.fromJson(Map<String, dynamic> json) =>
      VendorParticipationRecord(
        referenceNo: asString(json['referenceNo']),
        tenderNo: asString(json['tenderNo']),
        title: asString(json['title']),
        tenderCategory: asString(json['tenderCategory']),
        division: asString(json['division']),
        vendorName: asString(json['vendorName']),
        invitationStatus: asString(json['invitationStatus']),
        documentPurchased: asBool(json['documentPurchased']),
        submissionStatus: asString(json['submissionStatus']),
        submissionDateTime: asDateOrNull(json['submissionDateTime']),
        participationStatus: asString(json['participationStatus']),
        openTo: asString(json['openTo']),
        vendorCategory: asString(json['vendorCategory']),
        certificationType: asString(json['certificationType']),
      );

  final String referenceNo;
  final String tenderNo;
  final String title;
  final String tenderCategory;
  final String division;
  final String vendorName;
  final String invitationStatus;
  final bool documentPurchased;
  final String submissionStatus;

  /// Null unless the vendor submitted.
  final DateTime? submissionDateTime;

  /// Whether the vendor took the invitation up: 'Participated' or
  /// 'Rejected'. The funnel counts off this, not off the submission.
  final String participationStatus;

  /// Appendix A 8.1 eligibility the tender was opened to.
  final String openTo;

  final String vendorCategory;
  final String certificationType;

  Map<String, dynamic> toJson() => {
    'referenceNo': referenceNo,
    'tenderNo': tenderNo,
    'title': title,
    'tenderCategory': tenderCategory,
    'division': division,
    'vendorName': vendorName,
    'invitationStatus': invitationStatus,
    'documentPurchased': documentPurchased,
    'submissionStatus': submissionStatus,
    'submissionDateTime': submissionDateTime?.toIso8601String(),
    'participationStatus': participationStatus,
    'openTo': openTo,
    'vendorCategory': vendorCategory,
    'certificationType': certificationType,
  };

  /// Late bids still count as a submission: the vendor did bid.
  bool get hasSubmitted =>
      submissionStatus == 'Submitted' || submissionStatus == 'Late';

  /// Took the invitation up, as opposed to turning it down.
  bool get hasParticipated => participationStatus == 'Participated';

  bool get wasInvited => invitationStatus == 'Sent';

  bool get wasLate => submissionStatus == 'Late';

  /// For display and for the Yes / No filter.
  String get purchaseLabel => documentPurchased ? 'Yes' : 'No';

  @override
  List<Object?> get props => [
    referenceNo,
    tenderNo,
    title,
    tenderCategory,
    division,
    vendorName,
    invitationStatus,
    documentPurchased,
    submissionStatus,
    submissionDateTime,
    participationStatus,
    openTo,
    vendorCategory,
    certificationType,
  ];
}
