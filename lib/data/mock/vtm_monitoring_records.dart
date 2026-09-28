// lib/data/mock/vtm_monitoring_records.dart
//
// Appendix F documents moving from preparation to floating, for the VTM
// Tender/Quotation Monitoring report.
//
// Eight rows, one per status, ordered oldest endorsement last so the set
// reads as a pipeline: the further down, the further along. Five tenders
// and three quotations.
//
// Staff names are the role titles rather than people, which is how the
// spec's own sample reads and which suits a report about who owes the next
// step. The other mock files anonymise personal names the same way.
//
// Every date is an offset from the day the report is opened rather than a
// literal: aging counts to *today* for anything still in flight, so fixed
// dates would drift out of meaning within a fortnight.

/// A date [offset] days from [base], in the `yyyy-MM-dd` form the contract
/// uses for date-only fields.
String _day(DateTime base, int offset) {
  final date = DateTime(base.year, base.month, base.day + offset);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// A timestamp [offset] days from [base], for the fields that carry a time.
String _at(DateTime base, int offset, int hour, int minute) => DateTime(
  base.year,
  base.month,
  base.day + offset,
  hour,
  minute,
).toIso8601String();

Map<String, dynamic> _actor(String userId, String name, String role) => {
  'userId': userId,
  'name': name,
  'role': role,
};

Map<String, dynamic> get _adminSupervisor =>
    _actor('SE10231', 'Admin Supervisor', 'Admin Supervisor');
Map<String, dynamic> get _seClerk => _actor('SE10477', 'SE Clerk', 'SE Clerk');
Map<String, dynamic> get _executiveTender =>
    _actor('SE10088', 'Executive Tender', 'Executive Tender');
Map<String, dynamic> get _executiveQuotation =>
    _actor('SE10102', 'Executive Quotation', 'Executive Quotation');
Map<String, dynamic> get _manager =>
    _actor('SE10015', 'VTM Manager', 'Manager/Sr. Manager');

List<Map<String, dynamic>> buildVtmMonitoringRecords({DateTime? asOf}) {
  final base = asOf ?? DateTime.now();
  return [
    // Draft — being prepared, nothing submitted. No tender number yet:
    // that is allocated on the way to floating.
    {
      'erfcNo': 'ERFC/2026/00000041',
      'tenderQuotationNo': null,
      'projectTitle':
          'Supply and Delivery of 11kV Ring Main Units for West Coast Zone',
      'documentType': 'Tender',
      'tenderType': '1S',
      'modeOfProcurement': '7.1',
      'division': 'Distribution Division',
      'department': 'Asset Management',
      'estimatedValue': 480000.00,
      'documentPrice': 50.00,
      'status': 'DRAFT',
      'preparedBy': _adminSupervisor,
      'verifiedBy': null,
      'approvedBy': null,
      'endorsedDate': _day(base, -6),
      'submittedDate': null,
      'verifiedDate': null,
      'approvedDate': null,
      'floatingDate': null,
      'closingDate': null,
      'rejectionRemarks': null,
    },

    // Submitted — with the VTM Executive, waiting on verification.
    {
      'erfcNo': 'ERFC/2026/00000038',
      'tenderQuotationNo': null,
      'projectTitle':
          'Servicing of Air-Conditioning Units at Wisma SE Kota Kinabalu',
      'documentType': 'Quotation',
      'tenderType': '1S',
      'modeOfProcurement': '7.1',
      'division': 'Corporate Services Division',
      'department': 'Facilities Management',
      'estimatedValue': 185000.00,
      'documentPrice': 0.00,
      'status': 'SUBMITTED',
      'preparedBy': _seClerk,
      'verifiedBy': null,
      'approvedBy': null,
      'endorsedDate': _day(base, -13),
      'submittedDate': _at(base, -7, 10, 42),
      'verifiedDate': null,
      'approvedDate': null,
      'floatingDate': null,
      'closingDate': null,
      'rejectionRemarks': null,
    },

    // Verified — with the Manager, waiting on approval.
    {
      'erfcNo': 'ERFC/2026/00000035',
      'tenderQuotationNo': null,
      'projectTitle': 'Upgrading of 33kV Switchgear at Sandakan Main Intake',
      'documentType': 'Tender',
      'tenderType': '1S',
      'modeOfProcurement': '7.2',
      'division': 'Transmission Division',
      'department': 'Substation Projects',
      'estimatedValue': 750000.00,
      'documentPrice': 75.00,
      'status': 'VERIFIED_BY_EXEC',
      'preparedBy': _adminSupervisor,
      'verifiedBy': _executiveTender,
      'approvedBy': null,
      'endorsedDate': _day(base, -20),
      'submittedDate': _at(base, -14, 15, 10),
      'verifiedDate': _at(base, -11, 11, 25),
      'approvedDate': null,
      'floatingDate': null,
      'closingDate': null,
      'rejectionRemarks': null,
    },

    // Rejected by the Executive — back with the preparer, and past the slow
    // threshold, so it raises a flag.
    {
      'erfcNo': 'ERFC/2026/00000033',
      'tenderQuotationNo': null,
      'projectTitle': 'Supply of Personal Protective Equipment for Tawau Area',
      'documentType': 'Quotation',
      'tenderType': '1S',
      'modeOfProcurement': '7.3',
      'division': 'Distribution Division',
      'department': 'Tawau Area Office',
      'estimatedValue': 92000.00,
      'documentPrice': 0.00,
      'status': 'REJECTED_BY_EXEC',
      'preparedBy': _seClerk,
      'verifiedBy': _executiveQuotation,
      'approvedBy': null,
      'endorsedDate': _day(base, -23),
      'submittedDate': _at(base, -18, 9, 30),
      'verifiedDate': _at(base, -16, 16, 5),
      'approvedDate': null,
      'floatingDate': null,
      'closingDate': null,
      'rejectionRemarks':
          'Revised Kod Bidang in Section 12 does not match the scope. Please '
          'update and resubmit.',
    },

    // Approved — one step from floating, and nobody has taken it.
    {
      'erfcNo': 'ERFC/2026/00000029',
      'tenderQuotationNo': 'T.10024(2S)',
      'projectTitle': 'Implementation of Outage Management System',
      'documentType': 'Tender',
      'tenderType': '2S',
      'modeOfProcurement': '7.1',
      'division': 'Information & Communication Technology Division',
      'department': 'Application Services',
      'estimatedValue': 320000.00,
      'documentPrice': 50.00,
      'status': 'APPROVED_BY_MANAGER',
      'preparedBy': _adminSupervisor,
      'verifiedBy': _executiveTender,
      'approvedBy': _manager,
      'endorsedDate': _day(base, -31),
      'submittedDate': _at(base, -25, 14, 20),
      'verifiedDate': _at(base, -21, 10, 0),
      'approvedDate': _at(base, -18, 17, 45),
      'floatingDate': null,
      'closingDate': null,
      'rejectionRemarks': null,
    },

    // Rejected by the Manager — the longest-standing row in the set, and
    // the one most in need of chasing.
    {
      'erfcNo': 'ERFC/2026/00000027',
      'tenderQuotationNo': null,
      'projectTitle': 'Construction of 11kV Overhead Line to Kg. Pensiangan',
      'documentType': 'Tender',
      'tenderType': '1S',
      'modeOfProcurement': '7.5',
      'division': 'Distribution Division',
      'department': 'Rural Electrification',
      'estimatedValue': 650000.00,
      'documentPrice': 75.00,
      'status': 'REJECTED_BY_MANAGER',
      'preparedBy': _adminSupervisor,
      'verifiedBy': _executiveTender,
      'approvedBy': _manager,
      'endorsedDate': _day(base, -34),
      'submittedDate': _at(base, -27, 11, 15),
      'verifiedDate': _at(base, -24, 9, 50),
      'approvedDate': _at(base, -20, 15, 30),
      'floatingDate': null,
      'closingDate': null,
      'rejectionRemarks':
          'Site briefing date in Section 21 falls after the proposed closing '
          'date. Please correct.',
    },

    // Published — floated 20 days after endorsement, which is what the
    // average lead time is drawn from.
    {
      'erfcNo': 'ERFC/2026/00000019',
      'tenderQuotationNo': 'T.10021',
      'projectTitle': 'Supply and Delivery of XLPE Underground Cables (CPA)',
      'documentType': 'Tender',
      'tenderType': '1S',
      'modeOfProcurement': '7.1',
      'division': 'Procurement Division',
      'department': 'Stock Purchasing Unit',
      'estimatedValue': 410000.00,
      'documentPrice': 50.00,
      'status': 'PUBLISHED',
      'preparedBy': _adminSupervisor,
      'verifiedBy': _executiveTender,
      'approvedBy': _manager,
      'endorsedDate': _day(base, -47),
      'submittedDate': _at(base, -41, 10, 5),
      'verifiedDate': _at(base, -39, 14, 40),
      'approvedDate': _at(base, -35, 9, 15),
      'floatingDate': _day(base, -27),
      'closingDate': _at(base, 8, 12, 0),
      'rejectionRemarks': null,
    },

    // Published — floated in 16 days, and already closed to bids.
    {
      'erfcNo': 'ERFC/2026/00000024',
      'tenderQuotationNo': 'Q.10057',
      'projectTitle':
          'Schedule Rate for Grass Cutting at Substations, Keningau',
      'documentType': 'Quotation',
      'tenderType': '1S',
      'modeOfProcurement': '7.6',
      'division': 'Distribution Division',
      'department': 'Keningau Area Office',
      'estimatedValue': 60000.00,
      'documentPrice': 0.00,
      'status': 'PUBLISHED',
      'preparedBy': _seClerk,
      'verifiedBy': _executiveQuotation,
      'approvedBy': _manager,
      'endorsedDate': _day(base, -26),
      'submittedDate': _at(base, -21, 13, 0),
      'verifiedDate': _at(base, -19, 10, 20),
      'approvedDate': _at(base, -17, 16, 10),
      'floatingDate': _day(base, -10),
      'closingDate': _at(base, -3, 12, 0),
      'rejectionRemarks': null,
    },
  ];
}
