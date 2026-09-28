// lib/reports/models/tender_security_attributes.dart
//
// The vocabularies the Tender Security Submission sub-function works in,
// per Blueprint v1.3 chapter 9.1 and process flow 3.5 process 1.12.

/// How the supplier lodged its security.
///
/// The instrument must be issued by a bank domiciled in Malaysia, including
/// the offshore bank in the Federal Territory of Labuan. That rule is the
/// server's to enforce — this app only reports what was lodged.
///
/// The one vocabulary in the app whose wire value is a code rather than the
/// words on screen, because that is what the endpoint sends. Keep
/// [wireValue] and [label] apart and the difference stays visible.
enum PaymentType {
  cashiersOrder(wireValue: 'CASHIERS_ORDER', label: "Cashier's Order"),
  bankDraft(wireValue: 'BANK_DRAFT', label: 'Bank Draft'),
  bankGuarantee(wireValue: 'BANK_GUARANTEE', label: 'Bank Guarantee');

  const PaymentType({required this.wireValue, required this.label});

  /// What the endpoint sends and the filter stores.
  final String wireValue;

  /// What the table shows.
  final String label;

  static PaymentType? fromWire(Object? value) {
    final text = value?.toString();
    for (final type in PaymentType.values) {
      if (type.wireValue == text) return type;
    }
    return null;
  }

  /// An unknown code renders as itself rather than as a blank cell, so a
  /// vocabulary drift shows up instead of disappearing.
  static String labelFor(String wireValue) =>
      fromWire(wireValue)?.label ?? wireValue;

  static List<String> get wireValues => [
    for (final type in PaymentType.values) type.wireValue,
  ];

  /// Wire value to label, for a dropdown that stores the code.
  static Map<String, String> get labels => {
    for (final type in PaymentType.values) type.wireValue: type.label,
  };
}

/// Whether the tenderer lost, which is what releases the security.
///
/// Three states, not two. Blank is not `NO`: it means VTM has not decided,
/// and only [yes] puts a row in the refund queue. A blank defaulted to `NO`
/// would quietly empty that queue.
enum UnsuccessfulTenderer {
  /// Blank on the wire.
  notDecided(wireValue: null, label: 'Not decided'),
  yes(wireValue: 'YES', label: 'YES'),
  no(wireValue: 'NO', label: 'NO');

  const UnsuccessfulTenderer({required this.wireValue, required this.label});

  /// Null for [notDecided]; the blueprint's own `YES` / `NO` otherwise.
  final String? wireValue;

  final String label;

  /// Anything unrecognised — including null, an empty string and a value
  /// from some later vocabulary — reads as undecided rather than as `NO`.
  static UnsuccessfulTenderer fromWire(Object? value) {
    final text = value?.toString();
    for (final option in UnsuccessfulTenderer.values) {
      if (option.wireValue != null && option.wireValue == text) return option;
    }
    return UnsuccessfulTenderer.notDecided;
  }

  static List<String> get labels => [
    for (final option in UnsuccessfulTenderer.values) option.label,
  ];
}

/// How much security a tender asks for, per Appendix A section 8.6 and
/// supplier Appendix B.
///
/// Not carried on a tender security record: it is a property of the tender,
/// and the endpoint in 9.1 does not send it. Declared here because the
/// validity periods below are what recommendation R3 would check an expiry
/// date against, and they belong with the rest of this vocabulary.
enum TenderSecurityRequirement {
  prevailingPpp(wireValue: 'PREVAILING_PPP', label: 'As Per Prevailing PPP'),
  deviateProposedValue(
    wireValue: 'DEVIATE_PROPOSED_VALUE',
    label: 'Deviate from Prevailing PPP / Proposed Value',
  ),
  deviateNotApplicable(
    wireValue: 'DEVIATE_NOT_APPLICABLE',
    label: 'Deviate from Prevailing PPP / Not Applicable',
  );

  const TenderSecurityRequirement({
    required this.wireValue,
    required this.label,
  });

  final String wireValue;
  final String label;

  static TenderSecurityRequirement? fromWire(Object? value) {
    final text = value?.toString();
    for (final option in TenderSecurityRequirement.values) {
      if (option.wireValue == text) return option;
    }
    return null;
  }
}

/// Days of validity a security must carry under [
/// TenderSecurityRequirement.prevailingPpp], by tender category.
///
/// Section 8.6: 120 days for Work or Service, 90 for Supply & Delivery. The
/// other two requirement options follow the proposed value, or none at all.
const Map<String, int> kPrevailingPppValidityDays = {
  'Work': 120,
  'Service': 120,
  'Supply & Delivery': 90,
};
