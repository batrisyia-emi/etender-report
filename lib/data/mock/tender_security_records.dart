// lib/data/mock/tender_security_records.dart
//
// Tender securities lodged by suppliers, per Blueprint v1.3 chapter 9.1 and
// process flow 3.5 process 1.12.
//
// One row per tenderer per tender: T.10001 and T.10002(2S) drew two bidders
// each. Between them the five rows cover every named view, all three
// payment types and all three outcome states.
//
// Tenderer names are fictional, following the convention of the other mock
// files in this folder. Bank names are left as real institutions: they name
// no party to a tender, and one of them carries a rule worth seeing — the
// blueprint allows the offshore bank in the Federal Territory of Labuan
// alongside the mainland ones.
//
// Every date is an offset from the day the report is opened rather than a
// literal: "expiring soon" and "expired" are questions about today, and
// fixed dates answer them correctly for a fortnight and then stop.

/// A date [offset] days from [base], in the `yyyy-MM-dd` form the contract
/// uses for date-only fields.
String _day(DateTime base, int offset) {
  final date = DateTime(base.year, base.month, base.day + offset);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

List<Map<String, dynamic>> buildTenderSecurityRecords({DateTime? asOf}) {
  final base = asOf ?? DateTime.now();
  return [
    // In order throughout: original in, lodged with Revenue Assurance, a
    // long way from expiry, and the tender not yet decided.
    {
      'tenderNo': 'T.10001',
      'vendorName': 'Vendor A Sdn Bhd',
      'uniqueNo': 'TS/2026/000001',
      'amount': 30000.00,
      'bankName': 'Maybank',
      'paymentType': 'BANK_GUARANTEE',
      'referenceNo': 'BK00101102',
      'scanCopy': '/files/tender-security/TS-2026-000001.pdf',
      'expiryDate': _day(base, 106),
      'originalCopyReceived': true,
      'submittedToRevenueAssuranceDate': _day(base, -6),
      'unsuccessfulTenderer': null,
      'refundDate': null,
    },

    // Expiring inside the warning window, with neither the original in nor
    // the security lodged — so this one row answers three of the views.
    {
      'tenderNo': 'T.10001',
      'vendorName': 'Vendor B Sdn Bhd',
      'uniqueNo': 'TS/2026/000002',
      'amount': 30000.00,
      'bankName': 'CIMB Bank',
      'paymentType': 'CASHIERS_ORDER',
      'referenceNo': 'CO-778120',
      'scanCopy': '/files/tender-security/TS-2026-000002.pdf',
      'expiryDate': _day(base, 10),
      'originalCopyReceived': false,
      'submittedToRevenueAssuranceDate': null,
      'unsuccessfulTenderer': null,
      'refundDate': null,
    },

    // Closed out: lost the tender and the security has been returned.
    {
      'tenderNo': 'T.10002(2S)',
      'vendorName': 'Vendor C Sdn Bhd',
      'uniqueNo': 'TS/2026/000003',
      'amount': 85000.00,
      'bankName': 'RHB Bank',
      'paymentType': 'BANK_GUARANTEE',
      'referenceNo': 'RHB-BG-09982',
      'scanCopy': '/files/tender-security/TS-2026-000003.pdf',
      'expiryDate': _day(base, 81),
      'originalCopyReceived': true,
      'submittedToRevenueAssuranceDate': _day(base, -34),
      'unsuccessfulTenderer': 'YES',
      'refundDate': _day(base, -5),
    },

    // Decided successful, so the security stays lodged rather than joining
    // the refund queue. The state that makes the third value worth having.
    {
      'tenderNo': 'T.10002(2S)',
      'vendorName': 'Vendor D Sdn Bhd',
      'uniqueNo': 'TS/2026/000004',
      'amount': 85000.00,
      'bankName': 'Bank of Labuan (Offshore)',
      'paymentType': 'BANK_GUARANTEE',
      'referenceNo': 'LBN-448201',
      'scanCopy': '/files/tender-security/TS-2026-000004.pdf',
      'expiryDate': _day(base, 81),
      'originalCopyReceived': true,
      'submittedToRevenueAssuranceDate': _day(base, -34),
      'unsuccessfulTenderer': 'NO',
      'refundDate': null,
    },

    // Owed back and lapsed anyway: the tenderer lost, the security was
    // never returned, and it has now expired while still on file. The worst
    // combination the report can show, and the one recommendation R2 exists
    // to surface.
    //
    // The blueprint's own sample leaves this row undecided, which left the
    // Pending refund view empty. Marked YES here so every named view has
    // something in it — see docs/tender-security-report.md.
    {
      'tenderNo': 'Q.10003',
      'vendorName': 'Vendor E Sdn Bhd',
      'uniqueNo': 'TS/2026/000005',
      'amount': 5000.00,
      'bankName': 'Public Bank',
      'paymentType': 'BANK_DRAFT',
      'referenceNo': 'BD-3301877',
      'scanCopy': '/files/tender-security/TS-2026-000005.pdf',
      'expiryDate': _day(base, -3),
      'originalCopyReceived': false,
      'submittedToRevenueAssuranceDate': null,
      'unsuccessfulTenderer': 'YES',
      'refundDate': null,
    },
  ];
}
