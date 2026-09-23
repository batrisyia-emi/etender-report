// lib/data/mock/supplier_portal.dart
//
// The signed-in supplier the portal dashboard is about: who they are, what they hold, what they have bid on and what is waiting for them.

const Map<String, dynamic> kSupplierProfile = {
  'supplierName': 'Vendor N Sdn Bhd',
  'supplierId': 'VEN/2000/000004',
  // Drawn from the tender vocabulary, so category matching against
  // [tenderRecords] actually hits.
  'categories': ['Service', 'Supply & Delivery'],
  'performanceScore': 87,
  'scoreTier': 'Top Tier',
  'scorePercentile': 'Top 15% of vendors',
  'bumiputera': true,
  'scoreBreakdown': [
    {'name': 'Document Completeness', 'percent': 80},
    {'name': 'On-time Submission', 'percent': 95},
    {'name': 'Bid Accuracy', 'percent': 90},
    {'name': 'Compliance History', 'percent': 85},
  ],
};

const List<Map<String, dynamic>> kSupplierDocuments = [
  {
    'name': 'SSM Certificate of Incorporation',
    'reference': 'SSM-200000000004',
    'fileName': 'SSM Cert.pdf',
    'fileType': 'PDF',
    'fileSize': '245 KB',
    'uploadedDate': '2024-03-14T00:00:00',
    'expiryDate': '2027-03-14T00:00:00',
  },
  {
    'name': 'MOF Registration Certificate',
    'reference': 'MOF-BUMI-0000-0000',
    'fileName': 'MOF Cert 2025.pdf',
    'fileType': 'PDF',
    'fileSize': '182 KB',
    'uploadedDate': '2025-09-01T00:00:00',
    'expiryDate': '2026-11-05T00:00:00',
  },
  {
    'name': 'CIDB Certificate (G5 - Electrical)',
    'reference': 'CIDB-KONTRAKTOR KERJA & PERKHIDMATAN',
    'fileName': 'CIDB G5 Cert.pdf',
    'fileType': 'PDF',
    'fileSize': '310 KB',
    'uploadedDate': '2024-08-15T00:00:00',
    'expiryDate': '2026-10-05T00:00:00',
  },
  {
    'name': 'Bumiputera Status Letter (PUNB / SKM)',
    'reference': 'PUNB-0000-00000',
    'fileName': 'Bumiputera Letter.pdf',
    'fileType': 'PDF',
    'fileSize': '89 KB',
    'uploadedDate': '2026-01-22T00:00:00',
    'expiryDate': '2028-01-22T00:00:00',
  },
  {
    'name': 'Audited Financial Statements FY2025',
    'reference': 'AFS-FY2025',
    'fileName': 'Audited FS FY2025.xlsx',
    'fileType': 'XLSX',
    'fileSize': '1.2 MB',
    'uploadedDate': '2026-04-30T00:00:00',
    'expiryDate': null,
  },
  {
    'name': 'Company Profile & Track Record',
    'reference': 'PROFILE-2024',
    'fileName': 'Company Profile.docx',
    'fileType': 'DOCX',
    'fileSize': '3.4 MB',
    'uploadedDate': '2024-03-14T00:00:00',
    'expiryDate': null,
  },
  {
    'name': "Directors' Identity Documents (IC)",
    'reference': 'IC-DIRECTORS',
    'fileName': 'Directors IC.pdf',
    'fileType': 'PDF',
    'fileSize': '512 KB',
    'uploadedDate': '2024-03-14T00:00:00',
    'expiryDate': null,
  },
  {
    'name': 'EPF / KWSP Contribution Statement',
    'reference': 'EPF-STATEMENT',
    'fileName': null,
    'fileType': null,
    'fileSize': null,
    'uploadedDate': null,
    'expiryDate': null,
  },
  {
    'name': 'LHDN Tax Clearance Letter',
    'reference': 'LHDN-CLEARANCE',
    'fileName': null,
    'fileType': null,
    'fileSize': null,
    'uploadedDate': null,
    'expiryDate': null,
  },
];

const List<Map<String, dynamic>> kSupplierBidPipeline = [
  {
    'tenderNo': 'SESB/T/2026/012',
    'title': 'Substation Maintenance Sabah West',
    'tenderCategory': 'Service',
    'bidAmount': 242500.00,
    'submittedDate': '2026-09-10T14:30:00',
    'outcome': 'Under Evaluation',
  },
  {
    'tenderNo': 'SESB/T/2026/008',
    'title': 'Supply of High-Voltage Cables (Sandakan)',
    'tenderCategory': 'Supply & Delivery',
    'bidAmount': 1180000.00,
    'submittedDate': '2026-08-28T11:10:00',
    'outcome': 'Under Evaluation',
  },
  {
    'tenderNo': 'SESB/Q/2026/045',
    'title': 'HQ Server Room Cooling System Upgrade',
    'tenderCategory': 'Supply & Delivery',
    'bidAmount': 86500.00,
    'submittedDate': '2026-08-21T09:05:00',
    'outcome': 'Under Evaluation',
  },
  {
    'tenderNo': 'SESB/T/2026/017',
    'title': 'Gas Turbine Overhaul (Patau-Patau)',
    'tenderCategory': 'Service',
    'bidAmount': 4450000.00,
    'submittedDate': '2026-08-14T15:40:00',
    'outcome': 'Shortlisted',
  },
  {
    'tenderNo': 'SESB/T/2026/021',
    'title': 'SCADA System Upgrade Phase 2',
    'tenderCategory': 'Service',
    'bidAmount': 2120000.00,
    'submittedDate': '2026-08-05T10:25:00',
    'outcome': 'Shortlisted',
  },
  {
    'tenderNo': 'SESB/T/2026/025',
    'title': 'Switchgear Replacement (Ranau)',
    'tenderCategory': 'Supply & Delivery',
    'bidAmount': 738000.00,
    'submittedDate': '2026-07-24T13:00:00',
    'outcome': 'Awarded',
  },
  {
    'tenderNo': 'SESB/L/2026/003',
    'title': 'Protection Relay Testing Services',
    'tenderCategory': 'Service',
    'bidAmount': 154000.00,
    'submittedDate': '2026-07-18T16:20:00',
    'outcome': 'Unsuccessful',
  },
  {
    'tenderNo': 'SESB/T/2026/023',
    'title': 'Rural Electrification Works (Pitas)',
    'tenderCategory': 'Service',
    'bidAmount': 905000.00,
    'submittedDate': '2026-07-02T09:45:00',
    'outcome': 'Unsuccessful',
  },
];

const List<Map<String, dynamic>> kSupplierNotifications = [
  {
    'message':
        'Your CIDB Certificate expires in 14 days. Please renew and '
        're-upload.',
    'severity': 'danger',
    'timestamp': '2026-09-21T08:30:00',
    'unread': true,
  },
  {
    'message':
        'New tender SESB/Q/2026/067 matches your Supply & Delivery '
        'category - closing 10 Oct.',
    'severity': 'warning',
    'timestamp': '2026-09-21T07:45:00',
    'unread': true,
  },
  {
    'message':
        'Your bid for SESB/T/2026/017 is shortlisted. Await further '
        'instructions.',
    'severity': 'info',
    'timestamp': '2026-09-20T15:12:00',
    'unread': false,
  },
  {
    'message':
        'Addendum ADD/2026/002 issued for SESB/Q/2026/045. Please review '
        'the revised specification.',
    'severity': 'success',
    'timestamp': '2026-09-18T10:00:00',
    'unread': false,
  },
  {
    'message':
        'Bid for SESB/L/2026/003 was unsuccessful. The award went to '
        'another vendor.',
    'severity': 'danger',
    'timestamp': '2026-09-15T14:00:00',
    'unread': false,
  },
];
