// lib/reports/models/status/vtm_monitoring_status.dart
//
// Where an Appendix F has reached on its way from preparation to floating,
// per the VTM Tender/Quotation Monitoring report.
//
// Seven stages with a real shape: two of them send the document back to the
// start, and only one is terminal. [nextStatuses] carries that shape so the
// table can say what happens next rather than leaving the reader to know.
//
// Sent by the server as a code, not as the words on screen — the one thing
// this vocabulary has in common with the tender security payment types, and
// unlike the older reports whose status *is* its label.

enum VtmStatus {
  draft(
    code: 'DRAFT',
    label: 'Draft',
    actor: 'Admin Supervisor (Tender) / SE Clerk (Quotation)',
    description:
        'Appendix F is being prepared and has not been submitted for '
        'verification.',
  ),
  submitted(
    code: 'SUBMITTED',
    label: 'Submitted',
    actor: 'Admin Supervisor (Tender) / SE Clerk (Quotation)',
    description:
        'Appendix F submitted and pending verification by the VTM '
        'Executive.',
  ),
  verifiedByExec(
    code: 'VERIFIED_BY_EXEC',
    label: 'Verified by VTM Executive',
    actor: 'Executive Tender / Executive Quotation / Executive Vendor',
    description:
        'Appendix F verified and pending approval by the VTM Manager or '
        'Senior Manager.',
  ),
  rejectedByExec(
    code: 'REJECTED_BY_EXEC',
    label: 'Rejected by VTM Executive',
    actor: 'Executive Tender / Executive Quotation / Executive Vendor',
    description:
        'Returned to the Admin Supervisor or SE Clerk for correction '
        '(process 1.4).',
  ),
  approvedByManager(
    code: 'APPROVED_BY_MANAGER',
    label: 'Approved by VTM Manager',
    actor: 'Manager / Sr. Manager',
    description:
        'Appendix F approved; pending requestor review and VTM float '
        'confirmation.',
  ),
  rejectedByManager(
    code: 'REJECTED_BY_MANAGER',
    label: 'Rejected by VTM Manager',
    actor: 'Manager / Sr. Manager',
    description:
        'Returned to the Admin Supervisor or SE Clerk for correction '
        '(process 1.4).',
  ),
  published(
    code: 'PUBLISHED',
    label: 'Published',
    actor: 'Admin Supervisor (Tender) / SE Clerk (Quotation)',
    description:
        'Tender or quotation floated and visible to suppliers '
        '(process 1.6).',
  );

  const VtmStatus({
    required this.code,
    required this.label,
    required this.actor,
    required this.description,
  });

  /// What the endpoint sends and the filter stores.
  final String code;

  /// What the chip displays.
  final String label;

  /// Whose step this is.
  final String actor;

  final String description;

  /// The report's own order, which is also the order of this enum.
  int get order => index + 1;

  /// Nothing further is expected once a document is floated.
  bool get isTerminal => this == VtmStatus.published;

  /// Where a document can go from here.
  ///
  /// Both rejections return to [submitted] rather than to [draft]: the
  /// document goes back to its preparer for correction and is resubmitted,
  /// it is not started again.
  Set<VtmStatus> get nextStatuses => switch (this) {
    VtmStatus.draft => {VtmStatus.submitted},
    VtmStatus.submitted => {VtmStatus.verifiedByExec, VtmStatus.rejectedByExec},
    VtmStatus.verifiedByExec => {
      VtmStatus.approvedByManager,
      VtmStatus.rejectedByManager,
    },
    VtmStatus.rejectedByExec => {VtmStatus.submitted},
    VtmStatus.approvedByManager => {VtmStatus.published},
    VtmStatus.rejectedByManager => {VtmStatus.submitted},
    VtmStatus.published => const {},
  };

  /// Sent back for correction. Distinct from simply not finished: these are
  /// the ones somebody has to act on again.
  bool get isRejected =>
      this == VtmStatus.rejectedByExec || this == VtmStatus.rejectedByManager;

  /// Moving forward, neither rejected nor floated.
  bool get isInProgress => !isRejected && !isTerminal;

  static VtmStatus? fromCode(Object? value) {
    final text = value?.toString();
    for (final status in VtmStatus.values) {
      if (status.code == text) return status;
    }
    return null;
  }

  /// An unrecognised code renders as itself rather than as a blank chip, so
  /// a vocabulary drift shows up instead of disappearing.
  static String labelFor(String code) => fromCode(code)?.label ?? code;

  /// Every status, in process order — the filter's option list.
  static List<String> get codes => [
    for (final status in VtmStatus.values) status.code,
  ];

  /// Code to label, for a filter that stores the code.
  static Map<String, String> get labels => {
    for (final status in VtmStatus.values) status.code: status.label,
  };

  static Set<String> codesOf(Set<VtmStatus> statuses) => {
    for (final status in statuses) status.code,
  };
}

/// The procurement modes that reach this report, by their Appendix A
/// section 7 numbers.
///
/// Five, not the sixteen in `kProcurementModes`. Section 7.4 — Direct
/// Negotiation — is deliberately absent: a directly negotiated purchase is
/// never floated to suppliers, so it has no Appendix F to monitor here. The
/// labels are the same wording the other reports use.
enum VtmProcurementMode {
  openTender(code: '7.1', label: 'Tender/Quotation'),
  selective(code: '7.2', label: 'Selective Tender/Quotation'),
  restricted(code: '7.3', label: 'Restricted Tender/Quotation'),
  preQualification(code: '7.5', label: 'Tender Through Pre-Qualification'),
  scheduleRate(code: '7.6', label: 'Schedule Rate/JHT');

  const VtmProcurementMode({required this.code, required this.label});

  final String code;
  final String label;

  static VtmProcurementMode? fromCode(Object? value) {
    final text = value?.toString();
    for (final mode in VtmProcurementMode.values) {
      if (mode.code == text) return mode;
    }
    return null;
  }

  /// A code outside the five shows as itself — a 7.4 arriving here is a
  /// finding, not something to hide behind a blank cell.
  static String labelFor(String code) => fromCode(code)?.label ?? code;

  static List<String> get codes => [
    for (final mode in VtmProcurementMode.values) mode.code,
  ];

  /// Code to label, with the number kept in front so the filter reads the
  /// way the form does.
  static Map<String, String> get labels => {
    for (final mode in VtmProcurementMode.values)
      mode.code: '${mode.code}  ${mode.label}',
  };
}

/// One or two stages of bid submission. Carried on the document, not on the
/// status: it decides how the tender is opened, not where it has reached.
enum VtmTenderType {
  oneStage(code: '1S', label: '1 Stage'),
  twoStage(code: '2S', label: '2 Stage');

  const VtmTenderType({required this.code, required this.label});

  final String code;
  final String label;

  static VtmTenderType? fromCode(Object? value) {
    final text = value?.toString();
    for (final type in VtmTenderType.values) {
      if (type.code == text) return type;
    }
    return null;
  }
}
